import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/auth/login_page.dart';
import '../../widgets/navbar/navbar.dart';

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