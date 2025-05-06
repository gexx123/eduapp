import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'landing_page.dart';
// import 'auth/login_page.dart';
// import 'services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'root_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Persist auth state on web
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }
  runApp(const ProviderScope(child: EduFlowApp()));
}

class EduFlowApp extends StatelessWidget {
  const EduFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RootPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
