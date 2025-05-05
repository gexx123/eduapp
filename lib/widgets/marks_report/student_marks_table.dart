import 'package:flutter/material.dart';

class StudentMarksTable extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final List<String> subjects;
  final Map<String, Map<String, dynamic>> marksMap;

  const StudentMarksTable({
    Key? key,
    required this.students,
    required this.subjects,
    required this.marksMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
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
            DataColumn(label: Text('Roll', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)))),
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45)))),
            ...subjects.map((s) => DataColumn(label: Row(
              children: [
                Text(s, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45))),
                SizedBox(width: 2),
                Text('(${marksMap[s]?['outOf'] ?? '-'})', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF888FA6), fontSize: isMobile ? 11 : 13)),
              ],
            ))),
            DataColumn(label: Row(
              children: [
                Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2))),
                SizedBox(width: 2),
                Text('(${marksMap['total']?['outOf'] ?? '-'})', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF888FA6), fontSize: isMobile ? 11 : 13)),
              ],
            )),
            DataColumn(label: Text('Percentage %', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)))),
          ],
          rows: students.map((student) {
            final roll = student['roll']?.toString() ?? student['rollNumber']?.toString() ?? '';
            final name = student['name'] ?? '';
            final markDoc = marksMap[roll] ?? {};
            final total = subjects.fold<num>(0, (sum, s) {
              final val = num.tryParse(markDoc[s]?.toString() ?? '');
              return sum + (val ?? 0);
            });
            final totalOutOf = marksMap['total']?['outOf'] ?? 0;
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
    );
  }
}
