import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';

/// Manage Class Dialog
/// Usage: showManageClassDialog(context: context, ...);
Future<void> showManageClassDialog({
  required BuildContext context,
  required String schoolCode,
  required String className,
  required String section,
  required List<String> subjects,
  required List<Map<String, dynamic>> students,
  required Map<String, dynamic> subjectTeachers,
  required List<Map<String, dynamic>> teacherOptions,
  required Function(List<Map<String, dynamic>>, List<String>, Map<String, dynamic>) onSave,
}) async {
  final _classNameController = TextEditingController(text: className);
  final _sectionController = TextEditingController(text: section);
  List<String> selectedSubjects = List<String>.from(subjects);
  List<Map<String, dynamic>> studentList = List<Map<String, dynamic>>.from(students);
  Map<String, dynamic> subjectTeacherMap = Map<String, dynamic>.from(subjectTeachers);
  final List<Map<String, dynamic>> subjectGroups = [
    {
      'group': 'Languages',
      'subjects': [
        'English', 'Hindi', 'Sanskrit', 'Urdu', 'French', 'German', 'Spanish', 'Russian', 'Chinese',
        'Assamese', 'Bengali', 'Gujarati', 'Kannada', 'Kashmiri', 'Malayalam', 'Manipuri', 'Marathi',
        'Odia', 'Punjabi', 'Tamil', 'Telugu', 'Sindhi', 'Nepali', 'Bodo', 'Dogri', 'Garo', 'Khasi',
        'Lepcha', 'Limboo', 'Mizo', 'Rajasthani', 'Santhali', 'Sherpa', 'Tibetan', 'Bhutia', 'Persian', 'Japanese'
      ]
    },
    {
      'group': 'Sciences',
      'subjects': [
        'Mathematics', 'Applied Mathematics', 'Physics', 'Chemistry', 'Biology', 'Biotechnology', 'Computer Science',
        'Information Practices', 'Environmental Science', 'Science', 'Home Science', 'Psychology'
      ]
    },
    {
      'group': 'Commerce',
      'subjects': [
        'Accountancy', 'Business Studies', 'Economics', 'Banking', 'Marketing', 'Entrepreneurship', 'Statistics'
      ]
    },
    {
      'group': 'Humanities',
      'subjects': [
        'History', 'Geography', 'Political Science', 'Sociology', 'Fine Arts', 'Legal Studies', 'Mass Media', 'Media Studies', 'Design'
      ]
    },
    {
      'group': 'Vocational/Professional',
      'subjects': [
        'Vocational Studies', 'Retail', 'Automobile', 'Health Care', 'Tourism', 'Web Application', 'Artificial Intelligence', 'Fashion Studies'
      ]
    },
    {
      'group': 'Other',
      'subjects': [
        'Music', 'Dance', 'Painting', 'Physical Education', 'Yoga', 'Other'
      ]
    },
  ];
  final allSubjects = subjectGroups.expand((g) => g['subjects'] as List<String>).toList();
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Manage Your Class',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(Icons.class_, color: Theme.of(context).colorScheme.primary, size: 32),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _classNameController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Class Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _sectionController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 2,
                        decoration: InputDecoration(
                          labelText: 'Section',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          counterText: '',
                        ),
                        onChanged: (val) {
                          final upper = val.toUpperCase();
                          if (val != upper) {
                            _sectionController.value = _sectionController.value.copyWith(
                              text: upper,
                              selection: TextSelection.collapsed(offset: upper.length),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownSearch<String>.multiSelection(
                  items: allSubjects,
                  selectedItems: selectedSubjects,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Subjects Taught in This Class',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  popupProps: PopupPropsMultiSelection.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(hintText: 'Search subject...'),
                    ),
                  ),
                  onChanged: (vals) => setState(() => selectedSubjects = vals),
                ),
                const SizedBox(height: 18),
                Text('Assign Teachers to Subjects', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ...selectedSubjects.map((subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(subject, style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: subjectTeacherMap[subject],
                          items: teacherOptions.map((teacher) => DropdownMenuItem<String>(
                            value: teacher['uid'],
                            child: Text(teacher['name'] ?? 'Unknown'),
                          )).toList(),
                          onChanged: (val) => setState(() => subjectTeacherMap[subject] = val),
                          decoration: InputDecoration(
                            labelText: 'Teacher',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 18),
                Text('Add Students (Roll Number & Name)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ...studentList.map((student) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: TextEditingController(text: student['roll'] ?? ''),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Roll',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                          onChanged: (val) => student['roll'] = val,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: student['name'] ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                          onChanged: (val) => student['name'] = val,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => studentList.remove(student)),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 10),
                TextButton.icon(
                  icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                  label: Text('Add Student', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  onPressed: () => setState(() => studentList.add({'roll': '', 'name': ''})),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    onPressed: () {
                      if (_classNameController.text.trim().isEmpty || _sectionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Class name and section are required.')),
                        );
                        return;
                      }
                      onSave(studentList, selectedSubjects, subjectTeacherMap);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
