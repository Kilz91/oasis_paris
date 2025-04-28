import 'package:cloud_firestore/cloud_firestore.dart';

class RendezVous {
  final String id;
  final String ilotId;
  final String ilotNom;
  final String ilotAdresse;
  final DateTime date;
  final String creatorId; // ID de l'utilisateur qui a créé le rendez-vous
  final Map<String, String> participants; // Map avec user ID comme clé et statut comme valeur ("pending", "accepted", "declined")
  final GeoPoint location;
  final DateTime createdAt;
  final List<Map<String, dynamic>> participantRequests; // Demandes d'ajout de participants

  RendezVous({
    required this.id,
    required this.ilotId,
    required this.ilotNom,
    required this.ilotAdresse,
    required this.date,
    required this.creatorId,
    required this.participants,
    required this.location,
    required this.createdAt,
    this.participantRequests = const [],
  });

  factory RendezVous.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertir les participants de liste à map avec statut
    Map<String, String> participantsMap = {};
    if (data['participants'] is List) {
      // Format ancien: liste d'IDs
      List<dynamic> participantsList = data['participants'] ?? [];
      for (String participantId in participantsList.cast<String>()) {
        participantsMap[participantId] = 'pending'; // Par défaut tous sont en pending
      }
    } else if (data['participants'] is Map) {
      // Format nouveau: map avec statut
      participantsMap = Map<String, String>.from(data['participants']);
    }

    return RendezVous(
      id: doc.id,
      ilotId: data['ilotId'] ?? '',
      ilotNom: data['ilotNom'] ?? '',
      ilotAdresse: data['ilotAdresse'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      creatorId: data['userId'] ?? data['creatorId'] ?? '',
      participants: participantsMap,
      location: data['location'] ?? GeoPoint(0, 0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantRequests: List<Map<String, dynamic>>.from(data['participantRequests'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ilotId': ilotId,
      'ilotNom': ilotNom,
      'ilotAdresse': ilotAdresse,
      'date': Timestamp.fromDate(date),
      'creatorId': creatorId,
      'participants': participants,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'participantRequests': participantRequests,
    };
  }

  // Méthode pour obtenir tous les IDs des participants (peu importe leur statut)
  List<String> getAllParticipantIds() {
    return participants.keys.toList();
  }

  // Méthode pour obtenir les IDs des participants acceptés uniquement
  List<String> getAcceptedParticipantIds() {
    return participants.entries
        .where((entry) => entry.value == 'accepted')
        .map((entry) => entry.key)
        .toList();
  }

  // Méthode pour obtenir les IDs des participants en attente
  List<String> getPendingParticipantIds() {
    return participants.entries
        .where((entry) => entry.value == 'pending')
        .map((entry) => entry.key)
        .toList();
  }

  // Méthode pour vérifier si un utilisateur est le créateur
  bool isCreator(String userId) {
    return creatorId == userId;
  }

  // Méthode pour vérifier si un utilisateur est un participant (peu importe son statut)
  bool isParticipant(String userId) {
    return participants.containsKey(userId);
  }

  // Méthode pour vérifier si un utilisateur est un participant accepté
  bool isAcceptedParticipant(String userId) {
    return participants[userId] == 'accepted';
  }

  // Méthode pour vérifier si un utilisateur a refusé le rendez-vous
  bool isDeclinedParticipant(String userId) {
    return participants[userId] == 'declined';
  }

  // Méthode pour vérifier si un utilisateur est en attente de réponse
  bool isPendingParticipant(String userId) {
    return participants[userId] == 'pending';
  }
}