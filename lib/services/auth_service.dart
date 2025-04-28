import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;
  
  // Stream pour suivre les changements d'état d'authentification
  Stream<User?> authStateChanges() => _auth.authStateChanges();
  
  // Configurer le gestionnaire de vérification d'email
  void configureEmailVerificationHandler() {
    // Ajouter un listener pour les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data()?['emailVerificationRequested'] == true && doc.data()?['pendingEmail'] != null) {
            final String pendingEmail = doc.data()?['pendingEmail'];
            
            // Si l'email actuel correspond à celui en attente, cela signifie que la vérification est réussie
            if (user.email == pendingEmail) {
              // Mettre à jour le statut dans Firestore
              await _firestore.collection('users').doc(user.uid).update({
                'emailVerificationRequested': false,
                'pendingEmail': null,
                'email': pendingEmail,  // Mettre à jour l'email dans Firestore
              });
              
              print("Email mis à jour dans Firestore: ${user.email}");
              
              // Attendre un bref délai pour que les données soient correctement mises à jour
              await Future.delayed(Duration(seconds: 2));
              
              // Déconnecter l'utilisateur après validation réussie de l'email
              await _auth.signOut();
              print("Utilisateur déconnecté après validation d'email réussie");
            }
          }
        } catch (e) {
          print("Erreur lors de la vérification des données utilisateur: $e");
        }
      }
    });
    
    // Ajouter également un listener pour détecter les connexions
    _auth.userChanges().listen((User? user) async {
      if (user != null && user.emailVerified) {
        try {
          // Actualiser les données utilisateur dans Firestore à chaque connexion réussie
          await _firestore.collection('users').doc(user.uid).update({
            'email': user.email,  // Synchroniser l'email avec celui de l'authentification
            'emailVerified': true,
          });
        } catch (e) {
          print("Erreur lors de la mise à jour des données utilisateur après connexion: $e");
        }
      }
    });
  }
  
  // Déconnexion
  Future<void> signOut() async {
    return await _auth.signOut();
  }
  
  // Autres méthodes d'authentification selon les besoins
}