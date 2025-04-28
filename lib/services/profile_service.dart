import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  // Récupérer les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  Future<bool> updateProfile({
    String? nom,
    String? prenom,
    File? imageFile,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{};

      // Ajouter les champs à mettre à jour
      if (nom != null) updates['nom'] = nom;
      if (prenom != null) updates['prenom'] = prenom;

      // Upload de l'image si fournie
      if (imageFile != null) {
        final downloadUrl = await _uploadProfileImage(user.uid, imageFile);
        if (downloadUrl != null) {
          updates['photoUrl'] = downloadUrl;
          // Mettre à jour également l'URL dans Firebase Auth
          await user.updatePhotoURL(downloadUrl);
        }
      }

      // Mise à jour Firestore
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      return false;
    }
  }

  // Upload d'une image de profil
  Future<String?> _uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Erreur lors de l\'upload de l\'image: $e');
      return null;
    }
  }

  // Changer l'adresse email
  Future<Map<String, dynamic>> changeEmail({
    required String password,
    required String newEmail,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Utilisateur non connecté'};
      }

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Vérifier si l'email est déjà utilisé
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(newEmail);
      if (methods.isNotEmpty) {
        return {'success': false, 'message': 'Cette adresse email est déjà utilisée'};
      }

      // Mettre à jour dans Firestore en tant que pendingEmail
      await _firestore.collection('users').doc(user.uid).update({
        'pendingEmail': newEmail,
      });

      // Envoyer l'email de vérification
      await user.verifyBeforeUpdateEmail(newEmail);

      return {
        'success': true,
        'message': 'Email de vérification envoyé',
        'newEmail': newEmail
      };
    } catch (e) {
      String message;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            message = 'Le mot de passe est incorrect';
            break;
          case 'too-many-requests':
            message = 'Trop de tentatives, veuillez réessayer plus tard';
            break;
          case 'invalid-credential':
            message = 'Les identifiants sont invalides';
            break;
          default:
            message = 'Une erreur est survenue: ${e.code}';
        }
      } else {
        message = 'Une erreur est survenue: $e';
      }
      return {'success': false, 'message': message};
    }
  }

  // Renvoyer l'email de vérification
  Future<bool> resendEmailVerification(String email) async {
    try {
      final user = currentUser;
      if (user == null) return false;
      await user.verifyBeforeUpdateEmail(email);
      return true;
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email de vérification: $e');
      return false;
    }
  }

  // Changer le numéro de téléphone
  Future<bool> changePhoneNumber({
    required String password,
    required String newPhone,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Mettre à jour dans Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'telephone': newPhone,
      });

      return true;
    } catch (e) {
      print('Erreur lors du changement de téléphone: $e');
      return false;
    }
  }

  // Changer le mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Utilisateur non connecté'};
      }

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Mettre à jour le mot de passe
      await user.updatePassword(newPassword);

      return {'success': true};
    } catch (e) {
      String message;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            message = 'Le mot de passe actuel est incorrect';
            break;
          case 'weak-password':
            message = 'Le nouveau mot de passe est trop faible';
            break;
          case 'too-many-requests':
            message = 'Trop de tentatives, veuillez réessayer plus tard';
            break;
          default:
            message = 'Une erreur est survenue: ${e.code}';
        }
      } else {
        message = 'Une erreur est survenue: $e';
      }
      return {'success': false, 'message': message};
    }
  }

  // Supprimer le compte utilisateur
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Utilisateur non connecté'};
      }

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Référence au document utilisateur
      final userDocRef = _firestore.collection('users').doc(user.uid);
      
      // Obtenir les données utilisateur avant la suppression
      final userData = await userDocRef.get();
      
      // Supprimer le document utilisateur
      await userDocRef.delete();
      
      // Supprimer l'image de profil si elle existe
      if (userData.exists && userData.data()!['photoUrl'] != null) {
        try {
          await _storage.ref().child('profile_images').child('${user.uid}.jpg').delete();
        } catch (e) {
          print('Erreur lors de la suppression de l\'image: $e');
        }
      }
      
      // Supprimer l'utilisateur dans Firebase Auth
      await user.delete();
      
      return {'success': true};
    } catch (e) {
      String message;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            message = 'Le mot de passe est incorrect';
            break;
          case 'too-many-requests':
            message = 'Trop de tentatives, veuillez réessayer plus tard';
            break;
          case 'requires-recent-login':
            message = 'Cette action nécessite une connexion récente, veuillez vous reconnecter';
            break;
          default:
            message = 'Une erreur est survenue: ${e.code}';
        }
      } else {
        message = 'Une erreur est survenue: $e';
      }
      return {'success': false, 'message': message};
    }
  }

  // Déconnexion
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      return false;
    }
  }
}