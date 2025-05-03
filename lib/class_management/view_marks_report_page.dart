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
    selectedExam = widget.exam ?? exams.first;
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
          Container(
            margin: EdgeInsets.only(right: isMobile ? 8 : 24, top: 8, bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Color(0xFFF4F4FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFE0E7FF), width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedExam,
                items: exams.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(fontWeight: FontWeight.w600)),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedExam = val;
                  });
                },
                style: TextStyle(color: Color(0xFF222B45), fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 15),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1976D2)),
                dropdownColor: Colors.white,
              ),
            ),
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
                List<_StudentRank> rankedStudents = students.map((student) {
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
                  return _StudentRank(
                    roll: roll,
                    name: name,
                    total: total,
                    percent: percent,
                  );
                }).toList();
                rankedStudents.sort((a, b) => b.total.compareTo(a.total));
                // Assign ranks (handle ties)
                int rank = 1;
                for (int i = 0; i < rankedStudents.length; i++) {
                  if (i > 0 && rankedStudents[i].total == rankedStudents[i - 1].total) {
                    rankedStudents[i].rank = rankedStudents[i - 1].rank;
                  } else {
                    rankedStudents[i].rank = rank;
                  }
                  rank++;
                }
                return Padding(
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
                                          r.rank,
                                          r.roll,
                                          r.name,
                                          r.total,
                                          '${r.percent.toStringAsFixed(1)}%',
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
                      // --- Original Data Table ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Color(0xFFF4F4FD)),
                            dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) {
                              if (states.contains(MaterialState.selected)) return Color(0xFFE3F2FD);
                              return null;
                            }),
                            columnSpacing: isMobile ? 14 : 32,
                            horizontalMargin: isMobile ? 10 : 28,
                            columns: [
                              DataColumn(label: Text('Roll', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)) )),
                              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45)) )),
                              ...subjects.map((s) => DataColumn(label: Row(
                                children: [
                                  Text(s, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45))),
                                  SizedBox(width: 2),
                                  Text('(${_getOutOfMarks(s, marksList)})', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF888FA6), fontSize: isMobile ? 11 : 13)),
                                ],
                              ))),
                              DataColumn(label: Row(
                                children: [
                                  Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2))),
                                  SizedBox(width: 2),
                                  Text('(${_getTotalOutOf(subjects, marksList)})', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF888FA6), fontSize: isMobile ? 11 : 13)),
                                ],
                              )),
                              ...subjects.map((s) => DataColumn(label: Text('Grade ($s)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6C63FF), fontSize: isMobile ? 12 : 13)))),
                              DataColumn(label: Text('Percentage %', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)))),
                            ],
                            rows: students.map((student) {
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
                              final percent = totalOutOf > 0 ? ((total / totalOutOf) * 100).toStringAsFixed(1) : '-';
                              return DataRow(
                                cells: [
                                  DataCell(Text(roll, style: TextStyle(fontWeight: FontWeight.w500, fontSize: isMobile ? 13 : 15))),
                                  DataCell(Text(name, style: TextStyle(fontWeight: FontWeight.w500, fontSize: isMobile ? 13 : 15))),
                                  ...subjects.map((s) => DataCell(Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(markDoc[s]?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222B45), fontSize: isMobile ? 13 : 15)),
                                  ))),
                                  DataCell(Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD1F2EB),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(total > 0 ? total.toString() : '-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF138D75), fontSize: isMobile ? 13 : 15)),
                                  )),
                                  ...subjects.map((s) => DataCell(Container(
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFEEF7FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(markDoc['grade_$s']?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1976D2), fontSize: isMobile ? 12 : 14)),
                                  ))),
                                  DataCell(Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFF9E5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(percent != '-' ? '$percent%' : '-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF39C12), fontSize: isMobile ? 13 : 15)),
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 18 : 32),
                      // --- RANKS TABLE ---
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: isMobile ? 12 : 24),
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueGrey.withOpacity(0.09),
                                blurRadius: 14,
                                offset: Offset(0, 5),
                              ),
                            ],
                            border: Border.all(color: Color(0xFFE0E7FF), width: 1),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: isMobile ? double.infinity : 520,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: isMobile ? 14 : 18),
                                child: Text(
                                  'Ranks',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 17 : 20,
                                    color: Color(0xFF222B45),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Color(0xFFF4F4FD)),
                                  columnSpacing: isMobile ? 14 : 32,
                                  horizontalMargin: isMobile ? 10 : 28,
                                  columns: [
                                    DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)))),
                                    DataColumn(label: Text('Roll', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45)))),
                                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45)))),
                                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF138D75)))),
                                    DataColumn(label: Text('Percentage %', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF39C12)))),
                                  ],
                                  rows: rankedStudents.map((r) {
                                    final isTop1 = r.rank == 1;
                                    final isTop2 = r.rank == 2;
                                    final isTop3 = r.rank == 3;
                                    final highlightColor = isTop1
                                        ? Color(0xFFFFF7D6)
                                        : isTop2
                                            ? Color(0xFFE6F7FF)
                                            : isTop3
                                                ? Color(0xFFF6E6FF)
                                                : Colors.transparent;
                                    final borderColor = isTop1
                                        ? Color(0xFFFFD700)
                                        : isTop2
                                            ? Color(0xFF40A9FF)
                                            : isTop3
                                                ? Color(0xFFB37FEB)
                                                : Colors.transparent;
                                    return DataRow(
                                      color: MaterialStateProperty.all(highlightColor),
                                      cells: [
                                        DataCell(Container(
                                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isTop1
                                                ? Color(0xFFFFF7D6)
                                                : isTop2
                                                    ? Color(0xFFE6F7FF)
                                                    : isTop3
                                                        ? Color(0xFFF6E6FF)
                                                        : Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: borderColor, width: isTop1 || isTop2 || isTop3 ? 2 : 0),
                                          ),
                                          child: Row(
                                            children: [
                                              if (isTop1)
                                                Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 18)
                                              else if (isTop2)
                                                Icon(Icons.emoji_events, color: Color(0xFF40A9FF), size: 18)
                                              else if (isTop3)
                                                Icon(Icons.emoji_events, color: Color(0xFFB37FEB), size: 18),
                                              SizedBox(width: 2),
                                              Text(r.rank.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                                            ],
                                          ),
                                        )),
                                        DataCell(Text(r.roll, style: TextStyle(fontWeight: FontWeight.w500))),
                                        DataCell(Text(r.name, style: TextStyle(fontWeight: FontWeight.w500))),
                                        DataCell(Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFD1F2EB),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(r.total > 0 ? r.total.toString() : '-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF138D75))),
                                        )),
                                        DataCell(Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFFF9E5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text('${r.percent.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF39C12))),
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 14),
                            ],
                          ),
                        ),
                      ),
                    ],
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

// Helper class for ranks
class _StudentRank {
  final String roll;
  final String name;
  final num total;
  final double percent;
  int rank;
  _StudentRank({required this.roll, required this.name, required this.total, required this.percent, this.rank = 0});
}
