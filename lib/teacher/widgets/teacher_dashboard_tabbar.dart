import 'package:flutter/material.dart';

class TeacherDashboardTabBar extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final bool isMobile;

  const TeacherDashboardTabBar({
    Key? key,
    required this.tabIndex,
    required this.onTabChanged,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tabs = ['Classes & Marks', 'Assigned Tasks', 'Question Papers'];
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == tabIndex;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: selected ? Colors.white : Colors.transparent,
                foregroundColor: selected ? Color(0xFF1976D2) : Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15),
              ),
              onPressed: () => onTabChanged(i),
              child: Text(tabs[i]),
            ),
          );
        }),
      ),
    );
  }
}

