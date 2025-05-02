import 'package:flutter/material.dart';

/// InfoCard widget for displaying a label, icon, and value in a card style.
class InfoCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool isMobile;

  const InfoCard({
    Key? key,
    required this.label,
    required this.icon,
    required this.value,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? double.infinity : 170,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 22, horizontal: isMobile ? 16 : 22),
      margin: EdgeInsets.only(bottom: 8, right: isMobile ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
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
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 15)),
                SizedBox(height: 6),
                Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: isMobile ? 14 : 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
