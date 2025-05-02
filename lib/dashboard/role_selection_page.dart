import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import 'principal_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';
import '../join_school_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _saveRoleAndRedirect(BuildContext context, String role) async {
    final user = FirebaseService.auth.currentUser;
    if (user != null) {
      await FirestoreService().saveUserRole(user.uid, role, user.email);
      if (role == 'Principal') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PrincipalDashboard()),
        );
      } else if (role == 'Teacher' || role == 'Parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => JoinSchoolPage(role: role)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Choose your role:', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _saveRoleAndRedirect(context, 'Principal'),
                child: const Text('Principal'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _saveRoleAndRedirect(context, 'Teacher'),
                child: const Text('Teacher'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _saveRoleAndRedirect(context, 'Parent'),
                child: const Text('Parent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
