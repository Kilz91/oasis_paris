import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import nécessaire

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Désactiver temporairement App Check
    FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase : $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oasis Paris',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(title: 'Oasis Paris'),
    );
  }
}