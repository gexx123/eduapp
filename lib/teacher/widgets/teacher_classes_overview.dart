import 'package:flutter/material.dart';

import '../../models/class.dart';
import '../widgets/teacher_quick_actions.dart';
import '../../services/firestore_service.dart';

class TeacherClassesOverview extends StatelessWidget {
  final String schoolCode;
  final String? teacherName;
  final bool isMobile;
  final VoidCallback? onManageClass;
  final AsyncWidgetBuilder<List<SchoolClass>> classListBuilder;

  const TeacherClassesOverview({
    Key? key,
    required this.schoolCode,
    required this.teacherName,
    required this.isMobile,
    this.onManageClass,
    required this.classListBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18),
        Text('Classes & Student Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 17 : 22)),
        SizedBox(height: 2),
        Text('Manage your classes and upload student marks', style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 14)),
        SizedBox(height: isMobile ? 10 : 16),
        if (onManageClass != null)
          TeacherQuickActions(
            isMobile: isMobile,
            onManageClass: onManageClass!,
            showManageClass: true,
          ),
        SizedBox(height: 18),
        StreamBuilder<List<SchoolClass>>(
          stream: FirestoreService().getClassesForTeacher(schoolCode, '', teacherName: teacherName),
          builder: classListBuilder,
        ),
      ],
    );
  }
}
