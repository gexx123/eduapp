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
  String? errorText;
  String? sectionErrorText;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
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
                            errorText: errorText,
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
                            errorText: sectionErrorText,
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
                            setState(() => sectionErrorText = null);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: TextStyle(color: Colors.red)),
                  ],
                  if (sectionErrorText != null) ...[
                    const SizedBox(height: 8),
                    Text(sectionErrorText!, style: TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  DropdownSearch<String>.multiSelection(
                    items: [
                      '---Selected Subjects---',
                      ...selectedSubjects,
                      for (var group in subjectGroups) ...[
                        '---${group['group']}---',
                        ...List<String>.from(group['subjects']).where((subject) => !selectedSubjects.contains(subject)),
                      ]
                    ],
                    selectedItems: selectedSubjects,
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Subjects Taught in This Class',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.book_rounded, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    popupProps: PopupPropsMultiSelection.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search subject...',
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      showSelectedItems: true,
                      itemBuilder: (context, item, isSelected) => item.startsWith('---')
                        ? Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              border: Border(
                                bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                              ),
                            ),
                            child: Text(
                              item.replaceAll('-', '').trim(),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListTile(
                            title: Text(item),
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          ),
                      containerBuilder: (context, popupWidget) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: popupWidget,
                      ),
                    ),
                    itemAsString: (item) => item.startsWith('---') ? '' : item,
                    enabled: true,
                    onChanged: (vals) => setState(() => selectedSubjects = vals.where((e) => !e.startsWith('---')).toList()),
                    dropdownBuilder: (context, selectedItems) {
                      final filtered = selectedItems.where((e) => !e.startsWith('---')).toList();
                      return filtered.isEmpty
                        ? Text('')
                        : Text(filtered.join(', '), 
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15),
                          );
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
                        // Validate class name (must be a number)
                        if (_classNameController.text.isEmpty || int.tryParse(_classNameController.text) == null) {
                          setState(() => errorText = 'Please enter a valid class number');
                          return;
                        }

                        // Validate section (must not be empty and must be uppercase)
                        if (_sectionController.text.isEmpty) {
                          setState(() => sectionErrorText = 'Section is required');
                          return;
                        }

                        // Validate subjects (at least one must be selected)
                        if (selectedSubjects.isEmpty) {
                          messenger.showSnackBar(SnackBar(
                            content: Text('Please select at least one subject'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }

                        // Validate students (at least one student with both roll and name)
                        if (students.isEmpty) {
                          messenger.showSnackBar(SnackBar(
                            content: Text('Please add at least one student'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }

                        // Validate each student's roll and name
                        for (var student in students) {
                          if (student['roll'].toString().trim().isEmpty || student['name'].toString().trim().isEmpty) {
                            messenger.showSnackBar(SnackBar(
                              content: Text('Please fill both roll number and name for all students'),
                              backgroundColor: Colors.red,
                            ));
                            return;
                          }
                        }

                        // Check for duplicate class
                        final isDuplicate = await checkDuplicateClass(
                          _classNameController.text,
                          _sectionController.text,
                        );
                        if (isDuplicate) {
                          messenger.showSnackBar(SnackBar(
                            content: Text('This class-section combination already exists'),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }

                        // All validations passed, proceed with class creation
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw Exception("Not signed in");
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          final schoolCode = userDoc.data()?['schoolCode'] as String?;
                          if (schoolCode == null) throw Exception("No schoolCode found for user");
                          print('[CreateClass] Creating SchoolClass in Firestore...');
                          // Use composite document ID (className_section) for each class-section combo
                          final docId = _classNameController.text + '_' + _sectionController.text.toUpperCase();
                          // Fetch teacher name from group_member
                          final gmSnap = await FirebaseFirestore.instance.collection('group_member').doc(user.uid).get();
                          final teacherName = gmSnap.data()?['name'] ?? '';
                          final schoolClass = SchoolClass(
                            className: _classNameController.text,
                            section: _sectionController.text,
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
