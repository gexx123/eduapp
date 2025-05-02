import 'package:flutter/material.dart';

/// TaskCard widget for displaying a dashboard task with status and actions.
class TaskCard extends StatelessWidget {
  final String title;
  final String due;
  final String description;
  final String status;
  final Color statusColor;
  final String priority;
  final Color priorityColor;
  final Color priorityTextColor;
  final VoidCallback? onViewDetails;
  final VoidCallback? onUpdateStatus;

  const TaskCard({
    Key? key,
    required this.title,
    required this.due,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.priority,
    required this.priorityColor,
    required this.priorityTextColor,
    this.onViewDetails,
    this.onUpdateStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Container(
                margin: EdgeInsets.only(left: 8, top: 2),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(priority, style: TextStyle(fontSize: 14, color: priorityTextColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(due, style: TextStyle(fontSize: 13, color: Colors.black54)),
          SizedBox(height: 8),
          Text(description, style: TextStyle(fontSize: 15)),
          SizedBox(height: 16),
          Row(
            children: [
              Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              Spacer(),
              OutlinedButton(
                onPressed: onViewDetails,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF1976D2),
                  side: BorderSide(color: Color(0xFF1976D2)),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                child: Text('View Details'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: onUpdateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                child: Text('Update Status'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
