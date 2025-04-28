import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour observer les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inscription avec email et mot de passe
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    String? telephone,
  }) async {
    try {
      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Créer le document utilisateur dans Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Mettre à jour le displayName dans Firebase Auth
        await userCredential.user!.updateDisplayName('$prenom $nom');
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour la date de dernière connexion
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Envoi d'email de vérification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? userData,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Mettre à jour dans Firebase Auth
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Mettre à jour dans Firestore
      if (userData != null) {
        await _firestore.collection('users').doc(user.uid).update(userData);
      }

      // Recharger l'utilisateur pour obtenir les données les plus récentes
      await user.reload();
    }
  }

  // Changer l'email de l'utilisateur
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Réauthentifier l'utilisateur avant de changer l'email
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // Mettre à jour l'email dans Firebase Auth
        await user.verifyBeforeUpdateEmail(newEmail);

        // Mettre à jour l'email dans Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'pendingEmail': newEmail,
          'emailVerificationRequested': true,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Changer le mot de passe de l'utilisateur
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Réauthentifier l'utilisateur avant de changer le mot de passe
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // Mettre à jour le mot de passe
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer le compte utilisateur
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Réauthentifier l'utilisateur avant de supprimer le compte
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);

        // Supprimer les données utilisateur de Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Supprimer le compte
        await user.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Vérifier si le mot de passe est correct (utile pour validation)
  Future<bool> verifyPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Obtenir les données utilisateur de Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }
}