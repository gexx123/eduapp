/// Task model for representing tasks/assignments in Firestore and UI logic.
class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String dueDate;
  final String assignedBy;
  final String assignedTo;
  final String type;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.assignedBy,
    required this.assignedTo,
    required this.type,
  });

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      priority: map['priority'] ?? '',
      dueDate: map['dueDate'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate,
      'assignedBy': assignedBy,
      'assignedTo': assignedTo,
      'type': type,
    };
  }
}
