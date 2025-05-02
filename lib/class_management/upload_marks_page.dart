import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/student.dart';

/// UploadMarksPage: Allows teachers to enter and upload marks for a class & exam
class UploadMarksPage extends StatefulWidget {
  final String schoolCode;
  final String classId;
  final String className;
  final String section;
  final String exam;

  const UploadMarksPage({
    Key? key,
    required this.schoolCode,
    required this.classId,
    required this.className,
    required this.section,
    required this.exam,
  }) : super(key: key);

  @override
  State<UploadMarksPage> createState() => _UploadMarksPageState();
}

class _UploadMarksPageState extends State<UploadMarksPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool loading = false;
  List<Map<String, dynamic>> students = [];
  Map<String, Map<String, TextEditingController>> marksControllers = {};
  List<String> subjects = [];
  Map<String, dynamic> subjectTeachers = {};
  String? teacherName;
  String? userRole;
  Map<String, TextEditingController> outOfControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchUserAndClassContext();
  }

  Future<void> _fetchUserAndClassContext() async {
    setState(() => loading = true);
    final user = FirebaseAuth.instance.currentUser;
    final groupSnap = await FirebaseFirestore.instance
        .collection('group_member')
        .where('userId', isEqualTo: user?.uid)
        .limit(1)
        .get();
    if (groupSnap.docs.isNotEmpty) {
      teacherName = groupSnap.docs.first.data()['name'];
      userRole = groupSnap.docs.first.data()['role'];
    }
    final classDoc = await FirebaseFirestore.instance
        .collection('school_classes')
        .doc(widget.schoolCode)
        .collection('classesData')
        .doc(widget.classId)
        .get();
    if (classDoc.exists && classDoc.data() != null) {
      subjectTeachers = Map<String, dynamic>.from(classDoc.data()!['subjectTeachers'] ?? {});
      subjects = List<String>.from(classDoc.data()!['subjects'] ?? []);
    }
    final doc = await FirebaseFirestore.instance
        .collection('student_master')
        .doc(widget.schoolCode)
        .collection(widget.classId)
        .doc('students')
        .get();
    final data = doc.data();
    if (data != null && data['students'] != null) {
      students = List<Map<String, dynamic>>.from(data['students']);
    }
    if (userRole == 'teacher' && teacherName != null) {
      final assignedSubjects = subjectTeachers.entries
          .where((e) => (e.value?.toString()?.toLowerCase() ?? '') == teacherName!.toLowerCase())
          .map((e) => e.key)
          .toList();
      if (assignedSubjects.isNotEmpty) {
        subjects = assignedSubjects;
      }
    }
    // Initialize out-of-marks controllers
    for (final subject in subjects) {
      outOfControllers[subject] = TextEditingController();
    }
    final marksSnap = await FirebaseFirestore.instance
        .collection('marks')
        .doc(widget.schoolCode)
        .collection(widget.classId)
        .doc(widget.exam)
        .collection('students')
        .get();
    final existingMarks = {for (var doc in marksSnap.docs) doc.id: doc.data()};
    for (final student in students) {
      final roll = student['roll']?.toString() ?? student['rollNumber']?.toString() ?? '';
      marksControllers[roll] = {};
      for (final subject in subjects) {
        final mark = existingMarks[roll] != null &&
                        (existingMarks[roll] as Map<String, dynamic>?) != null &&
                        (existingMarks[roll] as Map<String, dynamic>?)![subject] != null
            ? (existingMarks[roll] as Map<String, dynamic>?)![subject].toString()
            : '';
        marksControllers[roll]![subject] = TextEditingController(text: mark);
        // Pre-fill out-of-marks if present
        final outOfKey = 'outOf_$subject';
        if (existingMarks[roll] != null &&
            (existingMarks[roll] as Map<String, dynamic>?) != null &&
            (existingMarks[roll] as Map<String, dynamic>?)![outOfKey] != null &&
            outOfControllers[subject]?.text.isEmpty == true) {
          outOfControllers[subject]?.text = (existingMarks[roll] as Map<String, dynamic>?)![outOfKey].toString();
        }
      }
    }
    setState(() => loading = false);
  }

  Future<void> _uploadMarks() async {
    setState(() => loading = true);
    try {
      for (final student in students) {
        final roll = student['roll']?.toString() ?? student['rollNumber']?.toString() ?? '';
        final name = student['name'] ?? '';
        final marksData = {
          'studentName': name,
          'rollNumber': roll,
          'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
        };
        for (final subject in subjects) {
          final controller = marksControllers[roll]?[subject];
          if (controller != null && controller.text.trim().isNotEmpty) {
            marksData[subject] = int.tryParse(controller.text.trim()) ?? controller.text.trim();
          }
          // Save out-of-marks for this subject if provided
          final outOf = outOfControllers[subject]?.text.trim();
          if (outOf != null && outOf.isNotEmpty) {
            marksData['outOf_$subject'] = int.tryParse(outOf) ?? outOf;
          }
        }
        await _firestoreService.uploadStudentMarks(
          widget.schoolCode,
          widget.classId,
          widget.exam,
          roll,
          marksData,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marks uploaded successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading marks: $e')),
      );
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Marks - ${widget.className}${widget.section.isNotEmpty ? ' ${widget.section}' : ''}'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF222B45),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF222B45)),
      ),
      backgroundColor: const Color(0xFFF8F7FC),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(child: Text('No students found.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return Column(
                      children: [
                        // Out-of-marks row
                        if (subjects.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: isMobile ? 10 : 24, left: isMobile ? 4 : 18, right: isMobile ? 4 : 18),
                            padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 12, horizontal: isMobile ? 6 : 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFEDF2FB),
                              borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(width: isMobile ? 35 : 55),
                                SizedBox(width: isMobile ? 60 : 100, child: Text('Out of', style: TextStyle(color: Color(0xFF5B8DEE), fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15))),
                                ...subjects.map((subject) => SizedBox(
                                  width: isMobile ? 52 : 80,
                                  child: TextField(
                                    controller: outOfControllers[subject],
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(fontSize: isMobile ? 13 : 15, color: Color(0xFF222B45)),
                                    decoration: InputDecoration(
                                      hintText: 'Max',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(isMobile ? 6 : 8)),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: isMobile ? 6 : 10),
                                      isDense: true,
                                      filled: true,
                                      fillColor: Color(0xFFF8F7FC),
                                    ),
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        // Beautiful marks table
                        Container(
                          margin: EdgeInsets.only(top: isMobile ? 10 : 24, left: isMobile ? 4 : 18, right: isMobile ? 4 : 18),
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 12, horizontal: isMobile ? 6 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Color(0xFFEDF2FB)),
                              columnSpacing: isMobile ? 12 : 24,
                              dataRowMinHeight: isMobile ? 32 : 48,
                              dataRowMaxHeight: isMobile ? 44 : 56,
                              columns: [
                                DataColumn(label: Text('Roll', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 15, color: Color(0xFF222B45)))),
                                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 15, color: Color(0xFF222B45)))),
                                ...subjects.map((s) => DataColumn(label: Text(s, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 15, color: Color(0xFF5B8DEE))))).toList(),
                              ],
                              rows: students.map((student) {
                                final roll = student['roll']?.toString() ?? student['rollNumber']?.toString() ?? '';
                                final name = student['name'] ?? '';
                                return DataRow(
                                  cells: [
                                    DataCell(Text(roll, style: TextStyle(fontSize: isMobile ? 13 : 15))),
                                    DataCell(Text(name, style: TextStyle(fontSize: isMobile ? 13 : 15, fontWeight: FontWeight.w500))),
                                    ...subjects.map((subject) {
                                      return DataCell(
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF8F7FC),
                                            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                            border: Border.all(color: Color(0xFF5B8DEE).withOpacity(0.18)),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 2),
                                          child: TextField(
                                            controller: marksControllers[roll]?[subject],
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(fontSize: isMobile ? 13 : 15),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: isMobile ? 6 : 10),
                                              isDense: true,
                                              hintText: '-',
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Spacer(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 24, vertical: isMobile ? 8 : 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _uploadMarks,
                              icon: Icon(Icons.cloud_upload, size: isMobile ? 18 : 20),
                              label: Text('Upload Marks', style: TextStyle(fontSize: isMobile ? 14 : 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF5B8DEE),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 8 : 10)),
                                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
                                textStyle: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
