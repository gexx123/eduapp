import 'package:flutter/material.dart';

import '../../widgets/task_card.dart';

class TeacherTasksPanel extends StatelessWidget {
  final bool isMobile;
  const TeacherTasksPanel({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18),
        Text('Tasks from Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 17 : 22)),
        SizedBox(height: 12),
        TaskCard(
          title: 'Submit Annual Lesson Plans',
          due: 'Due: 6/15/2023 · Type: Lesson Plan',
          description: 'All teachers need to submit their annual lesson plans for review',
          status: 'In Progress',
          statusColor: Color(0xFF1565C0),
          priority: 'High Priority',
          priorityColor: Color(0xFFFDE7E7),
          priorityTextColor: Color(0xFFD32F2F),
          onViewDetails: () {},
          onUpdateStatus: () {},
        ),
        SizedBox(height: 18),
        TaskCard(
          title: 'Mid-Term Assessment Reports',
          due: 'Due: 6/30/2023 · Type: Assessment',
          description: 'Complete mid-term assessment reports for all classes',
          status: 'Pending',
          statusColor: Color(0xFFF9A825),
          priority: 'Medium Priority',
          priorityColor: Color(0xFFFFF8E1),
          priorityTextColor: Color(0xFFFBC02D),
          onViewDetails: () {},
          onUpdateStatus: () {},
        ),
      ],
    );
  }
}
