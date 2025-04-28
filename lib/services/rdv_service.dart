import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rendezvous_model.dart';
import 'notification_service.dart';

class RdvService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => _auth.currentUser?.uid;

  // Créer un nouveau rendez-vous
  Future<String> createRendezVous({
    required String ilotId,
    required String ilotNom,
    required String ilotAdresse,
    required DateTime date,
    required List<String> participants,
    required double latitude,
    required double longitude,
  }) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final user = _auth.currentUser!;

      // Créer le document du rendez-vous
      final docRef = await _firestore.collection('rendezvous').add({
        'ilotId': ilotId,
        'ilotNom': ilotNom,
        'ilotAdresse': ilotAdresse,
        'date': Timestamp.fromDate(date),
        'userId': user.uid,
        'organizerName': user.displayName ?? 'Utilisateur',
        'participants': participants,
        'acceptedParticipants': [], // Liste pour les participants qui ont accepté
        'location': GeoPoint(latitude, longitude),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Envoyer une notification à chaque participant
      for (String participantId in participants) {
        await _notificationService.createRdvInvitation(
          rdvId: docRef.id,
          recipientId: participantId,
          rdvName: ilotNom,
          rdvDate: date,
        );
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du rendez-vous: $e');
    }
  }

  // Obtenir les rendez-vous de l'utilisateur (créés ou acceptés)
  Stream<List<RendezVous>> getUserRendezVous() {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Union de deux requêtes : les RDV où l'utilisateur est créateur OU accepté
    return _firestore
        .collection('rendezvous')
        .where(Filter.or(
          Filter('userId', isEqualTo: currentUserId),
          Filter('acceptedParticipants', arrayContains: currentUserId!),
        ))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RendezVous.fromFirestore(doc))
            .toList());
  }

  // Obtenir les invitations en attente pour l'utilisateur
  Stream<List<RendezVous>> getPendingInvitations() {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    return _firestore
        .collection('rendezvous')
        .where('participants', arrayContains: currentUserId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      
      // Filtrer pour ne garder que les RDV où l'utilisateur n'a pas encore accepté
      return docs.where((doc) {
        final acceptedParticipants = List<String>.from(doc.data()['acceptedParticipants'] ?? []);
        return !acceptedParticipants.contains(currentUserId);
      })
      .map((doc) => RendezVous.fromFirestore(doc))
      .toList();
    });
  }

  // Répondre à une invitation
  Future<void> respondToInvitation(String rdvId, bool accept) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final rdvRef = _firestore.collection('rendezvous').doc(rdvId);
    final rdvDoc = await rdvRef.get();
    
    if (!rdvDoc.exists) {
      throw Exception('Ce rendez-vous n\'existe plus');
    }
    
    if (accept) {
      // Accepter l'invitation
      await rdvRef.update({
        'acceptedParticipants': FieldValue.arrayUnion([currentUserId])
      });
      
      // Envoyer une notification à l'organisateur
      final rdvData = rdvDoc.data() as Map<String, dynamic>;
      final organizerId = rdvData['userId'] as String;
      await _notificationService.createRdvAcceptanceNotification(
        rdvId: rdvId,
        rdvName: rdvData['ilotNom'],
        organizerId: organizerId,
      );
    } else {
      // Refuser l'invitation en retirant l'utilisateur des participants
      await rdvRef.update({
        'participants': FieldValue.arrayRemove([currentUserId])
      });
    }
  }

  // Obtenir les détails d'un rendez-vous spécifique
  Future<RendezVous?> getRendezVousDetails(String rdvId) async {
    try {
      final doc = await _firestore.collection('rendezvous').doc(rdvId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return RendezVous.fromFirestore(doc);
    } catch (e) {
      print('Erreur lors de la récupération des détails du rendez-vous: $e');
      return null;
    }
  }

  // Modifier un rendez-vous existant
  Future<void> updateRendezVous({
    required String rdvId,
    DateTime? date,
    List<String>? participants,
  }) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Vérifier que l'utilisateur est bien le créateur du rendez-vous
    final rdvDoc = await _firestore.collection('rendezvous').doc(rdvId).get();
    
    if (!rdvDoc.exists) {
      throw Exception('Ce rendez-vous n\'existe plus');
    }
    
    final rdvData = rdvDoc.data() as Map<String, dynamic>;
    if (rdvData['userId'] != currentUserId) {
      throw Exception('Vous n\'êtes pas autorisé à modifier ce rendez-vous');
    }

    final updates = <String, dynamic>{};
    
    if (date != null) {
      updates['date'] = Timestamp.fromDate(date);
    }
    
    if (participants != null) {
      // Conserver les participants qui ont déjà accepté
      final acceptedParticipants = List<String>.from(rdvData['acceptedParticipants'] ?? []);
      
      // Nouveaux participants à qui envoyer des invitations
      final existingParticipants = List<String>.from(rdvData['participants'] ?? []);
      final newParticipants = participants.where((p) => !existingParticipants.contains(p)).toList();
      
      updates['participants'] = participants;
      
      // Envoyer des notifications aux nouveaux participants
      for (String participantId in newParticipants) {
        await _notificationService.createRdvInvitation(
          rdvId: rdvId,
          recipientId: participantId,
          rdvName: rdvData['ilotNom'],
          rdvDate: (date ?? rdvData['date'].toDate()),
        );
      }
    }
    
    if (updates.isNotEmpty) {
      await _firestore.collection('rendezvous').doc(rdvId).update(updates);
    }
  }

  // Supprimer un rendez-vous
  Future<void> deleteRendezVous(String rdvId) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Vérifier que l'utilisateur est bien le créateur du rendez-vous
    final rdvDoc = await _firestore.collection('rendezvous').doc(rdvId).get();
    
    if (rdvDoc.exists) {
      final rdvData = rdvDoc.data() as Map<String, dynamic>;
      if (rdvData['userId'] != currentUserId) {
        throw Exception('Vous n\'êtes pas autorisé à supprimer ce rendez-vous');
      }
    }

    await _firestore.collection('rendezvous').doc(rdvId).delete();
  }

  // Quitter un rendez-vous (pour les participants)
  Future<void> leaveRendezVous(String rdvId) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    await _firestore.collection('rendezvous').doc(rdvId).update({
      'participants': FieldValue.arrayRemove([currentUserId]),
      'acceptedParticipants': FieldValue.arrayRemove([currentUserId]),
    });
  }

  // Obtenir les participants à un rendez-vous avec leurs informations
  Future<List<Map<String, dynamic>>> getRendezVousParticipants(String rdvId) async {
    try {
      final rdvDoc = await _firestore.collection('rendezvous').doc(rdvId).get();
      
      if (!rdvDoc.exists) {
        return [];
      }
      
      final rdvData = rdvDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(rdvData['participants'] ?? []);
      final acceptedParticipants = List<String>.from(rdvData['acceptedParticipants'] ?? []);
      
      // Ajouter l'organisateur s'il n'est pas déjà dans la liste
      final organizerId = rdvData['userId'] as String;
      if (!participants.contains(organizerId)) {
        participants.add(organizerId);
      }
      
      final participantsList = <Map<String, dynamic>>[];
      
      // Récupérer les informations de chaque participant
      for (final participantId in participants) {
        final userDoc = await _firestore.collection('users').doc(participantId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          participantsList.add({
            'id': participantId,
            'nom': userData['nom'] ?? '',
            'prenom': userData['prenom'] ?? '',
            'isOrganizer': participantId == organizerId,
            'status': acceptedParticipants.contains(participantId) ? 'accepted' 
                   : participantId == organizerId ? 'organizer' : 'pending',
          });
        }
      }
      
      return participantsList;
    } catch (e) {
      print('Erreur lors de la récupération des participants: $e');
      return [];
    }
  }
  
  // Proposer un participant à un rendez-vous
  Future<void> proposeParticipant({
    required String rdvId, 
    required String participantId,
  }) async {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    try {
      final rdvDoc = await _firestore.collection('rendezvous').doc(rdvId).get();
      
      if (!rdvDoc.exists) {
        throw Exception('Ce rendez-vous n\'existe plus');
      }
      
      final rdvData = rdvDoc.data() as Map<String, dynamic>;
      final organizerId = rdvData['userId'] as String;
      final participants = List<String>.from(rdvData['participants'] ?? []);
      
      // Vérifier si l'utilisateur est déjà dans les participants
      if (participants.contains(participantId)) {
        throw Exception('Cette personne est déjà invitée à ce rendez-vous');
      }
      
      // Obtenir les informations du participant proposé
      final proposedUserDoc = await _firestore.collection('users').doc(participantId).get();
      
      if (!proposedUserDoc.exists) {
        throw Exception('Utilisateur introuvable');
      }
      
      final proposedUserData = proposedUserDoc.data() as Map<String, dynamic>;
      final proposedUserName = '${proposedUserData['prenom']} ${proposedUserData['nom']}';
      
      // Envoyer une notification à l'organisateur pour proposer le participant
      await _notificationService.createParticipantRequest(
        rdvId: rdvId,
        rdvName: rdvData['ilotNom'],
        organizerId: organizerId,
        newParticipantId: participantId,
        newParticipantName: proposedUserName,
      );
      
    } catch (e) {
      throw Exception('Erreur lors de la proposition du participant: $e');
    }
  }
  
  // Obtenir les prochains rendez-vous (à venir)
  Stream<List<RendezVous>> getUpcomingRendezVous() {
    if (currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }

    final now = Timestamp.now();
    
    return _firestore
        .collection('rendezvous')
        .where(Filter.or(
          Filter('userId', isEqualTo: currentUserId),
          Filter('acceptedParticipants', arrayContains: currentUserId!),
        ))
        .where('date', isGreaterThanOrEqualTo: now)
        .orderBy('date')
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RendezVous.fromFirestore(doc))
            .toList());
  }
}