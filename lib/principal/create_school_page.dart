import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/principal_dashboard.dart';
import '../services/firebase_service.dart';

class CreateSchoolPage extends StatefulWidget {
  const CreateSchoolPage({super.key});

  @override
  State<CreateSchoolPage> createState() => _CreateSchoolPageState();
}

class _CreateSchoolPageState extends State<CreateSchoolPage> {
  final TextEditingController _schoolNameController = TextEditingController();
  bool _creating = false;

  // Helper to get current principal UID
  String? get _principalUid => FirebaseAuth.instance.currentUser?.uid;

  Future<String> _generateUniqueSchoolCode() async {
    final firestore = FirebaseFirestore.instance;
    String code;
    bool exists = true;
    do {
      code = _generateSchoolCode();
      final query = await firestore.collection('schools').where('schoolCode', isEqualTo: code).limit(1).get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return code;
  }

  Future<void> _createSchoolAndUpdatePrincipal() async {
    setState(() { _creating = true; });
    try {
      final schoolName = _schoolNameController.text.trim();
      if (schoolName.isEmpty) return;
      final schoolCode = await _generateUniqueSchoolCode();
      final firestore = FirebaseFirestore.instance;
      // 1. Create school doc
      await firestore.collection('schools').add({
        'schoolCode': schoolCode,
        'schoolName': schoolName,
        'createdBy': _principalUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // 2. Update principal's user doc (if UID available)
      if (_principalUid != null) {
        await firestore.collection('users').doc(_principalUid).set({
          'schoolCode': schoolCode,
          'schoolName': schoolName,
        }, SetOptions(merge: true));
        // 3. Add to group_member collection
        await FirebaseService.addToGroupMember(
          userId: _principalUid!,
          name: schoolName, // You may want to use principal's name if available
          role: 'principal',
          schoolCode: schoolCode,
          schoolName: schoolName,
        );
        // 4. Create school_classes collection/document
        await _createSchoolClassesCollection(schoolCode, '2022-2023', _principalUid!);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrincipalDashboardPage(
            schoolName: schoolName,
            schoolCode: schoolCode,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating school: $e')),
      );
    } finally {
      setState(() { _creating = false; });
    }
  }

  Future<void> _createSchoolClassesCollection(String schoolCode, String academicYear, String principalUid) async {
    final docRef = FirebaseFirestore.instance.collection('school_classes').doc(schoolCode);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'schoolCode': schoolCode,
        'academicYear': academicYear,
        'createdBy': principalUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final cardPad = isMobile ? 18.0 : 32.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 0, vertical: isMobile ? 18 : 32),
            child: Container(
              width: isMobile ? double.infinity : 400,
              padding: EdgeInsets.all(cardPad),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create Your School',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 20 : 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Set up your educational institution on EduLink',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 22),
                  Text('School Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 15)),
                  SizedBox(height: 6),
                  TextField(
                    controller: _schoolNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter the name of your school',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      filled: true,
                      fillColor: Color(0xFFF8F7FC),
                    ),
                    onChanged: (_) => setState(() {}),
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
                      onPressed: _creating || _schoolNameController.text.trim().isEmpty ? null : _createSchoolAndUpdatePrincipal,
                      child: _creating ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create School'),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'A unique school code will be generated for you to share with teachers and parents.',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13.5,
                      color: Colors.black54,
                    ),
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

  String _generateSchoolCode() {
    // Generate a unique 6-char code using time and randomness
    final rand = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String randomPart = List.generate(3, (i) => chars[rand.nextInt(chars.length)]).join();
    String timePart = (timestamp % 1000000).toString().padLeft(6, '0');
    return randomPart + timePart.substring(0,3);
  }
}

// --- PrincipalDashboardPage has been moved to dashboard/principal_dashboard.dart ---
