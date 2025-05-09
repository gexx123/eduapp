import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/principal_dashboard.dart';
import '../join_school_page.dart';
import '../dashboard/parent_dashboard.dart';
import '../principal/create_school_page.dart';
import '../teacher/teacher_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final horizontalPad = isMobile ? 12.0 : 0.0;
    final cardPad = isMobile ? 18.0 : 32.0;
    
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
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              
                              // Attempt to sign in
                              await FirebaseService.auth.signInWithEmailAndPassword(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                              
                              // Close loading dialog
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              
                              // Let the RootPage handle navigation based on auth state
                              // This is key to fixing the persistence issue
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              
                            } catch (e) {
                              // Close loading dialog if it's showing
                              if (context.mounted) {
                                Navigator.of(context, rootNavigator: true).pop();
                              }
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Login failed: $e')),
                                );
                              }
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
