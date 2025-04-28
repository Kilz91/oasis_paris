import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase et les services associés
  await FirebaseService.initialize();
  
  // Lancer l'application
  runApp(MyApp());
}
