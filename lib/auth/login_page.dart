import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/principal_dashboard.dart';
import '../join_school_page.dart';
import '../dashboard/parent_dashboard.dart';
import '../principal/create_school_page.dart';
import '../teacher/teacher_dashboard.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final horizontalPad = isMobile ? 12.0 : 0.0;
    final cardPad = isMobile ? 18.0 : 32.0;
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: isMobile ? 18 : 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EduLink',
                  style: TextStyle(
                    color: Color(0xFFBBAAFE),
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 30 : 36,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Smart Educational Platform',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: isMobile ? 18 : 28),
                Container(
                  padding: EdgeInsets.all(cardPad),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1.2),
                  ),
                  width: isMobile ? double.infinity : 370,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 20 : 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sign in to your EduLink account',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 18),
                      Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15)),
                      SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF8F7FC),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15)),
                      SizedBox(height: 6),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF8F7FC),
                        ),
                      ),
                      SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBBAAFE),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            textStyle: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            try {
                              final userCredential = await FirebaseService.auth.signInWithEmailAndPassword(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                              if (userCredential.user != null) {
                                // Fetch user role from Firestore
                                final userDoc = await FirebaseService.firestore
                                    .collection('users')
                                    .doc(userCredential.user!.uid)
                                    .get();
                                final data = userDoc.data();
                                if (data != null && data['role'] != null) {
                                  final role = data['role'];
                                  if (role == 'principal') {
                                    // If principal has schoolCode, route to dashboard, else to CreateSchoolPage
                                    final schoolCode = data['schoolCode'];
                                    final schoolName = data['schoolName'];
                                    if (schoolCode != null && schoolName != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PrincipalDashboardPage(
                                            schoolName: schoolName,
                                            schoolCode: schoolCode,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CreateSchoolPage(),
                                        ),
                                      );
                                    }
                                  } else if (role == 'teacher') {
                                    // --- FIX: Check if teacher already has schoolCode and name ---
                                    final uid = userCredential.user!.uid;
                                    final userSnap = await FirebaseService.firestore.collection('users').doc(uid).get();
                                    final userData = userSnap.data() ?? {};
                                    final schoolCode = userData['schoolCode'];
                                    final schoolName = userData['schoolName'];
                                    final gmDoc = await FirebaseService.firestore.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
                                    final gmData = gmDoc.docs.isNotEmpty ? gmDoc.docs.first.data() : null;
                                    final hasName = gmData != null && (gmData['name'] ?? '').toString().trim().isNotEmpty;
                                    final hasSchoolCode = gmData != null && (gmData['schoolCode'] ?? '').toString().trim().isNotEmpty;
                                    final userHasSchool = (schoolCode ?? '').toString().trim().isNotEmpty;
                                    if (hasName && hasSchoolCode && userHasSchool && schoolName != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TeacherDashboardPage(schoolName: schoolName, schoolCode: schoolCode),
                                        ),
                                      );
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => JoinSchoolPage(role: 'teacher'),
                                        ),
                                      );
                                    }
                                  } else if (role == 'parent') {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ParentDashboard(),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Unknown role: $role')),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('User role not set. Please complete registration.')),
                                  );
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Login failed: $e')),
                              );
                            }
                          },
                          child: const Text('Sign In'),
                        ),
                      ),
                      SizedBox(height: 14),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(fontSize: isMobile ? 13 : 15)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignupPage()),
                                );
                              },
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Color(0xFFBBAAFE),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 13 : 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
