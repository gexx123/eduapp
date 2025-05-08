import 'package:flutter/material.dart';

/// Shows a dialog notifying the user to assign teachers before uploading marks.
/// Returns true if the user wants to navigate to Manage Class, false otherwise.
Future<bool?> showNotifyAssignTeacherDialog(BuildContext context) async {
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
            Text(
              'You must assign teachers to all subjects in this class before uploading marks.',
              style: TextStyle(fontSize: isMobile ? 15 : 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 8),
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
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
