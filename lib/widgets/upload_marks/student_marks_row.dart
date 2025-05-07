import 'package:flutter/material.dart';

class StudentMarksRow extends StatelessWidget {
  final String roll;
  final String name;
  final List<String> subjects;
  final Map<String, TextEditingController> marksControllers;
  final bool isMobile;

  const StudentMarksRow({
    Key? key,
    required this.roll,
    required this.name,
    required this.subjects,
    required this.marksControllers,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = isMobile ? 13 : 15;
    final double labelSpacing = isMobile ? 8 : 12;
    final double fieldWidth = isMobile ? 60 : 70;
    final double fieldHeight = isMobile ? 32 : 36;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Roll:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: const Color(0xFF222B45))),
            SizedBox(width: labelSpacing),
            Text(roll, style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize)),
            SizedBox(width: labelSpacing),
            Text('Name:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: const Color(0xFF222B45))),
            SizedBox(width: 4),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isMobile ? 70 : 120),
              child: Text(name, style: TextStyle(fontWeight: FontWeight.w500, fontSize: fontSize), overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
            SizedBox(width: labelSpacing),
            ...subjects.map((subject) => Row(
              children: [
                Text('$subject:', style: TextStyle(color: const Color(0xFF5B8DEE), fontWeight: FontWeight.w600, fontSize: fontSize)),
                SizedBox(width: 6),
                SizedBox(
                  width: fieldWidth,
                  height: fieldHeight,
                  child: TextField(
                    controller: marksControllers[subject],
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: fontSize),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.18)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.18)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: isMobile ? 8 : 10),
                      isDense: true,
                      hintText: '-',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.background,
                    ),
                  ),
                ),
                SizedBox(width: labelSpacing),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
