import 'package:flutter/material.dart';

class TeacherMarksPanel extends StatelessWidget {
  final bool isMobile;
  const TeacherMarksPanel({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18),
        Text('Question Papers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 17 : 22)),
        SizedBox(height: 2),
        Text('View and customize question papers', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 14)),
        SizedBox(height: 10),
        Text(
          'Access question papers created by your principal. You can view, edit, and select questions for your exams.',
          style: TextStyle(color: Colors.black87, fontSize: isMobile ? 12 : 14),
        ),
        SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(
            color: Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Text('No question papers available yet', style: TextStyle(color: Colors.black54, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
