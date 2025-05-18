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
        Text(
          'Classes & Student Marks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: MediaQuery.of(context).size.width <= 360 ? 15.0 : (isMobile ? 17.0 : 22.0),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: MediaQuery.of(context).size.width <= 360 ? 1 : 2),
        Text(
          'Manage your classes and upload student marks',
          style: TextStyle(
            color: Colors.black54,
            fontSize: MediaQuery.of(context).size.width <= 360 ? 11.0 : (isMobile ? 12.0 : 14.0),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: MediaQuery.of(context).size.width <= 360 ? 6 : (isMobile ? 10 : 16)),
        if (onManageClass != null)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TeacherQuickActions(
              isMobile: isMobile,
              onManageClass: onManageClass!,
              showManageClass: true,
            ),
          ),
        SizedBox(height: MediaQuery.of(context).size.width <= 360 ? 10 : 18),
        StreamBuilder<List<SchoolClass>>(
          stream: FirestoreService().getClassesForTeacher(schoolCode, '', teacherName: teacherName),
          builder: classListBuilder,
        ),
      ],
    );
  }
}
