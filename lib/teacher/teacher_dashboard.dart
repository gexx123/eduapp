import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../onboarding/teacher_onboarding_dialog.dart';
import 'widgets/teacher_dashboard_header.dart';
import 'widgets/teacher_quick_actions.dart';
import 'widgets/teacher_dashboard_tabbar.dart';
import 'widgets/teacher_classes_overview.dart';
import 'widgets/teacher_tasks_panel.dart';
import 'widgets/teacher_marks_panel.dart';
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
  bool isClassTeacher = false;
  String? teacherName;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    if (showJoinBanner) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => showJoinBanner = false);
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    await Future.wait([
      _initAsync(),
      _getTeacherName(),
    ]);
    // Add any additional dashboard-wide fetches here if needed
  }

  Future<void> _getTeacherName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final gmDoc = await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
    if (gmDoc.docs.isNotEmpty) {
      final data = gmDoc.docs.first.data();
      setState(() {
        teacherName = data['name'];
        isClassTeacher = (data['isClassTeacher'] ?? false) == true;
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
        // Set classAssigned in group_member
        await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1).get().then((snap) {
          if (snap.docs.isNotEmpty) {
            snap.docs.first.reference.set({'classAssigned': '${newClass.className}_${newClass.section}'}, SetOptions(merge: true));
          }
        });
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
    final docData = gmDoc.docs.first.data();
    final classAssigned = docData.containsKey('classAssigned') ? docData['classAssigned'] : null;
    final schoolCode = docData['schoolCode'];
    String? classToManage = classAssigned;
    // If classAssigned is missing, try to find a class created by this teacher
    if (classToManage == null || classToManage.toString().trim().isEmpty) {
      final classesSnap = await FirebaseFirestore.instance
          .collection('school_classes')
          .doc(schoolCode)
          .collection('classesData')
          .where('createdBy', isEqualTo: uid)
          .limit(1)
          .get();
      if (classesSnap.docs.isNotEmpty) {
        classToManage = classesSnap.docs.first.id; // use the doc ID, which is className_section
      }
    }
    if (classToManage == null || classToManage.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No class assigned or created by you.')));
      return;
    }
    // Use FirestoreService to fetch class
    final schoolClass = await _firestoreService.getClass(schoolCode, classToManage);
    if (schoolClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class not found.')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageClassPage(
          schoolClass: schoolClass,
          schoolCode: schoolCode,
        ),
      ),
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

  void _handleLogout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
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
      appBar: TeacherDashboardHeader(
        teacherName: teacherName ?? '',
        schoolName: widget.schoolName,
        schoolCode: widget.schoolCode,
        isMobile: isMobile,
        onLogout: _handleLogout,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 28, vertical: isMobile ? 14 : 30),
          children: [
            SizedBox(height: 18),
            SummaryCard(
              title: widget.schoolName,
              value: 'School Code: ${widget.schoolCode}',
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
                InfoCard(label: 'Due Dates', icon: Icons.calendar_today, value: '2', isMobile: isMobile),
              ],
            ),
            SizedBox(height: 18),
            _teacherTabBar(isMobile),
            SizedBox(height: 10),
            Builder(
              builder: (context) {
                if (tabIndex == 0) {
                  return _classesTab(isMobile);
                } else if (tabIndex == 1) {
                  return _assignedTasksTab(isMobile);
                } else {
                  return _marksUploadTab(isMobile);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _teacherTabBar(bool isMobile) {
  return TeacherDashboardTabBar(
    tabIndex: tabIndex,
    onTabChanged: (i) => setState(() => tabIndex = i),
    isMobile: isMobile,
  );
}

  Widget _assignedTasksTab(bool isMobile) {
  return TeacherTasksPanel(isMobile: isMobile);
}

  Widget _classesTab(bool isMobile) {
  return TeacherClassesOverview(
    schoolCode: widget.schoolCode,
    teacherName: teacherName,
    isMobile: isMobile,
    onManageClass: isClassTeacher && isClassCreated ? _showManageClassDialog : null,
    classListBuilder: (context, snapshot) {
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
  );
}

  Widget _classCard(SchoolClass schoolClass) {
    final classId = '${schoolClass.className}_${schoolClass.section}';
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth <= 360;
    final isMobile = screenWidth < 700;
    final cardPadding = isNarrow
        ? EdgeInsets.symmetric(vertical: 10, horizontal: 10)
        : isMobile
            ? EdgeInsets.symmetric(vertical: 14, horizontal: 14)
            : EdgeInsets.symmetric(vertical: 18, horizontal: 18);
    final titleFontSize = isNarrow ? 13.5 : (isMobile ? 15.0 : 16.0);
    final subtitleFontSize = isNarrow ? 11.0 : (isMobile ? 12.0 : 13.0);
    final iconSize = isNarrow ? 16.0 : (isMobile ? 18.0 : 20.0);
    final buttonPadding = isNarrow
        ? EdgeInsets.symmetric(horizontal: 6, vertical: 7)
        : EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final buttonFontSize = isNarrow ? 11.5 : (isMobile ? 13.0 : 14.0);
    final buttonSpacing = isNarrow ? 6.0 : 10.0;
    final cardElevation = isMobile ? 1.5 : 2.5;

    return Material(
      elevation: cardElevation,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: cardPadding,
        margin: EdgeInsets.only(bottom: isNarrow ? 6 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Class Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${schoolClass.className} - ${schoolClass.section}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isNarrow ? 2 : 4),
                  Text(
                    '${schoolClass.students.length} students',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: subtitleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: isNarrow ? 6 : 14),
            // Actions
            Flexible(
              child: isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ClassCardActionButton(
                          label: 'Upload Marks',
                          icon: Icons.file_upload_outlined,
                          isPrimary: true,
                          onPressed: () {
                            _showExamSelectionDialog(classId, schoolClass.className, schoolClass.section);
                          },
                        ),
                        SizedBox(height: buttonSpacing),
                        _ClassCardActionButton(
                          label: 'View Report',
                          icon: Icons.bar_chart_rounded,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ViewMarksReportPage(
                                  schoolCode: widget.schoolCode,
                                  classId: classId,
                                  className: schoolClass.className,
                                  section: schoolClass.section,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ClassCardActionButton(
                          label: 'Upload Marks',
                          icon: Icons.file_upload_outlined,
                          isPrimary: true,
                          onPressed: () {
                            _showExamSelectionDialog(classId, schoolClass.className, schoolClass.section);
                          },
                        ),
                        SizedBox(width: buttonSpacing),
                        _ClassCardActionButton(
                          label: 'View Report',
                          icon: Icons.bar_chart_rounded,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ViewMarksReportPage(
                                  schoolCode: widget.schoolCode,
                                  classId: classId,
                                  className: schoolClass.className,
                                  section: schoolClass.section,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
  return TeacherMarksPanel(isMobile: isMobile);
}
}

class _ClassCardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ClassCardActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: isPrimary 
            ? Theme.of(context).colorScheme.onPrimary 
            : Theme.of(context).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        minimumSize: Size(isSmallScreen ? 100 : 120, 36),
      ),
      icon: Icon(
        icon,
        size: isSmallScreen ? 16 : 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
