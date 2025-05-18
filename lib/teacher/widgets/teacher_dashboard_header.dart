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
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth <= 360;
    final nameFontSize = isNarrow ? 13.5 : (isMobile ? 15.0 : 16.0);
    final codeFontSize = isNarrow ? 10.0 : (isMobile ? 11.0 : 13.0);
    final avatarRadius = isNarrow ? 16.0 : (isMobile ? 18.0 : 20.0);
    final horizontalPad = isNarrow ? 6.0 : (isMobile ? 10.0 : 36.0);
    final verticalPad = isNarrow ? 7.0 : (isMobile ? 10.0 : 14.0);

    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      teacherName.isNotEmpty ? teacherName[0].toUpperCase() : '-',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: avatarRadius,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: isNarrow ? 5 : 8),
                  Flexible(
                    child: Text(
                      teacherName.isNotEmpty ? teacherName : 'Teacher',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: nameFontSize),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: isNarrow ? 7 : 12),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 5 : 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('School Code: ',
                              style: TextStyle(fontSize: codeFontSize, color: Colors.black54)),
                          Flexible(
                            child: SelectableText(
                              schoolCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: codeFontSize,
                                color: Color(0xFF1976D2),
                              ),
                              maxLines: 1,
                              enableInteractiveSelection: true,
                              toolbarOptions: const ToolbarOptions(copy: true),
                              showCursor: false,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.account_circle, color: Colors.blueGrey, size: isNarrow ? 22 : 28),
              offset: Offset(0, isNarrow ? 30 : 40),
              constraints: BoxConstraints(
                minWidth: isNarrow ? 120 : 160,
                maxWidth: isNarrow ? 180 : 240,
              ),
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

