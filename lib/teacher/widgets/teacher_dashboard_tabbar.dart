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
    final tabs = [
      {'icon': Icons.class_, 'label': 'Classes & Marks'},
      {'icon': Icons.assignment_turned_in, 'label': 'Assigned Tasks'},
      {'icon': Icons.description, 'label': 'Question Papers'},
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth <= 360;
    final tabFontSize = isNarrow ? 11.0 : (isMobile ? 13.0 : 15.0);
    final tabPadding = isNarrow ? EdgeInsets.symmetric(horizontal: 6, vertical: 7) : EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    final iconSize = isNarrow ? 18.0 : (isMobile ? 22.0 : 24.0);

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (i) {
            final selected = i == tabIndex;
            return Padding(
              padding: EdgeInsets.only(right: isNarrow ? 4 : 8),
              child: TextButton.icon(
                icon: Icon(
                  tabs[i]['icon'] as IconData,
                  size: iconSize,
                  color: selected ? Color(0xFF1976D2) : Colors.black54,
                ),
                label: Text(
                  tabs[i]['label'] as String,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: tabFontSize,
                    color: selected ? Color(0xFF1976D2) : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  backgroundColor: selected ? Colors.white : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  padding: tabPadding,
                  minimumSize: Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => onTabChanged(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

