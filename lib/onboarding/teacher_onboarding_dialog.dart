import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:eduflow_flutter/class_management/create_class_dialog.dart';

/// Teacher Onboarding Dialog/BottomSheet
/// Usage: showTeacherOnboardingDialog(context: context, ...);
class TeacherOnboardingBottomSheet extends StatefulWidget {
  final String schoolCode;
  final String? groupMemberDocId;
  const TeacherOnboardingBottomSheet({
    Key? key,
    required this.schoolCode,
    this.groupMemberDocId,
  }) : super(key: key);

  @override
  State<TeacherOnboardingBottomSheet> createState() => _TeacherOnboardingBottomSheetState();
}

class _TeacherOnboardingBottomSheetState extends State<TeacherOnboardingBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  String? selectedSubject;
  bool? isClassTeacher;
  bool _saving = false;

  // Grouped subject list for dropdowns
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

  @override
  void initState() {
    super.initState();
    _prefillName();
  }

  Future<void> _prefillName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final gmDoc = await FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
    if (gmDoc.docs.isNotEmpty) {
      final data = gmDoc.docs.first.data();
      if (data['name'] != null) {
        final rawName = data['name'].toString().trim();
        _nameController.text = (rawName.isEmpty || rawName == 'User') ? '' : rawName;
      }
      if (data['subject'] != null) selectedSubject = data['subject'];
      if (data['isClassTeacher'] != null) isClassTeacher = data['isClassTeacher'] == true;
      setState(() {});
    }
  }

  Future<void> _onProceed() async {
    if (_nameController.text.trim().isEmpty || selectedSubject == null || isClassTeacher == null) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final groupMemberRef = widget.groupMemberDocId != null
        ? FirebaseFirestore.instance.collection('group_member').doc(widget.groupMemberDocId)
        : FirebaseFirestore.instance.collection('group_member').where('userId', isEqualTo: uid).limit(1);
    // --- Ensure onboarded:true is set IMMEDIATELY after onboarding ---
    if (widget.groupMemberDocId != null) {
      await (groupMemberRef as DocumentReference).set({
        'name': _nameController.text.trim(),
        'subject': selectedSubject,
        'isClassTeacher': isClassTeacher,
        'onboarded': true,
      }, SetOptions(merge: true));
    } else {
      final docs = await (groupMemberRef as Query).get();
      if (docs.docs.isNotEmpty) {
        await docs.docs.first.reference.set({
          'name': _nameController.text.trim(),
          'subject': selectedSubject,
          'isClassTeacher': isClassTeacher,
          'onboarded': true,
        }, SetOptions(merge: true));
      }
    }
    // --- Await onboarded:true before proceeding to class creation dialog ---
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'isClassCreated': false, // will be true after class creation
    }, SetOptions(merge: true));
    setState(() => _saving = false);
    if (isClassTeacher == true) {
      // Show create class dialog immediately after onboarding
      await showCreateClassDialog(
        context: context,
        onSave: (className, section, subjects, students) async {
          // After class creation, update Firestore to mark as created
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'isClassCreated': true,
          }, SetOptions(merge: true));
          if (widget.groupMemberDocId != null) {
            await FirebaseFirestore.instance.collection('group_member')
              .doc(widget.groupMemberDocId)
              .set({'classCreated': true}, SetOptions(merge: true));
          }
        },
      );
    }
    // Only pop after all writes
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allSubjects = subjectGroups.expand((g) => g['subjects'] as List<String>).toList();
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Teacher Onboarding',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(Icons.school, color: Theme.of(context).colorScheme.primary, size: 32),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownSearch<String>(
                  items: allSubjects,
                  selectedItem: selectedSubject,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Subject You Teach',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(hintText: 'Search subject...'),
                    ),
                  ),
                  onChanged: (val) => setState(() => selectedSubject = val),
                ),
                const SizedBox(height: 16),
                Text('Are you a class teacher?', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Yes'),
                      selected: isClassTeacher == true,
                      onSelected: (v) => setState(() => isClassTeacher = true),
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isClassTeacher == true ? Theme.of(context).colorScheme.primary : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    ChoiceChip(
                      label: const Text('No'),
                      selected: isClassTeacher == false,
                      onSelected: (v) => setState(() => isClassTeacher = false),
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isClassTeacher == false ? Theme.of(context).colorScheme.primary : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                    icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward),
                    label: Text(_saving ? 'Saving...' : 'Proceed'),
                    onPressed: _saving ? null : _onProceed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
