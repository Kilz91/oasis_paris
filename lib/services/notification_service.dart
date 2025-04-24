import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de notification
class CustomNotification {
  final String id;
  final String type; // 'rdv_invitation', 'participant_request', 'rdv_acceptance'
  final String message;
  final DateTime createdAt;
  final String? rdvId;
  final bool isRead;
  final Map<String, dynamic> data;
  final String recipientId;
  final String senderId;

  CustomNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.rdvId,
    required this.isRead,
    required this.data,
    required this.recipientId,
    required this.senderId,
  });

  factory CustomNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomNotification(
      id: doc.id,
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      rdvId: data['rdvId'],
      isRead: data['isRead'] ?? false,
      data: data['data'] ?? {},
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Référence à la collection de notifications
  CollectionReference get _notificationsRef => _firestore.collection('notifications');

  // Récupérer toutes les notifications pour l'utilisateur actuel
  Stream<List<CustomNotification>> getAllNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _notificationsRef
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomNotification.fromDocument(doc))
          .toList();
    });
  }

  // Récupérer uniquement les notifications non lues
  Stream<List<CustomNotification>> getUnreadNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _notificationsRef
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CustomNotification.fromDocument(doc))
          .toList();
    });
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'isRead': true,
    });
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final unreadNotifications = await _notificationsRef
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Créer une invitation à un rendez-vous
  Future<void> createRdvInvitation({
    required String rdvId,
    required String recipientId,
    required String rdvName,
    required DateTime rdvDate,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) return;

    // Récupérer les informations de l'expéditeur
    final senderDoc = await _firestore.collection('users').doc(sender.uid).get();
    final senderData = senderDoc.data() as Map<String, dynamic>?;
    final senderName = '${senderData?['prenom'] ?? ''} ${senderData?['nom'] ?? ''}';

    // Créer la notification
    await _notificationsRef.add({
      'type': 'rdv_invitation',
      'message': '$senderName vous invite à un rendez-vous à $rdvName le ${_formatDate(rdvDate)}',
      'createdAt': FieldValue.serverTimestamp(),
      'rdvId': rdvId,
      'isRead': false,
      'recipientId': recipientId,
      'senderId': sender.uid,
      'data': {
        'rdvName': rdvName,
        'rdvDate': Timestamp.fromDate(rdvDate),
        'senderName': senderName,
      }
    });
  }

  // Créer une demande d'ajout de participant
  Future<void> createParticipantRequest({
    required String rdvId,
    required String rdvName,
    required String organizerId,
    required String newParticipantId,
    required String newParticipantName,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) return;

    // Récupérer les informations de l'expéditeur
    final senderDoc = await _firestore.collection('users').doc(sender.uid).get();
    final senderData = senderDoc.data() as Map<String, dynamic>?;
    final senderName = '${senderData?['prenom'] ?? ''} ${senderData?['nom'] ?? ''}';

    // Créer la notification
    await _notificationsRef.add({
      'type': 'participant_request',
      'message': '$senderName propose d\'inviter $newParticipantName à votre rendez-vous à $rdvName',
      'createdAt': FieldValue.serverTimestamp(),
      'rdvId': rdvId,
      'isRead': false,
      'recipientId': organizerId,
      'senderId': sender.uid,
      'data': {
        'rdvName': rdvName,
        'newParticipantId': newParticipantId,
        'newParticipantName': newParticipantName,
        'senderName': senderName,
      }
    });
  }
  
  // Créer une notification d'acceptation de rendez-vous
  Future<void> createRdvAcceptanceNotification({
    required String rdvId,
    required String rdvName,
    required String organizerId,
  }) async {
    final sender = _auth.currentUser;
    if (sender == null) return;

    // Récupérer les informations de l'expéditeur (celui qui accepte)
    final senderDoc = await _firestore.collection('users').doc(sender.uid).get();
    final senderData = senderDoc.data() as Map<String, dynamic>?;
    final senderName = '${senderData?['prenom'] ?? ''} ${senderData?['nom'] ?? ''}';

    // Créer la notification
    await _notificationsRef.add({
      'type': 'rdv_acceptance',
      'message': '$senderName a accepté votre invitation au rendez-vous à $rdvName',
      'createdAt': FieldValue.serverTimestamp(),
      'rdvId': rdvId,
      'isRead': false,
      'recipientId': organizerId,
      'senderId': sender.uid,
      'data': {
        'rdvName': rdvName,
        'acceptedBy': senderName,
      }
    });
  }

  // Répondre à une invitation à un rendez-vous
  Future<void> respondToRdvInvitation({
    required String notificationId,
    required String rdvId,
    required bool accepted,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Marquer la notification comme lue
    await markAsRead(notificationId);

    // Si la réponse est positive, ajouter l'utilisateur aux participants du rendez-vous
    if (accepted) {
      final rdvRef = _firestore.collection('rendezvous').doc(rdvId);
      final rdvDoc = await rdvRef.get();
      
      if (rdvDoc.exists) {
        final rdvData = rdvDoc.data() as Map<String, dynamic>;
        final organizerId = rdvData['userId'] as String;
        final rdvName = rdvData['ilotNom'] as String;
        
        // Mettre à jour le document du rendez-vous pour ajouter l'utilisateur aux participants acceptés
        await rdvRef.update({
          'acceptedParticipants': FieldValue.arrayUnion([user.uid])
        });
        
        // Créer une notification pour informer l'organisateur que l'invitation a été acceptée
        await createRdvAcceptanceNotification(
          rdvId: rdvId,
          rdvName: rdvName,
          organizerId: organizerId,
        );
      }
    }
    
    // Si la réponse est négative, on peut éventuellement ajouter l'utilisateur à une liste de refus
    // Mais ce n'est pas implémenté pour le moment
  }

  // Répondre à une demande d'ajout de participant
  Future<void> respondToParticipantRequest({
    required String notificationId,
    required String rdvId,
    required String newParticipantId,
    required bool approved,
  }) async {
    // Marquer la notification comme lue
    await markAsRead(notificationId);

    // Si la demande est approuvée, inviter le nouveau participant
    if (approved) {
      final rdvRef = _firestore.collection('rendezvous').doc(rdvId);
      final rdvDoc = await rdvRef.get();
      
      if (rdvDoc.exists) {
        final rdvData = rdvDoc.data() as Map<String, dynamic>;
        final rdvName = rdvData['ilotNom'] as String;
        final rdvDate = (rdvData['date'] as Timestamp).toDate();
        
        // Mettre à jour le document du rendez-vous pour ajouter l'utilisateur aux participants invités
        await rdvRef.update({
          'participants': FieldValue.arrayUnion([newParticipantId])
        });
        
        // Créer une invitation pour le nouveau participant
        await createRdvInvitation(
          rdvId: rdvId,
          recipientId: newParticipantId,
          rdvName: rdvName,
          rdvDate: rdvDate,
        );
      }
    }
  }
  
  // Formater une date pour l'affichage dans un message
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year à $hours:$minutes';
  }
}