import 'package:flutter/material.dart';

class TeacherQuickActions extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onManageClass;
  final bool showManageClass;

  const TeacherQuickActions({
    super.key,
    required this.isMobile,
    required this.onManageClass,
    this.showManageClass = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showManageClass) ...[
            ElevatedButton.icon(
              onPressed: onManageClass,
              icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
              label: Text(
                'Manage Class',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B8DEE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 14,
                  vertical: isMobile ? 8 : 10,
                ),
                elevation: 0,
                minimumSize: Size(isMobile ? 100 : 120, 36),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

