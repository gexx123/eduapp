import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class.dart';
import '../models/student.dart';
import '../services/firestore_service.dart';
import 'package:flutter/services.dart';
import 'assign_teacher_dialog.dart';
import 'upload_marks_page.dart';

/// Page for main/class teacher to manage their class details and assign subject teachers.
class ManageClassPage extends StatefulWidget {
  final SchoolClass schoolClass;
  final String schoolCode;
  const ManageClassPage({Key? key, required this.schoolClass, required this.schoolCode}) : super(key: key);

  @override
  State<ManageClassPage> createState() => _ManageClassPageState();
}

class _ManageClassPageState extends State<ManageClassPage> {
  late SchoolClass editableClass;
  late Map<String, dynamic> subjectTeachers;
  bool loading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    editableClass = widget.schoolClass;
    subjectTeachers = Map<String, dynamic>.from(editableClass.subjectTeachers ?? {});
  }

  // Map subject to icon asset (expand as needed)
  final Map<String, IconData> subjectIcons = {
    'MATHS': Icons.calculate,
    'SCIENCE': Icons.science,
    'ENGLISH': Icons.menu_book,
    'HINDI': Icons.language,
    'SOCIAL': Icons.public,
    // Add more as needed
  };

  Future<List<Map<String, dynamic>>> fetchTeachers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('group_member')
        .where('schoolCode', isEqualTo: widget.schoolCode)
        .where('role', isEqualTo: 'teacher')
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  void assignTeacherToSubject(String subject, Map<String, dynamic> teacher) {
    setState(() {
      subjectTeachers[subject] = teacher['name'];
      editableClass = SchoolClass(
        className: editableClass.className,
        section: editableClass.section,
        subjects: editableClass.subjects,
        students: editableClass.students,
        subjectTeachers: subjectTeachers,
        classTeacherName: editableClass.classTeacherName,
      );
    });
    _firestoreService.saveClassWithCreator(
      widget.schoolCode,
      editableClass,
      FirebaseAuth.instance.currentUser!.uid,
      editableClass.classTeacherName ?? '',
      docId: '${editableClass.className}_${editableClass.section}',
    );
  }

  Future<void> saveAssignments() async {
    setState(() => loading = true);
    await _firestoreService.saveClassWithCreator(
      widget.schoolCode,
      editableClass,
      FirebaseAuth.instance.currentUser!.uid,
      editableClass.classTeacherName ?? '',
      docId: '${editableClass.className}_${editableClass.section}',
    );
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assignments saved!')),
    );
  }

  void showTeacherSelection(String subject) async {
    final teachers = await fetchTeachers();
    await showAssignTeacherDialog(
      context: context,
      subject: subject,
      teachers: teachers,
      onSelect: (teacher) {
        assignTeacherToSubject(subject, teacher);
      },
    );
  }

  void _showExamSelectionDialog(String classId, String className, String section) async {
    final List<String> exams = [
      'PT 1', 'PT 2', 'Half Yearly', 'PT 3', 'PT 4', 'Yearly'
    ];
    String? selectedExam;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFF8F7FC),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'Select Exam Type',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5B8DEE)),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, size: 28, color: Colors.black87),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                ...exams.map((exam) => ListTile(
                  title: Text(exam, style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    selectedExam = exam;
                    Navigator.of(context).pop();
                  },
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
    if (selectedExam != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => UploadMarksPage(
            schoolCode: widget.schoolCode,
            classId: classId,
            className: className,
            section: section,
            exam: selectedExam!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF222B45)),
        title: Text('Manage Class ${widget.schoolClass.className}${widget.schoolClass.section.isNotEmpty ? ' ${widget.schoolClass.section}' : ''}',
          style: TextStyle(color: Color(0xFF222B45), fontWeight: FontWeight.w600, fontSize: isMobile ? 17 : 20)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 48, vertical: isMobile ? 10 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: editableClass.className),
                    decoration: InputDecoration(
                      labelText: 'Class Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(fontSize: isMobile ? 15 : 17),
                    onChanged: (val) {
                      setState(() => editableClass = SchoolClass(
                        className: val,
                        section: editableClass.section,
                        subjects: editableClass.subjects,
                        students: editableClass.students,
                        subjectTeachers: subjectTeachers,
                        classTeacherName: editableClass.classTeacherName,
                      ));
                    },
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 24),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: editableClass.section),
                    decoration: InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(fontSize: isMobile ? 15 : 17),
                    onChanged: (val) {
                      final upper = val.toUpperCase();
                      setState(() => editableClass = SchoolClass(
                        className: editableClass.className,
                        section: upper,
                        subjects: editableClass.subjects,
                        students: editableClass.students,
                        subjectTeachers: subjectTeachers,
                        classTeacherName: editableClass.classTeacherName,
                      ));
                    },
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 14 : 22),
            Text('Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 17)),
            SizedBox(height: 6),
            ...editableClass.students.map((student) => Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(student['name'] ?? '', style: TextStyle(fontSize: isMobile ? 14 : 16)),
                subtitle: Text('Roll: ${student['roll']}', style: TextStyle(fontSize: isMobile ? 12 : 13)),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[400], size: isMobile ? 20 : 22),
                  onPressed: () async {
                    final newStudents = List<Map<String, dynamic>>.from(editableClass.students);
                    newStudents.removeAt(editableClass.students.indexOf(student));
                    setState(() {
                      editableClass = SchoolClass(
                        className: editableClass.className,
                        section: editableClass.section,
                        subjects: editableClass.subjects,
                        students: newStudents,
                        subjectTeachers: subjectTeachers,
                        classTeacherName: editableClass.classTeacherName,
                      );
                    });
                    _firestoreService.saveClassWithCreator(
                      widget.schoolCode,
                      editableClass,
                      FirebaseAuth.instance.currentUser!.uid,
                      editableClass.classTeacherName ?? '',
                      docId: '${editableClass.className}_${editableClass.section}',
                    );
                    // Save to student_master
                    _firestoreService.saveStudents(
                      widget.schoolCode,
                      '${editableClass.className}_${editableClass.section}',
                      newStudents.cast<Map<String, dynamic>>()
                            .map((s) => Student(name: s['name'], roll: s['roll']))
                            .toList(),
                    );
                  },
                ),
              ),
            )),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add, size: 18),
                label: Text('Add Student', style: TextStyle(fontSize: isMobile ? 13 : 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5B8DEE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                ),
                onPressed: () async {
                  final controller = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Add Student'),
                      content: TextField(
                        controller: controller,
                        decoration: InputDecoration(labelText: 'Student Name'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            final name = controller.text.trim();
                            if (name.isNotEmpty) {
                              final studentList = [
                                ...editableClass.students,
                                {'name': name, 'roll': (editableClass.students.length + 1).toString()},
                              ];
                              setState(() {
                                editableClass = SchoolClass(
                                  className: editableClass.className,
                                  section: editableClass.section,
                                  subjects: editableClass.subjects,
                                  students: studentList,
                                  subjectTeachers: subjectTeachers,
                                  classTeacherName: editableClass.classTeacherName,
                                );
                              });
                              await _firestoreService.saveClassWithCreator(
                                widget.schoolCode,
                                editableClass,
                                FirebaseAuth.instance.currentUser!.uid,
                                editableClass.classTeacherName ?? '',
                                docId: '${editableClass.className}_${editableClass.section}',
                              );
                              // Save to student_master
                              await _firestoreService.saveStudents(
                                widget.schoolCode,
                                '${editableClass.className}_${editableClass.section}',
                                studentList.cast<Map<String, dynamic>>()
                                  .map((s) => Student(name: s['name'], roll: s['roll']))
                                  .toList(),
                              );
                            }
                            Navigator.pop(ctx);
                          },
                          child: Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: isMobile ? 16 : 28),
            Text('Edit Subjects & Assign Teachers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 17)),
            SizedBox(height: 10),
            Wrap(
              spacing: isMobile ? 10 : 18,
              runSpacing: 12,
              children: editableClass.subjects.map((subject) => Container(
                width: isMobile ? 140 : 170,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFF5B8DEE), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book, color: Color(0xFF5B8DEE), size: isMobile ? 34 : 40),
                    SizedBox(height: 8),
                    Text(subject, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 16)),
                    SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () {
                        showTeacherSelection(subject);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF5B8DEE),
                        side: BorderSide(color: Color(0xFF5B8DEE)),
                        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: Text(editableClass.subjectTeachers?[subject] ?? 'Assign Teacher'),
                    ),
                  ],
                ),
              )).toList(),
            ),
            SizedBox(height: isMobile ? 20 : 34),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final oldKey = '${widget.schoolClass.className}_${widget.schoolClass.section}';
                  final newKey = '${editableClass.className}_${editableClass.section}';
                  // Check for duplicate (other than current)
                  if (oldKey != newKey) {
                    final existing = await _firestoreService.getClass(widget.schoolCode, newKey);
                    if (existing != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Class ${editableClass.className} ${editableClass.section} already exists!'), backgroundColor: Colors.red)
                      );
                      return;
                    }
                    // MOVE operation: create new doc, copy data, delete old doc
                    await _firestoreService.saveClassWithCreator(
                      widget.schoolCode,
                      editableClass,
                      FirebaseAuth.instance.currentUser!.uid,
                      editableClass.classTeacherName ?? '',
                      docId: newKey,
                    );
                    await _firestoreService.saveStudents(
                      widget.schoolCode,
                      newKey,
                      editableClass.students.cast<Map<String, dynamic>>()
                        .map((s) => Student(name: s['name'], roll: s['roll']))
                        .toList(),
                    );
                    // Delete old docs
                    await FirebaseFirestore.instance
                      .collection('school_classes')
                      .doc(widget.schoolCode)
                      .collection('classesData')
                      .doc(oldKey)
                      .delete();
                    await FirebaseFirestore.instance
                      .collection('student_master')
                      .doc(widget.schoolCode)
                      .collection(oldKey)
                      .doc('students')
                      .delete();
                  } else {
                    // Just update in place
                    await _firestoreService.saveClassWithCreator(
                      widget.schoolCode,
                      editableClass,
                      FirebaseAuth.instance.currentUser!.uid,
                      editableClass.classTeacherName ?? '',
                      docId: oldKey,
                    );
                    await _firestoreService.saveStudents(
                      widget.schoolCode,
                      oldKey,
                      editableClass.students.cast<Map<String, dynamic>>()
                        .map((s) => Student(name: s['name'], roll: s['roll']))
                        .toList(),
                    );
                  }
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7D4CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 17),
                  elevation: 0,
                ),
                child: Text('Save'),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
