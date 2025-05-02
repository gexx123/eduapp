import 'package:flutter/material.dart';

/// SummaryCard widget for dashboard summaries or quick stats.
class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final bool isMobile;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 180,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 20, horizontal: isMobile ? 16 : 20),
      margin: EdgeInsets.only(bottom: 8, right: isMobile ? 0 : 14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.all(8),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: isMobile ? 23 : 28),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15)),
                SizedBox(height: 6),
                Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: isMobile ? 15 : 19)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
