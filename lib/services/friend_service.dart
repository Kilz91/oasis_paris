import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class FriendService {
  // Singleton pattern
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  String? get currentUserId => _auth.currentUser?.uid;

  // Charger la liste des amis depuis Firestore
  Future<List<UserModel>> loadFriends() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Récupérer la liste des amis de l'utilisateur actuel
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('friends')) {
        // Si l'utilisateur n'a pas encore de liste d'amis, on initialise une liste vide
        return [];
      }

      // Récupérer les IDs des amis
      List<dynamic> friendIds = userDoc.data()!['friends'] ?? [];
      List<UserModel> friendsList = [];

      // Récupérer les informations de chaque ami
      for (String friendId in List<String>.from(friendIds)) {
        final friendDoc = await _firestore
            .collection('users')
            .doc(friendId)
            .get();

        if (friendDoc.exists) {
          friendsList.add(UserModel.fromMap(friendDoc.data()!, friendId));
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
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Récupérer les demandes d'amis reçues par l'utilisateur actuel
      final querySnapshot = await _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];

      for (var doc in querySnapshot.docs) {
        final request = FriendRequestModel.fromMap(doc.data(), doc.id);
        
        // Récupérer les informations du demandeur
        final senderDoc = await _firestore
            .collection('users')
            .doc(request.senderId)
            .get();
        
        if (senderDoc.exists) {
          final senderData = senderDoc.data()!;
          requests.add({
            'request': request,
            'sender': UserModel.fromMap(senderData, request.senderId),
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
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // Récupérer les demandes d'amis envoyées par l'utilisateur actuel
      final querySnapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];

      for (var doc in querySnapshot.docs) {
        final request = FriendRequestModel.fromMap(doc.data(), doc.id);
        
        // Récupérer les informations du destinataire
        final receiverDoc = await _firestore
            .collection('users')
            .doc(request.receiverId)
            .get();
        
        if (receiverDoc.exists) {
          final receiverData = receiverDoc.data()!;
          requests.add({
            'request': request,
            'receiver': UserModel.fromMap(receiverData, request.receiverId),
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
    required List<UserModel> currentFriends,
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

    if (currentUserId == null) {
      result['message'] = 'Utilisateur non connecté';
      return result;
    }

    try {
      QuerySnapshot querySnapshot;
      
      if (isSearchingByEmail) {
        // Recherche par email
        querySnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: searchTerm)
            .get();
      } else {
        // Recherche par numéro de téléphone
        querySnapshot = await _firestore
            .collection('users')
            .where('telephone', isEqualTo: searchTerm)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        result['message'] = 'Aucun utilisateur trouvé avec ces informations';
        return result;
      }

      final foundUser = querySnapshot.docs.first;
      if (foundUser.id == currentUserId) {
        result['message'] = 'Vous ne pouvez pas vous ajouter comme ami';
        return result;
      }

      // Vérifier si l'utilisateur est déjà dans la liste d'amis
      final isAlreadyFriend = currentFriends.any((friend) => friend.uid == foundUser.id);
      if (isAlreadyFriend) {
        result['message'] = 'Cette personne est déjà dans votre liste d\'amis';
        return result;
      }

      // Vérifier si une demande existe déjà
      final existingRequestQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: foundUser.id)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (existingRequestQuery.docs.isNotEmpty) {
        result['message'] = 'Vous avez déjà envoyé une demande à cette personne';
        return result;
      }

      final reverseRequestQuery = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: foundUser.id)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      if (reverseRequestQuery.docs.isNotEmpty) {
        result['message'] = 'Cette personne vous a déjà envoyé une demande d\'ami';
        return result;
      }

      result['success'] = true;
      result['userData'] = UserModel.fromMap(foundUser.data() as Map<String, dynamic>, foundUser.id);
      return result;
    } catch (e) {
      print('Erreur lors de la recherche d\'utilisateur: $e');
      result['message'] = 'Une erreur s\'est produite. Veuillez réessayer.';
      return result;
    }
  }

  // Envoyer une demande d'ami
  Future<bool> sendFriendRequest(String receiverId) async {
    if (currentUserId == null) return false;

    try {
      // Créer la demande d'ami
      final friendRequest = FriendRequestModel(
        id: '',  // Sera attribué par Firestore
        senderId: currentUserId!,
        receiverId: receiverId,
        status: FriendRequestStatus.pending,
      );
      
      final docRef = await _firestore
          .collection('friendRequests')
          .add(friendRequest.toMap());
      
      // Récupérer les informations de l'expéditeur pour la notification
      final senderDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (senderDoc.exists) {
        final senderData = senderDoc.data()!;
        final senderName = '${senderData['prenom']} ${senderData['nom']}';
        
        // Envoyer une notification au destinataire
        await _notificationService.createFriendRequestNotification(
          userId: receiverId,
          senderName: senderName,
          senderId: currentUserId!,
        );
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'envoi de la demande d\'ami: $e');
      return false;
    }
  }

  // Accepter une demande d'ami
  Future<bool> acceptFriendRequest(String requestId, String friendId) async {
    if (currentUserId == null) return false;

    try {
      // Mettre à jour le statut de la demande d'ami
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Ajouter l'ami à la liste des amis de l'utilisateur actuel
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'friends': FieldValue.arrayUnion([friendId])
      });

      // Ajouter l'utilisateur actuel à la liste des amis de l'ami
      await _firestore
          .collection('users')
          .doc(friendId)
          .update({
        'friends': FieldValue.arrayUnion([currentUserId])
      });
      
      // Récupérer les informations de l'utilisateur actuel pour la notification
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (currentUserDoc.exists) {
        final userData = currentUserDoc.data()!;
        final userName = '${userData['prenom']} ${userData['nom']}';
        
        // Envoyer une notification à l'ami
        await _notificationService.createFriendAcceptedNotification(
          userId: friendId,
          friendName: userName,
          friendId: currentUserId!,
        );
      }

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
      await _firestore
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
      await _firestore
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
    if (currentUserId == null) return false;

    try {
      // Supprimer l'ami de la liste des amis de l'utilisateur actuel
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'friends': FieldValue.arrayRemove([friendId])
      });

      // Supprimer l'utilisateur actuel de la liste des amis de l'ami
      await _firestore
          .collection('users')
          .doc(friendId)
          .update({
        'friends': FieldValue.arrayRemove([currentUserId])
      });

      return true;
    } catch (e) {
      print('Erreur lors de la suppression d\'un ami: $e');
      return false;
    }
  }
  
  // Obtenir le stream des demandes d'amis en attente
  Stream<int> pendingFriendRequestsCountStream() {
    if (currentUserId == null) {
      return Stream.value(0);
    }
    
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}