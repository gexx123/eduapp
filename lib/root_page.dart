import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_page.dart';
import 'auth/login_page.dart';
import 'dashboard/principal_dashboard.dart';
import 'dashboard/parent_dashboard.dart';
import 'teacher/teacher_dashboard.dart';
import 'services/firebase_service.dart';

class RootPage extends StatefulWidget {
  final SharedPreferences prefs;
  
  const RootPage({super.key, required this.prefs});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // Auth persistence keys
  static const String _authUserIdKey = 'auth_user_id';
  static const String _authUserRoleKey = 'auth_user_role';
  static const String _authSchoolCodeKey = 'auth_school_code';
  static const String _authSchoolNameKey = 'auth_school_name';
  
  // Flag to track if we're restoring from cached auth
  bool _isRestoringAuth = false;

  // Fetch all needed info for routing
  Future<Map<String, dynamic>?> _getUserMeta(String uid) async {
    try {
      final groupSnap = await FirebaseFirestore.instance
          .collection('group_member')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      if (groupSnap.docs.isNotEmpty) {
        final data = groupSnap.docs.first.data();
        final meta = {
          'role': data['role'],
          'schoolCode': data['schoolCode'] ?? '',
          'schoolName': data['schoolName'] ?? '',
        };
        
        // Save to SharedPreferences for persistence
        await _saveUserMetaToPrefs(uid, meta);
        
        return meta;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user meta: $e');
      return null;
    }
  }
  
  // Save user metadata to SharedPreferences
  Future<void> _saveUserMetaToPrefs(String uid, Map<String, dynamic> meta) async {
    await widget.prefs.setString(_authUserIdKey, uid);
    await widget.prefs.setString(_authUserRoleKey, meta['role'] ?? '');
    await widget.prefs.setString(_authSchoolCodeKey, meta['schoolCode'] ?? '');
    await widget.prefs.setString(_authSchoolNameKey, meta['schoolName'] ?? '');
  }
  
  // Clear auth data from SharedPreferences
  Future<void> _clearAuthFromPrefs() async {
    await widget.prefs.remove(_authUserIdKey);
    await widget.prefs.remove(_authUserRoleKey);
    await widget.prefs.remove(_authSchoolCodeKey);
    await widget.prefs.remove(_authSchoolNameKey);
  }
  
  // Try to restore auth from SharedPreferences
  Future<bool> _tryRestoreAuthFromPrefs() async {
    final cachedUid = widget.prefs.getString(_authUserIdKey);
    final cachedRole = widget.prefs.getString(_authUserRoleKey);
    final cachedSchoolCode = widget.prefs.getString(_authSchoolCodeKey);
    final cachedSchoolName = widget.prefs.getString(_authSchoolNameKey);
    
    // Check if we have all required data
    if (cachedUid != null && cachedUid.isNotEmpty && 
        cachedRole != null && cachedRole.isNotEmpty &&
        cachedSchoolCode != null && cachedSchoolCode.isNotEmpty &&
        cachedSchoolName != null && cachedSchoolName.isNotEmpty) {
      
      // Verify if the current Firebase user matches our cached UID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != cachedUid) {
        // If there's a mismatch, clear the prefs and return false
        await _clearAuthFromPrefs();
        return false;
      }
      
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    // Check if we need to restore auth state
    _tryRestoreAuthFromPrefs().then((success) {
      if (success) {
        setState(() {
          _isRestoringAuth = true;
        });
      }
    });
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
          
          // If we're restoring from cache, use the cached data directly
          if (_isRestoringAuth) {
            final cachedRole = widget.prefs.getString(_authUserRoleKey) ?? '';
            final cachedSchoolCode = widget.prefs.getString(_authSchoolCodeKey) ?? '';
            final cachedSchoolName = widget.prefs.getString(_authSchoolNameKey) ?? '';
            
            // Reset the flag
            _isRestoringAuth = false;
            
            // Route based on cached data
            if (cachedRole == 'principal') {
              return PrincipalDashboardPage(
                schoolName: cachedSchoolName,
                schoolCode: cachedSchoolCode,
              );
            } else if (cachedRole == 'teacher') {
              return TeacherDashboardPage(
                schoolName: cachedSchoolName,
                schoolCode: cachedSchoolCode,
              );
            } else if (cachedRole == 'parent') {
              return ParentDashboard(
                schoolName: cachedSchoolName,
                schoolCode: cachedSchoolCode,
              );
            }
          }
          
          // Otherwise, fetch from Firestore as usual
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
        // Not signed in - clear any cached auth data
        _clearAuthFromPrefs();
        return LandingPage();
      },
    );
  }
}
