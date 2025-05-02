import 'package:flutter/material.dart';

/// Shows a dialog for assigning a teacher to a subject.
///
/// [subject] - The subject name to assign.
/// [teachers] - List of teacher maps from group_member collection.
/// [onSelect] - Callback when a teacher is selected.
/// Returns void.
Future<void> showAssignTeacherDialog({
  required BuildContext context,
  required String subject,
  required List<Map<String, dynamic>> teachers,
  required void Function(Map<String, dynamic> teacher) onSelect,
}) async {
  final isMobile = MediaQuery.of(context).size.width < 600;
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFFF8F7FC),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 80, vertical: isMobile ? 24 : 80),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.7 : 520,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Assign Teacher to $subject',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF5B8DEE)),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2.0, top: 2.0, left: 8.0),
                      child: Icon(Icons.close, size: 32, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: teachers.length,
                  itemBuilder: (context, idx) {
                    final teacher = teachers[idx];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF5B8DEE).withOpacity(0.13),
                          child: Icon(Icons.person, color: Color(0xFF5B8DEE)),
                        ),
                        title: Text(teacher['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          teacher['subject'] != null && (teacher['subject'] as String).isNotEmpty
                            ? 'Subject: ${teacher['subject']}'
                            : 'Subject: Not Assigned',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        onTap: () async {
                          final userSubject = (teacher['subject'] ?? '').toString().trim().toLowerCase();
                          final assignSubject = subject.trim().toLowerCase();
                          if (userSubject.isNotEmpty && userSubject != assignSubject) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                final isMobile = MediaQuery.of(context).size.width < 600;
                                return Dialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  backgroundColor: const Color(0xFFF8F7FC),
                                  insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 80, vertical: isMobile ? 36 : 120),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: 360,
                                      maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.35 : 280,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.warning_amber_rounded, color: Color(0xFFF9B233), size: 48),
                                          SizedBox(height: 12),
                                          Text('Subject Mismatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5B8DEE))),
                                          SizedBox(height: 10),
                                          Text(
                                            'This teacher is assigned to "${teacher['subject']}" but you are assigning them to "$subject". Are you sure you want to continue?',
                                            style: TextStyle(color: Colors.black87, fontSize: 15),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 22),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Color(0xFF222B45),
                                                    side: BorderSide(color: Color(0xFFB0B5C3)),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: EdgeInsets.symmetric(vertical: 10),
                                                  ),
                                                  child: Text('Cancel'),
                                                ),
                                              ),
                                              SizedBox(width: 14),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Color(0xFF5B8DEE),
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    padding: EdgeInsets.symmetric(vertical: 10),
                                                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  child: Text('Assign Anyway'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                            if (confirmed != true) return;
                          }
                          onSelect(teacher);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
