import 'package:flutter/material.dart';

class RanksCard extends StatelessWidget {
  final List<Map<String, dynamic>> rankedStudents;

  const RanksCard({
    Key? key,
    required this.rankedStudents,
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
                  DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1976D2)) )),
                  DataColumn(label: Text('Roll', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45)) )),
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF222B45)) )),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF138D75)) )),
                  DataColumn(label: Text('Percentage %', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFF39C12)) )),
                ],
                rows: rankedStudents.map((r) {
                  final isTop1 = r['rank'] == 1;
                  final isTop2 = r['rank'] == 2;
                  final isTop3 = r['rank'] == 3;
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
                            Text(r['rank'].toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                          ],
                        ),
                      )),
                      DataCell(Text(r['roll'], style: TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(r['name'], style: TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFFD1F2EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(r['total'] > 0 ? r['total'].toString() : '-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF138D75))),
                      )),
                      DataCell(Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF9E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${r['percent'].toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF39C12))),
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
    );
  }
}
