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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (showManageClass) ...[
            SizedBox(width: isMobile ? 10 : 18),
            ElevatedButton.icon(
              onPressed: onManageClass,
              icon: Icon(Icons.edit, size: isMobile ? 18 : 20),
              label: Text(
                'Manage Class',
                style: TextStyle(fontSize: isMobile ? 13 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 18,
                  vertical: isMobile ? 10 : 12,
                ),
                elevation: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

