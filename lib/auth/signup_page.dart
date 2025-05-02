import 'package:flutter/material.dart';
import 'login_page.dart';
import '../role_selection_page.dart';
import '../services/firebase_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    if (password != confirmPassword) {
      setState(() {
        isLoading = false;
        errorMessage = 'Passwords do not match';
      });
      return;
    }
    try {
      final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user?.uid;
      if (uid != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionPage(uid: uid, email: email),
          ),
        );
      } else {
        setState(() {
          errorMessage = 'Failed to retrieve user ID.';
        });
      }
    } on Exception catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 20 : 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Join EduLink and enhance your educational experience',
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
                          hintText: 'Create a password',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF8F7FC),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15)),
                      SizedBox(height: 6),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Confirm your password',
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF8F7FC),
                        ),
                      ),
                      SizedBox(height: 22),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
                          onPressed: isLoading ? null : _signUp,
                          child: isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Sign Up'),
                        ),
                      ),
                      SizedBox(height: 14),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text("Already have an account? ", style: TextStyle(fontSize: isMobile ? 13 : 15)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                );
                              },
                              child: Text(
                                'Sign in',
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
