import 'package:flutter/material.dart';

/// Modular, grouped subject picker for class creation and management flows.
/// Accepts subjectGroups, selectedSubjects, and onChanged callback.
class SubjectPicker extends StatelessWidget {
  final List<Map<String, dynamic>> subjectGroups;
  final List<String> selectedSubjects;
  final ValueChanged<List<String>> onChanged;
  final String? label;
  final bool isDense;

  const SubjectPicker({
    Key? key,
    required this.subjectGroups,
    required this.selectedSubjects,
    required this.onChanged,
    this.label,
    this.isDense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(label!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDense ? 14 : 16)),
          ),
        ...subjectGroups.map((group) {
          final groupName = group['group'] as String;
          final subjects = group['subjects'] as List<String>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isDense ? 13 : 15, color: Theme.of(context).colorScheme.primary)),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: subjects.map((subject) {
                    final selected = selectedSubjects.contains(subject);
                    return FilterChip(
                      label: Text(subject, style: TextStyle(fontSize: isDense ? 12 : 14)),
                      selected: selected,
                      onSelected: (val) {
                        final updated = List<String>.from(selectedSubjects);
                        if (val) {
                          if (!updated.contains(subject)) updated.add(subject);
                        } else {
                          updated.remove(subject);
                        }
                        onChanged(updated);
                      },
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
