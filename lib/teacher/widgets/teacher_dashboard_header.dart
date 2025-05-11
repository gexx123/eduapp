import 'package:flutter/material.dart';

class TeacherDashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final String teacherName;
  final String schoolName;
  final String schoolCode;
  final VoidCallback onLogout;
  final bool isMobile;

  const TeacherDashboardHeader({
    super.key,
    required this.teacherName,
    required this.schoolName,
    required this.schoolCode,
    required this.onLogout,
    required this.isMobile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 36, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '-',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  teacherName.isNotEmpty ? teacherName : 'Teacher',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4FD),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text('School Code: ', style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.black54)),
                      SelectableText(schoolCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13, color: Color(0xFF1976D2))),
                    ],
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle, color: Colors.blueGrey, size: 28),
              onSelected: (value) async {
                if (value == 'profile') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Profile'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('User Name:'),
                          const SizedBox(height: 4),
                          Text(teacherName.isNotEmpty ? teacherName : 'Teacher', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('School:'),
                          const SizedBox(height: 4),
                          Text(schoolName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          const Text('School Code:'),
                          const SizedBox(height: 4),
                          Text(schoolCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } else if (value == 'logout') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onLogout();
                          },
                          child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: Colors.blueGrey, size: 20),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Log Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

