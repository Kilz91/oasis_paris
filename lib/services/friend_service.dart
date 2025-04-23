import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  // Singleton pattern
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  // Charger la liste des amis depuis Firestore
  Future<List<Map<String, dynamic>>> loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Récupérer la liste des amis de l'utilisateur actuel
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('friends')) {
        // Si l'utilisateur n'a pas encore de liste d'amis, on initialise une liste vide
        return [];
      }

      // Récupérer les IDs des amis
      List<dynamic> friendIds = userDoc.data()!['friends'] ?? [];
      List<Map<String, dynamic>> friendsList = [];

      // Récupérer les informations de chaque ami
      for (String friendId in List<String>.from(friendIds)) {
        final friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();

        if (friendDoc.exists) {
          final friendData = friendDoc.data()!;
          friendsList.add({
            'id': friendId,
            'nom': friendData['nom'] ?? 'Sans nom',
            'prenom': friendData['prenom'] ?? '',
            'email': friendData['email'] ?? 'Email non disponible',
            'photoURL': friendData['photoURL'],
          });
        }
      }

      return friendsList;
    } catch (e) {
      print('Erreur lors du chargement des amis: $e');
      return [];
    }
  }

  // Charger la liste des demandes d'amis reçues depuis Firestore
  Future<List<Map<String, dynamic>>> loadFriendRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Récupérer les demandes d'amis reçues par l'utilisateur actuel
      final querySnapshot = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'];
        
        // Récupérer les informations du demandeur
        final senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
        
        if (senderDoc.exists) {
          final senderData = senderDoc.data()!;
          requests.add({
            'requestId': doc.id,
            'id': senderId,
            'nom': senderData['nom'] ?? 'Sans nom',
            'prenom': senderData['prenom'] ?? '',
            'email': senderData['email'] ?? 'Email non disponible',
            'photoURL': senderData['photoURL'],
            'timestamp': data['timestamp'],
          });
        }
      }

      return requests;
    } catch (e) {
      print('Erreur lors du chargement des demandes d\'amis: $e');
      return [];
    }
  }

  // Charger la liste des demandes d'amis envoyées depuis Firestore
  Future<List<Map<String, dynamic>>> loadSentRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Récupérer les demandes d'amis envoyées par l'utilisateur actuel
      final querySnapshot = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('senderId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final receiverId = data['receiverId'];
        
        // Récupérer les informations du destinataire
        final receiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();
        
        if (receiverDoc.exists) {
          final receiverData = receiverDoc.data()!;
          requests.add({
            'requestId': doc.id,
            'id': receiverId,
            'nom': receiverData['nom'] ?? 'Sans nom',
            'prenom': receiverData['prenom'] ?? '',
            'email': receiverData['email'] ?? 'Email non disponible',
            'photoURL': receiverData['photoURL'],
            'timestamp': data['timestamp'],
          });
        }
      }

      return requests;
    } catch (e) {
      print('Erreur lors du chargement des demandes d\'amis envoyées: $e');
      return [];
    }
  }

  // Rechercher un utilisateur par email ou téléphone
  Future<Map<String, dynamic>> searchUser({
    required String searchTerm, 
    required bool isSearchingByEmail,
    required List<Map<String, dynamic>> currentFriends,
  }) async {
    final result = <String, dynamic>{
      'success': false,
      'message': '',
      'userData': null,
    };

    if (searchTerm.isEmpty) {
      result['message'] = 'Veuillez entrer un email ou un numéro de téléphone';
      return result;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      result['message'] = 'Utilisateur non connecté';
      return result;
    }

    try {
      QuerySnapshot querySnapshot;
      
      if (isSearchingByEmail) {
        // Recherche par email
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: searchTerm)
            .get();
      } else {
        // Recherche par numéro de téléphone
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('telephone', isEqualTo: searchTerm)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        result['message'] = 'Aucun utilisateur trouvé avec ces informations';
        return result;
      }

      final foundUser = querySnapshot.docs.first;
      if (foundUser.id == user.uid) {
        result['message'] = 'Vous ne pouvez pas vous ajouter comme ami';
        return result;
      }

      // Vérifier si l'utilisateur est déjà dans la liste d'amis
      final isAlreadyFriend = currentFriends.any((friend) => friend['id'] == foundUser.id);
      if (isAlreadyFriend) {
        result['message'] = 'Cette personne est déjà dans votre liste d\'amis';
        return result;
      }

      // Vérifier si une demande existe déjà
      final existingRequestQuery = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('senderId', isEqualTo: user.uid)
          .where('receiverId', isEqualTo: foundUser.id)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (existingRequestQuery.docs.isNotEmpty) {
        result['message'] = 'Vous avez déjà envoyé une demande à cette personne';
        return result;
      }

      final reverseRequestQuery = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('senderId', isEqualTo: foundUser.id)
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (reverseRequestQuery.docs.isNotEmpty) {
        result['message'] = 'Cette personne vous a déjà envoyé une demande d\'ami';
        return result;
      }

      result['success'] = true;
      result['userData'] = {
        'id': foundUser.id,
        'data': foundUser.data(),
      };
      return result;
    } catch (e) {
      print('Erreur lors de la recherche d\'utilisateur: $e');
      result['message'] = 'Une erreur s\'est produite. Veuillez réessayer.';
      return result;
    }
  }

  // Envoyer une demande d'ami
  Future<bool> sendFriendRequest(String receiverId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      await FirebaseFirestore.instance.collection('friendRequests').add({
        'senderId': user.uid,
        'receiverId': receiverId,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de l\'envoi de la demande d\'ami: $e');
      return false;
    }
  }

  // Accepter une demande d'ami
  Future<bool> acceptFriendRequest(String requestId, String friendId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Mettre à jour le statut de la demande d'ami
      await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Ajouter l'ami à la liste des amis de l'utilisateur actuel
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'friends': FieldValue.arrayUnion([friendId])
      });

      // Ajouter l'utilisateur actuel à la liste des amis de l'ami
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .update({
        'friends': FieldValue.arrayUnion([user.uid])
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'acceptation de la demande d\'ami: $e');
      return false;
    }
  }

  // Refuser une demande d'ami
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      // Rejeter la demande d'ami
      await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'rejected'});

      return true;
    } catch (e) {
      print('Erreur lors du refus de la demande d\'ami: $e');
      return false;
    }
  }

  // Annuler une demande d'ami envoyée
  Future<bool> cancelFriendRequest(String requestId) async {
    try {
      // Supprimer la demande d'ami
      await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(requestId)
          .delete();

      return true;
    } catch (e) {
      print('Erreur lors de l\'annulation de la demande d\'ami: $e');
      return false;
    }
  }

  // Supprimer un ami
  Future<bool> removeFriend(String friendId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Supprimer l'ami de la liste des amis de l'utilisateur actuel
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'friends': FieldValue.arrayRemove([friendId])
      });

      // Supprimer l'utilisateur actuel de la liste des amis de l'ami
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .update({
        'friends': FieldValue.arrayRemove([user.uid])
      });

      return true;
    } catch (e) {
      print('Erreur lors de la suppression d\'un ami: $e');
      return false;
    }
  }
}