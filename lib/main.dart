import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart'; // Corriger l'import pour initializeDateFormatting
import 'package:cloud_firestore/cloud_firestore.dart'; // Import pour Firestore
import 'widgets/navbar/navbar.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialisation de Firebase avec les options spécifiques à la plateforme
    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions
              .currentPlatform, // Vérifie que le fichier firebase_options.dart contient bien les bonnes configurations
    );

    // Configuration du gestionnaire d'email verification
    configureEmailVerificationHandler();

    // Activation de Firebase App Check avec configuration spécifique par plateforme
    FirebaseAppCheck instance = FirebaseAppCheck.instance;
    if (Platform.isIOS || Platform.isMacOS) {
      // Pour iOS et macOS, utiliser le provider DeviceCheck
      await instance.activate(
        appleProvider: AppleProvider.appAttest,
        // En mode debug, vous pouvez utiliser AppleProvider.debug
        // appleProvider: AppleProvider.debug,
      );
    } else {
      // Pour Android et autres plateformes
      await instance.activate();
    }
    instance.setTokenAutoRefreshEnabled(true); // Rafraîchissement automatique activé
    
    // Initialisation des données de formatage de date pour la locale française
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase ou des données de localisation : $e');
  }

  runApp(MyApp());
}

// Gestionnaire de vérification d'email
void configureEmailVerificationHandler() {
  // Ajouter un listener pour les changements d'état d'authentification
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['emailVerificationRequested'] == true && doc.data()?['pendingEmail'] != null) {
          final String pendingEmail = doc.data()?['pendingEmail'];
          
          // Si l'email actuel correspond à celui en attente, cela signifie que la vérification est réussie
          if (user.email == pendingEmail) {
            // Mettre à jour le statut dans Firestore
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'emailVerificationRequested': false,
              'pendingEmail': null,
              'email': pendingEmail,  // Mettre à jour l'email dans Firestore
            });
            
            print("Email mis à jour dans Firestore: ${user.email}");
            
            // Attendre un bref délai pour que les données soient correctement mises à jour
            await Future.delayed(Duration(seconds: 2));
            
            // Déconnecter l'utilisateur après validation réussie de l'email
            await FirebaseAuth.instance.signOut();
            print("Utilisateur déconnecté après validation d'email réussie");
          }
        }
      } catch (e) {
        print("Erreur lors de la vérification des données utilisateur: $e");
      }
    }
  });
  
  // Ajouter également un listener pour détecter les connexions
  FirebaseAuth.instance.userChanges().listen((User? user) async {
    if (user != null && user.emailVerified) {
      try {
        // Actualiser les données utilisateur dans Firestore à chaque connexion réussie
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'email': user.email,  // Synchroniser l'email avec celui de l'authentification
          'emailVerified': true,
        });
      } catch (e) {
        print("Erreur lors de la mise à jour des données utilisateur après connexion: $e");
      }
    }
  });
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
