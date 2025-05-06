import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../onboarding/teacher_onboarding_dialog.dart';
import '../class_management/manage_class_dialog.dart';
import '../class_management/create_class_dialog.dart';
import '../class_management/manage_class_page.dart';
import '../class_management/upload_marks_page.dart';
import '../class_management/view_marks_report_page.dart';
import '../widgets/info_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/task_card.dart';
import '../widgets/student_tile.dart';
import '../widgets/exam_selection_dialog.dart';
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
                  Icon(Icons.person, color: Color(0xFF1976D2), size: 30),
                  SizedBox(width: 10),
                  Text(teacherName ?? 'Teacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 22)),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F4FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text('School Code: ', style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.black54)),
                        SelectableText(widget.schoolCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13, color: Color(0xFF1976D2))),
                      ],
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.account_circle, color: Colors.blueGrey, size: 28),
                onSelected: (value) async {
                  if (value == 'profile') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Profile'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User Name:'),
                            SizedBox(height: 4),
                            Text(teacherName ?? 'Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            Text('School:'),
                            SizedBox(height: 4),
                            Text(widget.schoolName, style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 12),
                            Text('School Code:'),
                            SizedBox(height: 4),
                            Text(widget.schoolCode, style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  } else if (value == 'logout') {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Log Out'),
                        content: Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await Future.delayed(Duration(milliseconds: 100));
                              await FirebaseAuth.instance.signOut();
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            },
                            child: Text('Log Out', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blueGrey, size: 20),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text('Log Out'),
                      ],
                    ),
                  ),
                ],
              ),
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
              children: classes.map((c) => _classCard(c)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _classCard(SchoolClass schoolClass) {
    final classId = '${schoolClass.className}_${schoolClass.section}';
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
              Text('${schoolClass.className} - ${schoolClass.section}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              SizedBox(height: 4),
              Text('${schoolClass.students.length} students', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _showExamSelectionDialog(classId, schoolClass.className, schoolClass.section);
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
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ViewMarksReportPage(
                        schoolCode: widget.schoolCode,
                        classId: classId,
                        className: schoolClass.className,
                        section: schoolClass.section,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.bar_chart_rounded, size: 16),
                label: Text('View Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
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
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ExamSelectionDialog(
        schoolCode: widget.schoolCode,
        classId: classId,
        className: className,
        section: section,
        onExamSelected: (selectedExam) {
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
        },
      ),
    );
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
