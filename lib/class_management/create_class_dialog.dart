import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eduflow_flutter/services/firestore_service.dart';
import 'package:eduflow_flutter/models/class.dart';
import 'package:eduflow_flutter/models/student.dart';

/// Create Class Dialog
/// Usage: showCreateClassDialog(context: context, ...);
Future<void> showCreateClassDialog({
  required BuildContext context,
  required Function(String, String, List<String>, List<Map<String, dynamic>>) onSave,
}) async {
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  List<String> selectedSubjects = [];
  List<Map<String, dynamic>> students = [];
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
  String? schoolCode;
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    schoolCode = userDoc.data()?['schoolCode'] as String?;
  }
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        String? errorText;
        bool loading = false;
        final messenger = ScaffoldMessenger.of(context);
        // Use composite document ID (className_section) for each class-section combo
        Future<bool> checkDuplicateClass(String className, String section) async {
          if (schoolCode == null) return false;
          final docId = className + '_' + section.toUpperCase();
          final doc = await FirebaseFirestore.instance
            .collection('school_classes')
            .doc(schoolCode)
            .collection('classesData')
            .doc(docId)
            .get();
          return doc.exists;
        }
        return Dialog(
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
                      Text('Create Your Class',
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
                        flex: 2,
                        child: TextField(
                          controller: _classNameController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Class Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && int.tryParse(val) == null) {
                              setState(() => errorText = 'Class name must be a number');
                            } else {
                              setState(() => errorText = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
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
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  DropdownSearch<String>.multiSelection(
                    items: [
                      for (var group in subjectGroups) ...[
                        '--- ${group['group']} ---',
                        ...List<String>.from(group['subjects'])
                      ]
                    ],
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
                    itemAsString: (item) => item.startsWith('---') ? item : '   $item',
                    enabled: true,
                    onChanged: (vals) => setState(() => selectedSubjects = vals.where((e) => !e.startsWith('---')).toList()),
                    dropdownBuilder: (context, selectedItems) {
                      final filtered = selectedItems.where((e) => !e.startsWith('---')).toList();
                      return Text(filtered.isEmpty ? '' : filtered.join(', '));
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Add Students (Roll Number & Name)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...students.map((student) => Padding(
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
                          onPressed: () => setState(() => students.remove(student)),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                    label: Text('Add Student', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    onPressed: () => setState(() => students.add({'roll': '', 'name': ''})),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: loading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                      label: Text(loading ? 'Creating...' : 'Create Class'),
                      onPressed: loading ? null : () async {
                        print('[CreateClass] Attempting to create class: className=${_classNameController.text.trim()}, section=${_sectionController.text.trim()}, subjects=$selectedSubjects, students=$students');
                        final className = _classNameController.text.trim();
                        final section = _sectionController.text.trim();
                        if (className.isEmpty) {
                          messenger.showSnackBar(SnackBar(content: Text('Class name is required')));
                          print('[CreateClass][Validation] Class name empty');
                          return;
                        }
                        if (int.tryParse(className) == null) {
                          messenger.showSnackBar(SnackBar(content: Text('Class name must be a number')));
                          print('[CreateClass][Validation] Class name not numeric');
                          return;
                        }
                        if (section.isEmpty) {
                          messenger.showSnackBar(SnackBar(content: Text('Section is required')));
                          print('[CreateClass][Validation] Section empty');
                          return;
                        }
                        if (selectedSubjects.isEmpty) {
                          messenger.showSnackBar(SnackBar(content: Text('Please select at least one subject')));
                          print('[CreateClass][Validation] No subjects selected');
                          return;
                        }
                        setState(() { errorText = null; loading = true; });
                        print('[CreateClass] Passed validation, checking for duplicates...');
                        final duplicate = await checkDuplicateClass(className, section);
                        if (duplicate) {
                          messenger.showSnackBar(SnackBar(content: Text('A class with this name and section already exists.')));
                          print('[CreateClass][Validation] Duplicate class found');
                          setState(() { loading = false; });
                          return;
                        }
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw Exception("Not signed in");
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          final schoolCode = userDoc.data()?['schoolCode'] as String?;
                          if (schoolCode == null) throw Exception("No schoolCode found for user");
                          print('[CreateClass] Creating SchoolClass in Firestore...');
                          // Use composite document ID (className_section) for each class-section combo
                          final docId = className + '_' + section.toUpperCase();
                          // Fetch teacher name from group_member
                          final gmSnap = await FirebaseFirestore.instance.collection('group_member').doc(user.uid).get();
                          final teacherName = gmSnap.data()?['name'] ?? '';
                          final schoolClass = SchoolClass(
                            className: className,
                            section: section,
                            subjects: selectedSubjects,
                            students: students,
                            subjectTeachers: null, // or build as needed
                          );
                          await FirestoreService().saveClassWithCreator(schoolCode, schoolClass, user.uid, teacherName, docId: docId);
                          bool studentsSaved = true;
                          try {
                            final studentObjs = students.map((e) => Student.fromMap(e)).toList();
                            await FirestoreService().saveStudents(schoolCode, docId, studentObjs);
                          } catch (e) {
                            studentsSaved = false;
                            messenger.showSnackBar(SnackBar(content: Text('Class created, but failed to save students: $e')));
                            print('[CreateClass][Warning] Students not saved: $e');
                          }
                          await FirestoreService().setUserClassCreated(user.uid, true);
                          if (studentsSaved) {
                            messenger.showSnackBar(SnackBar(content: Text('Class created successfully!')));
                          }
                          Navigator.of(context).pop();
                        } catch (e, stack) {
                          print('[CreateClass][Error] $e\n$stack');
                          messenger.showSnackBar(SnackBar(content: Text('Failed to create class: $e')));
                          setState(() { loading = false; });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
