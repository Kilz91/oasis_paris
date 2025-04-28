import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection de référence
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // Obtenir un utilisateur par son ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur : $e');
      return null;
    }
  }

  // Obtenir l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return getUserById(user.uid);
    }
    return null;
  }

  // Mettre à jour les données utilisateur
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      print('Erreur lors de la mise à jour des données utilisateur : $e');
    }
  }

  // Créer un nouvel utilisateur dans Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur : $e');
    }
  }

  // Écouter les changements sur un utilisateur
  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    });
  }

  // Récupérer les amis d'un utilisateur
  Future<List<UserModel>> getUserFriends(String uid) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(uid).get();
      List<String> friendIds = [];
      
      if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
        var userData = userDoc.data() as Map<String, dynamic>;
        if (userData['friends'] != null && userData['friends'] is List) {
          friendIds = List<String>.from(userData['friends']);
        }
      }

      List<UserModel> friends = [];
      for (var friendId in friendIds) {
        UserModel? friend = await getUserById(friendId);
        if (friend != null) {
          friends.add(friend);
        }
      }

      return friends;
    } catch (e) {
      print('Erreur lors de la récupération des amis : $e');
      return [];
    }
  }
}