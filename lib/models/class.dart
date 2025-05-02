/// Class model for representing a school class in Firestore and UI logic.
class SchoolClass {
  final String className;
  final String section;
  final List<String> subjects;
  final List<Map<String, dynamic>> students;
  final Map<String, dynamic>? subjectTeachers;
  final String? classTeacherName;

  SchoolClass({
    required this.className,
    required this.section,
    required this.subjects,
    required this.students,
    this.subjectTeachers,
    this.classTeacherName,
  });

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      subjects: List<String>.from(map['subjects'] ?? []),
      students: List<Map<String, dynamic>>.from(map['students'] ?? []),
      subjectTeachers: map['subjectTeachers'] != null ? Map<String, dynamic>.from(map['subjectTeachers']) : null,
      classTeacherName: map['classTeacherName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'section': section,
      'subjects': subjects,
      'students': students,
      if (subjectTeachers != null) 'subjectTeachers': subjectTeachers,
      if (classTeacherName != null) 'classTeacherName': classTeacherName,
    };
  }
}
