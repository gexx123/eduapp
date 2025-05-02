import 'package:flutter/material.dart';
import 'principal/create_school_page.dart';
import 'join_school_page.dart'; // Import the JoinSchoolPage
import 'services/firebase_service.dart';
import 'services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelectionPage extends StatefulWidget {
  final String uid;
  final String email;
  const RoleSelectionPage({super.key, required this.uid, required this.email});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  int? selectedIndex;
  bool isLoading = false;
  String? errorMessage;

  // Card data for beautiful role selection UI
  final List<_RoleCardData> roleCards = [
    _RoleCardData(
      title: 'Principal',
      subtitle: 'School administrator with full access',
      icon: Icons.school,
      color: Color(0xFF5B8DEE),
      highlightColor: Color(0xFFE9F2FC),
      role: 'principal',
    ),
    _RoleCardData(
      title: 'Teacher',
      subtitle: 'Create and manage classes and assessments',
      icon: Icons.school_outlined,
      color: Color(0xFFFFA726),
      highlightColor: Color(0xFFFFF6E9),
      role: 'teacher',
    ),
    _RoleCardData(
      title: 'Parent',
      subtitle: 'View student performance and updates',
      icon: Icons.family_restroom,
      color: Color(0xFFAA5BDE),
      highlightColor: Color(0xFFF7E9FC),
      role: 'parent',
    ),
    _RoleCardData(
      title: 'Student',
      subtitle: 'Access your classes and assessments',
      icon: Icons.person,
      color: Color(0xFF5B8DEE),
      highlightColor: Color(0xFFE9F2FC),
      role: 'student',
    ),
  ];

  void _onCardTap(int index) {
    setState(() {
      selectedIndex = index;
      errorMessage = null;
    });
  }

  Future<void> _onContinue() async {
    if (selectedIndex == null) return;
    final selectedRole = roleCards[selectedIndex!].role;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await FirestoreService().saveUserRole(widget.uid, selectedRole, widget.email);
      if (selectedRole == 'principal') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CreateSchoolPage()),
        );
      } else if (selectedRole == 'teacher' || selectedRole == 'parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => JoinSchoolPage(role: selectedRole)),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
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
    final cardPad = isMobile ? 16.0 : 28.0;
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
                    'Select Your Role',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 20 : 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Choose your role in the educational system',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 18),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ...List.generate(roleCards.length, (i) {
                    final card = roleCards[i];
                    final selected = selectedIndex == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isLoading ? null : () => _onCardTap(i),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: selected ? card.highlightColor : Colors.white,
                            border: Border.all(
                              color: selected ? card.color : Colors.grey.shade200,
                              width: selected ? 2.0 : 1.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(card.icon, color: card.color, size: 32),
                              SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: card.color,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      card.subtitle,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedIndex == null ? Color(0xFFEAE6F7) : Color(0xFFBBAAFE),
                        foregroundColor: selectedIndex == null ? Colors.black38 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        textStyle: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: isLoading || selectedIndex == null ? null : _onContinue,
                      child: isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color highlightColor;
  final String role;
  const _RoleCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.highlightColor,
    required this.role,
  });
}
