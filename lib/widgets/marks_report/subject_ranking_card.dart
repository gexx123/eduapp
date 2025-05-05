import 'package:flutter/material.dart';

class SubjectRankingCard extends StatelessWidget {
  final List<Map<String, dynamic>> subjectRanks;

  const SubjectRankingCard({
    Key? key,
    required this.subjectRanks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28, vertical: isMobile ? 14 : 18),
              child: Text(
                'Subject Rankings',
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
                  DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)) )),
                  DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)) )),
                  DataColumn(label: Text('Average Marks', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45)) )),
                ],
                rows: subjectRanks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subject = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text((index + 1).toString(), style: TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(subject['subject'], style: TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(subject['average'].toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF138D75)))),
                    ],
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: isMobile ? 8 : 14),
          ],
        ),
      ),
    );
  }
}
