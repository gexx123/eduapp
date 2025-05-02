import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../onboarding/teacher_onboarding_dialog.dart';
import '../class_management/manage_class_dialog.dart';
import '../class_management/create_class_dialog.dart';
import '../class_management/manage_class_page.dart';
import '../class_management/upload_marks_page.dart';
import '../widgets/info_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/task_card.dart';
import '../widgets/student_tile.dart';
import '../models/student.dart';
import '../models/class.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

class TeacherDashboardPage extends StatefulWidget {
  final String schoolName;
  final String schoolCode;
  const TeacherDashboardPage({Key? key, this.schoolName = '', this.schoolCode = ''}) : super(key: key);

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int tabIndex = 0;
  bool showJoinBanner = true;
  bool _onboardingChecked = false;
  final FirestoreService _firestoreService = FirestoreService();
  bool isClassCreated = false;
  String? teacherName;

  @override
  void initState() {
    super.initState();
    _initAsync();
    _getTeacherName();
    if (showJoinBanner) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => showJoinBanner = false);
      });
    }
  }

  Future<void> _getTeacherName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final gmDoc = await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
    if (gmDoc.docs.isNotEmpty) {
      setState(() {
        teacherName = gmDoc.docs.first['name'];
      });
    }
  }

  /// Initialize dashboard async logic in sequence
  Future<void> _initAsync() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // Get onboarding status from FirestoreService
    final shouldShowOnboarding = await _firestoreService.shouldShowTeacherOnboarding(uid);
    print('[TeacherDashboard] shouldShowOnboarding=$shouldShowOnboarding');
    
    setState(() {
      isClassCreated = !shouldShowOnboarding;
    });
    
    if (shouldShowOnboarding) {
      print('[TeacherDashboard] Will show onboarding dialog');
      // Show onboarding without any nested callbacks
      await _showOnboardingDialog();
    } else {
      print('[TeacherDashboard] Skipping onboarding - already completed');
    }
  }
  
  // Single, clean onboarding flow
  Future<void> _showOnboardingDialog() async {
    print("[TeacherDashboard] Showing onboarding dialog");
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // Get user's schoolCode
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userSnap.data() ?? {};
    String? schoolCode = userData['schoolCode'];
    if (schoolCode == null || schoolCode.toString().isEmpty) {
      // User has not joined a school, show join school page
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/joinSchool');
      }
      return;
    }
    
    // Get or create group_member document
    String? docId;
    final doc = await FirebaseFirestore.instance.collection('group_member')
      .where('userId', isEqualTo: uid).limit(1).get();
    
    if (doc.docs.isNotEmpty) {
      docId = doc.docs.first.id;
    } else {
      // Auto-create group_member doc for new teacher
      final newDoc = await FirebaseFirestore.instance.collection('group_member').add({
        'userId': uid,
        'role': 'teacher',
        'schoolCode': schoolCode,
        'schoolName': userData['schoolName'] ?? '',
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
        'image': '',
        'onboarded': false,
      });
      docId = newDoc.id;
    }
    
    // Show the modular onboarding dialog as a compact, centered dialog
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFF5EDF9),
          child: TeacherOnboardingBottomSheet(
            schoolCode: schoolCode!,
            groupMemberDocId: docId,
          ),
        ),
      );
    }
  }

  void _showCreateClassDialog() async {
    await showCreateClassDialog(
      context: context,
      onSave: (className, section, subjects, students) async {
        // Save new class via FirestoreService
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final gmDoc = await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
        if (gmDoc.docs.isEmpty) return;
        final schoolCode = gmDoc.docs.first['schoolCode'];
        final teacherName = gmDoc.docs.first['name'] ?? '';
        final newClass = SchoolClass(
          className: className,
          section: section,
          subjects: subjects,
          students: students,
        );
        await _firestoreService.saveClassWithCreator(schoolCode, newClass, uid, teacherName);
        await _firestoreService.setUserClassCreated(uid, true);
        setState(() {
          isClassCreated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class created successfully!')),
        );
      },
    );
  }

  void _showManageClassDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Fetch teacher's group_member doc
    final gmDoc = await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
    if (gmDoc.docs.isEmpty) return;
    final classAssigned = gmDoc.docs.first['classAssigned'];
    final schoolCode = gmDoc.docs.first['schoolCode'];
    if (classAssigned == null || classAssigned.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No class assigned to you.')));
      return;
    }
    // Use FirestoreService to fetch class
    final schoolClass = await _firestoreService.getClass(schoolCode, classAssigned);
    if (schoolClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class not found.')));
      return;
    }
    final _classNameController = TextEditingController(text: schoolClass.className);
    final _sectionController = TextEditingController(text: schoolClass.section);
    List<String> selectedSubjects = List<String>.from(schoolClass.subjects);
    List<Student> students = schoolClass.students.map((s) => Student.fromMap(s)).toList();
    Map<String, dynamic> subjectTeachers = schoolClass.subjectTeachers ?? {};
    // Fetch all teachers in this school (direct Firestore call retained for group_member lookup)
    final teachersSnap = await FirebaseFirestore.instance.collection('group_member')
      .where('schoolCode', isEqualTo: schoolCode)
      .where('role', isEqualTo: 'teacher')
      .get();
    final teacherOptions = teachersSnap.docs.map((doc) => {
      'uid': doc['userId'],
      'name': doc['name'],
      'subject': doc['subject'] ?? '',
    }).toList();
    await showManageClassDialog(
      context: context,
      schoolCode: schoolCode,
      className: _classNameController.text,
      section: _sectionController.text,
      subjects: selectedSubjects,
      students: students.map((s) => s.toMap()).toList(),
      subjectTeachers: subjectTeachers,
      teacherOptions: teacherOptions,
      onSave: (updatedStudents, updatedSubjects, updatedSubjectTeachers) async {
        // Fetch teacher name from group_member
        final gmDoc = await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid).limit(1).get();
        final teacherName = gmDoc.docs.isNotEmpty ? gmDoc.docs.first['name'] ?? '' : '';
        // Save changes via FirestoreService
        final updatedClass = SchoolClass(
          className: _classNameController.text,
          section: _sectionController.text,
          subjects: updatedSubjects,
          students: updatedStudents,
          subjectTeachers: updatedSubjectTeachers,
        );
        await _firestoreService.saveClassWithCreator(schoolCode, updatedClass, FirebaseAuth.instance.currentUser!.uid, teacherName);
        await _firestoreService.setUserClassCreated(FirebaseAuth.instance.currentUser!.uid, true);
        setState(() {
          isClassCreated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class updated successfully!')),
        );
      },
    );
  }

  void _saveTeacherOnboarding(String name, String subject, bool isClassTeacher) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
    if (doc.docs.isNotEmpty) {
      await doc.docs.first.reference.set({
        'name': name,
        'subject': subject,
        'isClassTeacher': isClassTeacher,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    // Wait for teacherName to load before building UI
    if (teacherName == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F7FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 36, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Color(0xFF5B8DEE), size: 28),
                  SizedBox(width: 8),
                  Text(
                    widget.schoolName.isEmpty ? 'School Name' : widget.schoolName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(width: 14),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F4FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text('School Code: ', style: TextStyle(fontSize: isMobile ? 10 : 12, color: Colors.black54)),
                        SelectableText(
                          widget.schoolCode,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12, color: Color(0xFF5B8DEE)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Icon(Icons.menu, size: 26, color: Colors.black87),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 28, vertical: isMobile ? 14 : 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 18),
              SummaryCard(
                title: 'School Information',
                value: widget.schoolCode,
                icon: Icons.school,
                isMobile: isMobile,
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  InfoCard(label: 'Your Classes', icon: Icons.groups, value: '3', isMobile: isMobile),
                  SizedBox(width: isMobile ? 6 : 18),
                  InfoCard(label: 'Pending Tasks', icon: Icons.assignment, value: '2', isMobile: isMobile),
                  SizedBox(width: isMobile ? 6 : 18),
                  InfoCard(label: 'Upcoming Due Dates', icon: Icons.calendar_today, value: '2', isMobile: isMobile),
                ],
              ),
              SizedBox(height: 18),
              _teacherTabBar(isMobile),
              SizedBox(height: 10),
              Builder(
                builder: (context) {
                  if (tabIndex == 0) {
                    return _assignedTasksTab(isMobile);
                  } else if (tabIndex == 1) {
                    return _classesTab(isMobile);
                  } else {
                    return _marksUploadTab(isMobile);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teacherTabBar(bool isMobile) {
    final tabs = ['Assigned Tasks', 'Classes & Marks', 'Question Papers'];
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == tabIndex;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: selected ? Colors.white : Colors.transparent,
                foregroundColor: selected ? Color(0xFF1976D2) : Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15),
              ),
              onPressed: () => setState(() => tabIndex = i),
              child: Text(tabs[i]),
            ),
          );
        }),
      ),
    );
  }

  Widget _assignedTasksTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18),
        Text('Tasks from Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 17 : 22)),
        SizedBox(height: 12),
        TaskCard(
          title: 'Submit Annual Lesson Plans',
          due: 'Due: 6/15/2023 · Type: Lesson Plan',
          description: 'All teachers need to submit their annual lesson plans for review',
          status: 'In Progress',
          statusColor: Color(0xFF1565C0),
          priority: 'High Priority',
          priorityColor: Color(0xFFFDE7E7),
          priorityTextColor: Color(0xFFD32F2F),
          onViewDetails: () {},
          onUpdateStatus: () {},
        ),
        SizedBox(height: 18),
        TaskCard(
          title: 'Mid-Term Assessment Reports',
          due: 'Due: 6/30/2023 · Type: Assessment',
          description: 'Complete mid-term assessment reports for all classes',
          status: 'Pending',
          statusColor: Color(0xFFF9A825),
          priority: 'Medium Priority',
          priorityColor: Color(0xFFFFF8E1),
          priorityTextColor: Color(0xFFFBC02D),
          onViewDetails: () {},
          onUpdateStatus: () {},
        ),
      ],
    );
  }

  Widget _classesTab(bool isMobile) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final schoolCode = widget.schoolCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Classes & Student Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 17 : 22)),
                SizedBox(height: 2),
                Text('Manage your classes and upload student marks', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 14)),
              ],
            ),
            // Show Manage button only if at least one class is assigned AND user is a class teacher
            if (teacherName != null)
              FutureBuilder<Map<String, dynamic>>(
                future: FirestoreService().getTeacherOnboardingStatus(uid ?? ''),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) return Container();
                  final onboarding = snapshot.data!;
                  final isClassCreated = onboarding['isClassCreated'] == true;
                  if (!isClassCreated) return Container();
                  return StreamBuilder<List<SchoolClass>>(
                    stream: FirestoreService().getClassesForTeacher(schoolCode, uid ?? '', teacherName: teacherName),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      if (snapshot.data!.isEmpty) {
                        return Container();
                      }
                      return ElevatedButton.icon(
                        onPressed: () {
                          // Fix: Use classTeacherName for main teacher check, and pass SchoolClass to ManageClassPage
                          final mainClass = snapshot.data!.firstWhere(
                            (c) => c.classTeacherName == teacherName,
                            orElse: () => snapshot.data!.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageClassPage(
                                schoolCode: widget.schoolCode,
                                schoolClass: mainClass,
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Manage Your Class'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
        SizedBox(height: 18),
        // Show classes assigned to or created by the teacher
        StreamBuilder<List<SchoolClass>>(
          stream: FirestoreService().getClassesForTeacher(schoolCode, uid ?? '', teacherName: teacherName),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final classes = snapshot.data!;
            if (classes.isEmpty) {
              return Center(child: Text('No classes assigned.'));
            }
            return Column(
              children: classes.map((c) => _classCard(c.className, c.section, c.students.length)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _classCard(String className, String section, int studentCount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$className - $section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              SizedBox(height: 4),
              Text('$studentCount students', style: TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _showExamSelectionDialog('${className}_$section', className, section);
                },
                icon: Icon(Icons.file_upload_outlined, size: 16),
                label: Text('Upload Marks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5B8DEE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExamSelectionDialog(String classId, String className, String section) async {
    final List<String> exams = [
      'PT 1', 'PT 2', 'Half Yearly', 'PT 3', 'PT 4', 'Yearly'
    ];
    // Fetch marks for each exam for this class
    final firestoreService = FirestoreService();
    final marksStatus = <String, bool>{};
    for (final exam in exams) {
      final marks = await firestoreService.getMarksForClassExam(widget.schoolCode, classId, exam).first;
      marksStatus[exam] = marks.isNotEmpty;
    }
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 16 : 24)),
          backgroundColor: const Color(0xFFF8F7FC),
          child: Container(
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(maxWidth: 520),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 32, vertical: isMobile ? 16 : 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Exam Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 15 : 20,
                          color: Color(0xFF5B8DEE),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, size: isMobile ? 22 : 28, color: Colors.black87),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 24),
                ...exams.map((exam) => ListTile(
                  leading: marksStatus[exam] == true
                      ? Icon(Icons.check_circle, color: Colors.green, size: isMobile ? 20 : 26)
                      : Icon(Icons.radio_button_unchecked, color: Colors.grey, size: isMobile ? 20 : 26),
                  title: Text(
                    exam,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 15 : 17,
                      color: Color(0xFF222B45),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(exam);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: marksStatus[exam] == true ? Color(0xFFE6F7EC) : null,
                  hoverColor: Color(0xFFE9F0FB),
                  contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 18, vertical: isMobile ? 6 : 14),
                )).toList(),
              ],
            ),
          ),
        );
      },
    ).then((selectedExam) {
      if (selectedExam != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UploadMarksPage(
              schoolCode: widget.schoolCode,
              classId: classId,
              className: className,
              section: section,
              exam: selectedExam,
            ),
          ),
        );
      }
    });
  }

  Widget _marksUploadTab(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18),
        Text('Question Papers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 17 : 22)),
        SizedBox(height: 2),
        Text('View and customize question papers', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 14)),
        SizedBox(height: 10),
        Text(
          'Access question papers created by your principal. You can view, edit, and select questions for your exams.',
          style: TextStyle(color: Colors.black87, fontSize: isMobile ? 12 : 14),
        ),
        SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(
            color: Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Text('No question papers available yet', style: TextStyle(color: Colors.black54, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
