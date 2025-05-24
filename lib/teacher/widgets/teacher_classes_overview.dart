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
        Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final showRow = screenWidth > 400;
            if (onManageClass != null && showRow) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Classes & Student Marks',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth <= 360 ? 15.0 : (isMobile ? 17.0 : 22.0),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage your classes and upload student marks',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: screenWidth <= 360 ? 11.0 : (isMobile ? 12.0 : 14.0),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TeacherQuickActions(
                    isMobile: isMobile,
                    onManageClass: onManageClass!,
                    showManageClass: true,
                  ),
                ],
              );
            } else if (onManageClass != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Classes & Student Marks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth <= 360 ? 15.0 : (isMobile ? 17.0 : 22.0),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage your classes and upload student marks',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenWidth <= 360 ? 11.0 : (isMobile ? 12.0 : 14.0),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Spacer(),
                      TeacherQuickActions(
                        isMobile: isMobile,
                        onManageClass: onManageClass!,
                        showManageClass: true,
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Classes & Student Marks',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth <= 360 ? 15.0 : (isMobile ? 17.0 : 22.0),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage your classes and upload student marks',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: screenWidth <= 360 ? 11.0 : (isMobile ? 12.0 : 14.0),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }
          },
        ),
        SizedBox(height: isMobile ? 10 : 18),
        StreamBuilder<List<SchoolClass>>(
          stream: FirestoreService().getClassesForTeacher(schoolCode, '', teacherName: teacherName),
          builder: classListBuilder,
        ),
      ],
    );
  }
}
