import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../class_management/upload_marks_page.dart';

class ExamSelectionDialog extends StatefulWidget {
  final String schoolCode;
  final String classId;
  final String className;
  final String section;
  final List<String>? exams;
  final void Function(String selectedExam)? onExamSelected;

  const ExamSelectionDialog({
    Key? key,
    required this.schoolCode,
    required this.classId,
    required this.className,
    required this.section,
    this.exams,
    this.onExamSelected,
  }) : super(key: key);

  @override
  State<ExamSelectionDialog> createState() => _ExamSelectionDialogState();
}

class _ExamSelectionDialogState extends State<ExamSelectionDialog> {
  late List<String> exams;
  Map<String, String> examStatus = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    exams = widget.exams ?? [
      'PT 1', 'PT 2', 'Half Yearly', 'PT 3', 'PT 4', 'Yearly'
    ];
    _fetchStatuses();
  }

  Future<void> _fetchStatuses() async {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;
    final groupSnap = await FirebaseFirestore.instance
        .collection('group_member')
        .where('userId', isEqualTo: user?.uid)
        .limit(1)
        .get();
    String? teacherName = groupSnap.docs.isNotEmpty ? groupSnap.docs.first.data()['name'] : null;
    final classDoc = await FirebaseFirestore.instance
        .collection('school_classes')
        .doc(widget.schoolCode)
        .collection('classesData')
        .doc(widget.classId)
        .get();
    Map<String, dynamic> subjectTeachers = {};
    List<String> subjects = [];
    if (classDoc.exists && classDoc.data() != null) {
      subjectTeachers = Map<String, dynamic>.from(classDoc.data()!['subjectTeachers'] ?? {});
      subjects = List<String>.from(classDoc.data()!['subjects'] ?? []);
    }
    final Map<String, String> statusMap = {};
    for (final exam in exams) {
      final marks = await firestoreService.getMarksForClassExam(widget.schoolCode, widget.classId, exam).first;
      bool uploadedByMe = false;
      bool uploadedByAnyone = false;
      for (final subject in subjects) {
        for (final m in marks) {
          if (m[subject] != null && m[subject].toString().isNotEmpty) {
            uploadedByAnyone = true;
            if (m['uploadedBy'] == user?.uid || (teacherName != null && subjectTeachers[subject]?.toString()?.toLowerCase() == teacherName.toLowerCase())) {
              uploadedByMe = true;
            }
          }
        }
      }
      if (uploadedByMe) {
        statusMap[exam] = 'uploaded';
      } else if (uploadedByAnyone) {
        statusMap[exam] = 'ongoing';
      } else {
        statusMap[exam] = 'not_started';
      }
    }
    setState(() {
      examStatus = statusMap;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 16 : 24)),
      backgroundColor: const Color(0xFFF8F7FC),
      child: Container(
        width: isMobile ? double.infinity : 480,
        constraints: BoxConstraints(maxWidth: 520),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 32, vertical: isMobile ? 16 : 30),
        child: loading
            ? Center(child: CircularProgressIndicator())
            : Column(
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
                  ...exams.map((exam) {
                    final status = examStatus[exam] ?? 'not_started';
                    Color? tileColor;
                    IconData? icon;
                    String? trailingText;
                    Color? iconColor;
                    if (status == 'uploaded') {
                      tileColor = Colors.green.shade50;
                      icon = Icons.check_circle;
                      iconColor = Colors.green;
                    } else if (status == 'ongoing') {
                      tileColor = Colors.yellow.shade50;
                      icon = Icons.autorenew;
                      iconColor = Colors.amber;
                      trailingText = 'Ongoing';
                    } else {
                      tileColor = null;
                      icon = Icons.radio_button_unchecked;
                      iconColor = Colors.grey;
                    }
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(icon, color: iconColor, size: 24),
                        title: Text(
                          exam,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: isMobile ? 15 : 17,
                            color: Color(0xFF222B45),
                          ),
                        ),
                        trailing: trailingText != null
                            ? Text(trailingText, style: TextStyle(fontSize: 14, color: Colors.amber.shade800, fontWeight: FontWeight.w500))
                            : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (widget.onExamSelected != null) {
                            widget.onExamSelected!(exam);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UploadMarksPage(
                                  schoolCode: widget.schoolCode,
                                  classId: widget.classId,
                                  className: widget.className,
                                  section: widget.section,
                                  exam: exam,
                                ),
                              ),
                            );
                          }
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        tileColor: null,
                        hoverColor: Color(0xFFE9F0FB),
                        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 18, vertical: isMobile ? 6 : 14),
                      ),
                    );
                  }).toList(),
                ],
              ),
      ),
    );
  }
}
