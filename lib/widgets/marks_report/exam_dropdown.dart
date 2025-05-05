import 'package:flutter/material.dart';

class ExamDropdown extends StatelessWidget {
  final String selectedExam;
  final List<String> exams;
  final ValueChanged<String?> onChanged;

  const ExamDropdown({
    Key? key,
    required this.selectedExam,
    required this.exams,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      margin: EdgeInsets.only(right: isMobile ? 8 : 24, top: 8, bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF1976D2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedExam,
          items: exams.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: TextStyle(fontWeight: FontWeight.bold)),
          )).toList(),
          onChanged: onChanged,
          style: TextStyle(color: Color(0xFF222B45), fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1976D2)),
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}
