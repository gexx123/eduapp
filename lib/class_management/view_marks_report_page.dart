import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../services/firestore_service.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../widgets/marks_report/exam_dropdown.dart';
import '../widgets/marks_report/student_marks_table.dart';
import '../widgets/marks_report/ranks_card.dart';
import '../widgets/marks_report/subject_ranking_card.dart';

class ViewMarksReportPage extends StatefulWidget {
  final String schoolCode;
  final String classId;
  final String className;
  final String section;
  final String? exam;

  const ViewMarksReportPage({
    Key? key,
    required this.schoolCode,
    required this.classId,
    required this.className,
    required this.section,
    this.exam,
  }) : super(key: key);

  @override
  State<ViewMarksReportPage> createState() => _ViewMarksReportPageState();
}

class _ViewMarksReportPageState extends State<ViewMarksReportPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> students = [];
  List<String> subjects = [];
  Map<String, dynamic> subjectTeachers = {};
  String? teacherName;
  String? userRole;
  String? selectedExam;
  bool loading = true;
  List<String> exams = [];
  Map<String, Map<String, dynamic>> marksMap = {};

  @override
  void initState() {
    super.initState();
    _fetchContextAndStudents();
  }

  Future<void> _fetchContextAndStudents() async {
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
    // Exams list (static for now, can be dynamic)
    exams = ['PT 1', 'PT 2', 'Half Yearly', 'PT 3', 'PT 4', 'Yearly'];
    selectedExam = exams.isNotEmpty ? exams.first : null;
    // Students
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
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: Text(
          'Marks Report - ${widget.className}${widget.section.isNotEmpty ? ' ${widget.section}' : ''}',
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 17 : 21,
            letterSpacing: 0.4,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF222B45),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF222B45)),
        actions: [
          if (selectedExam != null)
            ExamDropdown(
              selectedExam: selectedExam!,
              exams: exams,
              onChanged: (val) {
                setState(() {
                  selectedExam = val;
                });
              },
            ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMarksForClassExam(widget.schoolCode, widget.classId, selectedExam!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No marks uploaded for $selectedExam.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 14 : 16),
                    ),
                  );
                }
                final marksList = snapshot.data!;
                marksList.forEach((marks) {
                  marksMap[marks['rollNumber']] = marks;
                });
                // --- RANKS LOGIC ---
                List<Map<String, dynamic>> rankedStudents = students.map((student) {
                  final roll = student['roll']?.toString() ?? student['rollNumber']?.toString() ?? '';
                  final name = student['name'] ?? '';
                  final markDoc = marksList.firstWhere(
                    (m) => (m['rollNumber']?.toString() ?? '') == roll,
                    orElse: () => {},
                  );
                  final total = subjects.fold<num>(0, (sum, s) {
                    final val = num.tryParse(markDoc[s]?.toString() ?? '');
                    return sum + (val ?? 0);
                  });
                  final totalOutOf = _getTotalOutOf(subjects, marksList);
                  final percent = totalOutOf > 0 ? ((total / totalOutOf) * 100) : 0.0;
                  return {
                    'roll': roll,
                    'name': name,
                    'total': total,
                    'percent': percent,
                  };
                }).toList();
                rankedStudents.sort((a, b) => b['total'].compareTo(a['total']));
                // Assign ranks (handle ties)
                int rank = 1;
                for (int i = 0; i < rankedStudents.length; i++) {
                  if (i > 0 && rankedStudents[i]['total'] < rankedStudents[i - 1]['total']) {
                    rank = i + 1;
                  }
                  rankedStudents[i]['rank'] = rank;
                }
                // --- SUBJECT RANKING LOGIC ---
                List<Map<String, dynamic>> subjectRanks = subjects.map((subject) {
                  double totalMarks = 0;
                  int studentCount = 0;
                  for (var student in students) {
                    final roll = student['roll']?.toString() ?? student['rollNumber']?.toString() ?? '';
                    final marks = marksMap[roll]?[subject];
                    if (marks != null) {
                      totalMarks += marks;
                      studentCount++;
                    }
                  }
                  final average = studentCount > 0 ? totalMarks / studentCount : 0;
                  return {
                    'subject': subject,
                    'average': average,
                  };
                }).toList();
                subjectRanks.sort((a, b) => b['average'].compareTo(a['average']));
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 24, horizontal: isMobile ? 0 : 70),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- STUDENT REPORT TITLE & DOWNLOAD ICON ---
                        Padding(
                          padding: EdgeInsets.only(left: isMobile ? 10 : 4, bottom: isMobile ? 14 : 20, top: isMobile ? 10 : 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('STUDENT REPORT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: isMobile ? 18 : 24,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF222B45),
                                  )),
                              SizedBox(width: 10),
                              InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () async {
                                  if (loading) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Please wait for data to load.')),
                                    );
                                    return;
                                  }
                                  if (students.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No student data to export.')),
                                    );
                                    return;
                                  }
                                  if (marksMap.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No marks data to export.')),
                                    );
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Generating PDF...')),
                                  );
                                  final pdf = pw.Document();
                                  final font = await PdfGoogleFonts.notoSansRegular();
                                  final fontBold = await PdfGoogleFonts.notoSansBold();
                                  pdf.addPage(
                                    pw.MultiPage(
                                      theme: pw.ThemeData.withFont(
                                        base: font,
                                        bold: fontBold,
                                      ),
                                      build: (pw.Context context) => [
                                        pw.Text('Student Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                                        pw.SizedBox(height: 16),
                                        pw.Table.fromTextArray(
                                          headers: [
                                            'Roll',
                                            'Name',
                                            ...subjects,
                                            'Total',
                                            'Percentage %',
                                          ],
                                          data: students.map((student) {
                                            final roll = student['roll']?.toString() ?? student['rollNumber']?.toString() ?? '';
                                            final name = student['name'] ?? '';
                                            final marks = marksMap[roll] ?? {};
                                            final total = marks['total'] ?? '';
                                            final percent = marks['percent'] ?? '';
                                            return [
                                              roll,
                                              name,
                                              ...subjects.map((s) => marks[s]?.toString() ?? '-'),
                                              total.toString(),
                                              percent.toString(),
                                            ];
                                          }).toList(),
                                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                                          headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
                                          cellAlignment: pw.Alignment.centerLeft,
                                          cellStyle: pw.TextStyle(fontSize: 11),
                                          cellHeight: 22,
                                          border: pw.TableBorder.all(color: PdfColors.grey300),
                                        ),
                                        pw.SizedBox(height: 24),
                                        pw.Text('Ranks', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                                        pw.SizedBox(height: 8),
                                        pw.Table.fromTextArray(
                                          headers: ['Rank', 'Roll', 'Name', 'Total', 'Percentage %'],
                                          data: rankedStudents.map((r) => [
                                            r['rank'],
                                            r['roll'],
                                            r['name'],
                                            r['total'],
                                            '${r['percent'].toStringAsFixed(1)}%',
                                          ]).toList(),
                                          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                                          headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
                                          cellAlignment: pw.Alignment.centerLeft,
                                          cellStyle: pw.TextStyle(fontSize: 11),
                                          cellHeight: 22,
                                          border: pw.TableBorder.all(color: PdfColors.grey300),
                                        ),
                                      ],
                                    ),
                                  );
                                  final bytes = await pdf.save();
                                  if (kIsWeb) {
                                    final blob = html.Blob([bytes], 'application/pdf');
                                    final url = html.Url.createObjectUrlFromBlob(blob);
                                    final anchor = html.AnchorElement(href: url)
                                      ..setAttribute('download', 'student_report.pdf')
                                      ..click();
                                    html.Url.revokeObjectUrl(url);
                                  } else {
                                    await Printing.layoutPdf(onLayout: (format) async => bytes);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFEEF7FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.download_rounded, size: isMobile ? 22 : 26, color: Color(0xFF1976D2)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // --- STUDENT MARKS TABLE ---
                        StudentMarksTable(
                          students: students,
                          subjects: subjects,
                          marksMap: marksMap,
                        ),
                        SizedBox(height: isMobile ? 18 : 32),
                        if (!isMobile)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: RanksCard(rankedStudents: rankedStudents),
                                ),
                              ),
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 16),
                                  child: SubjectRankingCard(subjectRanks: subjectRanks),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          RanksCard(rankedStudents: rankedStudents),
                          SizedBox(height: 16),
                          SubjectRankingCard(subjectRanks: subjectRanks),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Helper function to get out-of-marks for a subject from the marksList
  int _getOutOfMarks(String subject, List<Map<String, dynamic>> marksList) {
    for (final doc in marksList) {
      final outOf = doc['outOf_$subject'];
      if (outOf != null) return int.tryParse(outOf.toString()) ?? 0;
    }
    return 0;
  }

  // Helper function to get the total out-of-marks for all subjects
  int _getTotalOutOf(List<String> subjects, List<Map<String, dynamic>> marksList) {
    int total = 0;
    for (final s in subjects) {
      total += _getOutOfMarks(s, marksList);
    }
    return total;
  }
}
