import 'package:flutter/material.dart';
import 'teacher/teacher_dashboard.dart';
import 'dashboard/parent_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';

class JoinSchoolPage extends StatefulWidget {
  final String role;
  const JoinSchoolPage({super.key, required this.role});

  @override
  State<JoinSchoolPage> createState() => _JoinSchoolPageState();
}

class _JoinSchoolPageState extends State<JoinSchoolPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 0, vertical: isMobile ? 18 : 32),
            child: Container(
              width: isMobile ? double.infinity : 400,
              padding: EdgeInsets.all(isMobile ? 18 : 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Join a School', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 20 : 24)),
                  SizedBox(height: 8),
                  Text(
                    'Enter the school code provided by your school administrator',
                    style: TextStyle(color: Colors.black54, fontSize: isMobile ? 13 : 15),
                  ),
                  SizedBox(height: 22),
                  Text('School Code', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  SizedBox(height: 7),
                  TextField(
                    controller: _codeController,
                    enabled: !_joining,
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit school code',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                      filled: true,
                      fillColor: Color(0xFFF8F7FC),
                      errorText: _error,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                      onPressed: _joining ? null : _onJoin,
                      child: _joining
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Join School'),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'The school code should be provided by your school\'s principal or administrator.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onJoin() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    final code = _codeController.text.trim();
    if (code.length == 6) {
      try {
        // Lookup school info
        final schoolSnap = await FirebaseFirestore.instance
            .collection('schools')
            .where('schoolCode', isEqualTo: code)
            .limit(1)
            .get();
        if (schoolSnap.docs.isEmpty) {
          setState(() {
            _joining = false;
            _error = 'School code not found.';
          });
          return;
        }
        final schoolData = schoolSnap.docs.first.data();
        final schoolName = schoolData['schoolName'] ?? '';
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            _joining = false;
            _error = 'User not authenticated.';
          });
          return;
        }
        final role = widget.role.toLowerCase();
        final name = user.displayName ?? 'User';
        await FirebaseService.addToGroupMember(
          userId: user.uid,
          name: name,
          role: role,
          schoolCode: code,
          schoolName: schoolName,
        );
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'schoolCode': code,
          'schoolName': schoolName,
        }, SetOptions(merge: true));
        // --- AUTO-REDIRECT IF ALREADY JOINED ---
        // Check if teacher already has name and schoolCode in group_member and users
        if (role == 'teacher') {
          final gmDoc = await FirebaseFirestore.instance.collection('group_member')
              .where('userId', isEqualTo: user.uid)
              .limit(1).get();
          final gmData = gmDoc.docs.isNotEmpty ? gmDoc.docs.first.data() : null;
          final hasName = gmData != null && (gmData['name'] ?? '').toString().trim().isNotEmpty;
          final hasSchoolCode = gmData != null && (gmData['schoolCode'] ?? '').toString().trim().isNotEmpty;
          final userSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final userData = userSnap.data() ?? {};
          final userHasSchool = (userData['schoolCode'] ?? '').toString().trim().isNotEmpty;
          if (hasName && hasSchoolCode && userHasSchool) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherDashboardPage(schoolName: schoolName, schoolCode: code),
              ),
            );
            return;
          }
          // Otherwise, continue with normal onboarding flow
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDashboardPage(schoolName: schoolName, schoolCode: code),
            ),
          );
        } else if (role == 'parent') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParentDashboard(),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _joining = false;
          _error = 'Error joining school: $e';
        });
      }
    } else {
      setState(() {
        _joining = false;
        _error = 'Please enter a valid 6-digit code';
      });
    }
  }
}
