import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailPage extends StatefulWidget {
  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  @override
  void initState() {
    super.initState();
    // Vérifier si l'utilisateur a cliqué sur le lien avec un code de vérification dans l'URL
    checkEmailVerification();
  }

  Future<void> checkEmailVerification() async {
    final Uri? uri = Uri.tryParse('https://oasis-paris.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=<code>'); // Remplace <code> par le code réel
    final oobCode = uri?.queryParameters['oobCode']; // Extraire le code (oobCode) de l'URL

    if (oobCode != null) {
      // Si un oobCode est présent, traite-le
      await handleVerificationLink(oobCode);
    } else {
      // Si aucun code n'est présent, afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lien de vérification invalide')));
    }
  }

  Future<void> handleVerificationLink(String oobCode) async {
    try {
      // Vérifier que le code est valide
      await FirebaseAuth.instance.checkActionCode(oobCode);  
      // Appliquer la vérification de l'email
      await FirebaseAuth.instance.applyActionCode(oobCode);  

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Votre email a été vérifié avec succès!')));
      
      // Rediriger l'utilisateur vers la page de connexion ou autre
      Navigator.pushReplacementNamed(context, '/login');  // Remplace '/login' par ton écran de connexion
    } catch (e) {
      // Si une erreur survient
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la vérification: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vérification Email'),
      ),
      body: Center(
        child: CircularProgressIndicator(), // Affiche un indicateur de chargement pendant le traitement
      ),
    );
  }
}
