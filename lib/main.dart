import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import pour initialiser les données de date localisées
import 'navbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialisation de Firebase avec les options spécifiques à la plateforme
    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions
              .currentPlatform, // Vérifie que le fichier firebase_options.dart contient bien les bonnes configurations
    );

    // Activation de Firebase App Check
    FirebaseAppCheck instance = FirebaseAppCheck.instance;
    await instance.activate();
    instance.setTokenAutoRefreshEnabled(
      true,
    ); // Rafraîchissement automatique activé
    
    // Initialisation des données de formatage de date pour la locale française
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase ou des données de localisation : $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oasis Paris',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Vérifie si un utilisateur est authentifié
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            // Si l'utilisateur est authentifié, redirige vers NavbarPage
            return NavbarPage();
          } else {
            // Sinon, affiche la page de connexion
            return LoginPage(title: 'Oasis Paris');
          }
        }
        // Affiche un indicateur de chargement pendant la vérification de l'état de la connexion
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
