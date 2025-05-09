import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'landing_page.dart';
// import 'auth/login_page.dart';
import 'services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'root_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Configure Firebase persistence based on platform
  if (kIsWeb) {
    // For web, explicitly set persistence to LOCAL
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  
  // Initialize shared preferences for additional auth state persistence
  final prefs = await SharedPreferences.getInstance();
  
  runApp(ProviderScope(child: EduFlowApp(prefs: prefs)));
}

class EduFlowApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const EduFlowApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: RootPage(prefs: prefs),
      debugShowCheckedModeBanner: false,
    );
  }
}
