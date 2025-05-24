import 'package:flutter/material.dart';

/// Shows a dialog notifying the user to assign teachers before uploading marks.
/// Displays the class teacher information for context.
/// 
/// [classTeacherName] - The name of the class teacher (if available)
/// 
/// Returns:
/// - true: User wants to navigate to Manage Class to assign teachers
/// - false: User wants to proceed with uploading marks for their own subjects only
/// - null: Dialog was dismissed
Future<bool?> showNotifyAssignTeacherDialog(BuildContext context, {String? classTeacherName}) async {
  final isMobile = MediaQuery.of(context).size.width < 600;
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      child: Container(
        width: isMobile ? MediaQuery.of(context).size.width * 0.93 : 380,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: isMobile ? 48 : 54),
            SizedBox(height: 18),
            Text(
              'Assign Teachers Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 14),
            if (classTeacherName != null) ...[              
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Class Teacher: $classTeacherName',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: isMobile ? 13 : 14, color: Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
            ],
            Text(
              'Assign teachers to all subjects in this class for complete mark management.',
              style: TextStyle(fontSize: isMobile ? 15 : 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'You can assign teachers later or proceed with uploading marks for your own subjects now.',
              style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                    elevation: 0,
                  ),
                  child: Text('Assign Teacher'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                  child: Text('Assign Teacher Later'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
