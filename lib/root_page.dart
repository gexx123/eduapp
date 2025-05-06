import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'landing_page.dart';
import 'auth/login_page.dart';
import 'dashboard/principal_dashboard.dart';
import 'dashboard/parent_dashboard.dart';
import 'teacher/teacher_dashboard.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  // Fetch all needed info for routing
  Future<Map<String, dynamic>?> _getUserMeta(String uid) async {
    final groupSnap = await FirebaseFirestore.instance
        .collection('group_member')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();
    if (groupSnap.docs.isNotEmpty) {
      final data = groupSnap.docs.first.data();
      return {
        'role': data['role'],
        'schoolCode': data['schoolCode'] ?? '',
        'schoolName': data['schoolName'] ?? '',
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserMeta(user.uid),
            builder: (context, metaSnap) {
              if (metaSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final meta = metaSnap.data;
              if (meta == null || meta['role'] == null || meta['schoolCode'] == '') {
                // If user is not fully set up, show login or an error page
                return LoginPage();
              }
              final role = meta['role'];
              if (role == 'principal') {
                return PrincipalDashboardPage(
                  schoolName: meta['schoolName'],
                  schoolCode: meta['schoolCode'],
                );
              } else if (role == 'teacher') {
                return TeacherDashboardPage(
                  schoolName: meta['schoolName'],
                  schoolCode: meta['schoolCode'],
                );
              } else if (role == 'parent') {
                return ParentDashboard(
                  schoolName: meta['schoolName'],
                  schoolCode: meta['schoolCode'],
                );
              } else {
                return LoginPage();
              }
            },
          );
        }
        // Not signed in
        return LandingPage();
      },
    );
  }
}
