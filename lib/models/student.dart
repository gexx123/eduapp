/// Student model for Firestore and UI logic.
class Student {
  final String roll;
  final String name;

  Student({required this.roll, required this.name});

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      roll: map['roll']?.toString() ?? '',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roll': roll,
      'name': name,
    };
  }
}
