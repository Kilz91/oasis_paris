import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Créer une nouvelle notification
  Future<String?> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Sera attribué par Firestore
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        data: data,
      );
      
      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toMap());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la notification : $e');
      return null;
    }
  }
  
  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Erreur lors du marquage de la notification comme lue : $e');
    }
  }
  
  // Marquer toutes les notifications d'un utilisateur comme lues
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;
    
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Erreur lors du marquage de toutes les notifications comme lues : $e');
    }
  }
  
  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression de la notification : $e');
    }
  }
  
  // Supprimer toutes les notifications d'un utilisateur
  Future<void> deleteAllNotifications() async {
    if (currentUserId == null) return;
    
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Erreur lors de la suppression de toutes les notifications : $e');
    }
  }
  
  // Obtenir toutes les notifications d'un utilisateur
  Stream<List<NotificationModel>> getUserNotifications() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
  
  // Obtenir le nombre de notifications non lues
  Stream<int> getUnreadNotificationsCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }
    
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  // Créer une notification pour une demande d'ami
  Future<String?> createFriendRequestNotification({
    required String userId,
    required String senderName,
    required String senderId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Nouvelle demande d\'ami',
      message: '$senderName vous a envoyé une demande d\'ami',
      type: NotificationType.friendRequest,
      data: {'senderId': senderId},
    );
  }
  
  // Créer une notification pour une acceptation d'ami
  Future<String?> createFriendAcceptedNotification({
    required String userId,
    required String friendName,
    required String friendId,
  }) {
    return createNotification(
      userId: userId,
      title: 'Demande d\'ami acceptée',
      message: '$friendName a accepté votre demande d\'ami',
      type: NotificationType.friendAccepted,
      data: {'friendId': friendId},
    );
  }
  
  // Créer une notification pour une invitation à un rendez-vous
  Future<String?> createRendezvousInvitationNotification({
    required String userId,
    required String senderName,
    required String rendezvousId,
    required String rendezvousName,
    required DateTime rendezvousDate,
  }) {
    return createNotification(
      userId: userId,
      title: 'Nouvelle invitation',
      message: '$senderName vous a invité à "$rendezvousName"',
      type: NotificationType.rendezvousInvitation,
      data: {
        'rendezvousId': rendezvousId,
        'rendezvousDate': Timestamp.fromDate(rendezvousDate),
      },
    );
  }
  
  // Créer une notification pour une acceptation de rendez-vous
  Future<String?> createRdvAcceptanceNotification({
    required String rdvId,
    required String rdvName,
    required String organizerId,
  }) {
    return createNotification(
      userId: organizerId,
      title: 'Rendez-vous accepté',
      message: 'Quelqu\'un a accepté votre invitation à "$rdvName"',
      type: NotificationType.rendezvousAccepted,
      data: {'rendezvousId': rdvId},
    );
  }
  
  // Créer une notification pour une proposition de participant
  Future<String?> createParticipantRequest({
    required String rdvId,
    required String rdvName,
    required String organizerId,
    required String newParticipantId,
    required String newParticipantName,
  }) {
    return createNotification(
      userId: organizerId,
      title: 'Proposition de participant',
      message: '$newParticipantName a été proposé comme participant pour "$rdvName"',
      type: NotificationType.participantRequest,
      data: {
        'rendezvousId': rdvId,
        'newParticipantId': newParticipantId,
        'newParticipantName': newParticipantName,
      },
    );
  }
  
  // Traiter l'acceptation d'une proposition de participant
  Future<bool> acceptParticipantRequest({
    required String notificationId,
    required String rdvId,
    required String newParticipantId,
    required String newParticipantName,
    required String rdvName,
    required DateTime rdvDate,
  }) async {
    try {
      // 1. Mettre à jour le document de rendez-vous pour ajouter le nouveau participant
      final rdvRef = _firestore.collection('rendezvous').doc(rdvId);
      final rdvDoc = await rdvRef.get();
      
      if (!rdvDoc.exists) {
        print('Le rendez-vous n\'existe plus');
        return false;
      }
      
      // Obtenir l'organisateur pour l'envoyer dans la notification d'invitation
      final rdvData = rdvDoc.data() as Map<String, dynamic>;
      final organizerName = rdvData['organizerName'] ?? 'Un organisateur';
      
      // Mise à jour du document en fonction du format des participants (liste ou map)
      if (rdvData['participants'] is List) {
        await rdvRef.update({
          'participants': FieldValue.arrayUnion([newParticipantId]),
        });
      } else if (rdvData['participants'] is Map) {
        await rdvRef.update({
          'participants.$newParticipantId': 'pending',
        });
      } else {
        // Si le format n'est pas reconnu, utiliser une map par défaut
        await rdvRef.update({
          'participants': {newParticipantId: 'pending'},
        });
      }
      
      // 2. Envoyer une notification d'invitation au nouveau participant
      await createRendezvousInvitationNotification(
        userId: newParticipantId,
        senderName: organizerName,
        rendezvousId: rdvId,
        rendezvousName: rdvName,
        rendezvousDate: rdvDate,
      );
      
      // 3. Marquer la notification de proposition comme lue
      await markAsRead(notificationId);
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'acceptation de la proposition de participant: $e');
      return false;
    }
  }
  
  // Refuser une proposition de participant
  Future<bool> rejectParticipantRequest({
    required String notificationId,
  }) async {
    try {
      // Marquer simplement la notification comme lue
      await markAsRead(notificationId);
      return true;
    } catch (e) {
      print('Erreur lors du refus de la proposition de participant: $e');
      return false;
    }
  }
}