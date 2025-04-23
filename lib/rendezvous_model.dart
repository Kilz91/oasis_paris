import 'package:cloud_firestore/cloud_firestore.dart';

class RendezVous {
  final String id;
  final String ilotId;
  final String ilotNom;
  final String ilotAdresse;
  final DateTime date;
  final String userId;
  final List<String> participants;
  final GeoPoint location;

  RendezVous({
    required this.id,
    required this.ilotId,
    required this.ilotNom,
    required this.ilotAdresse,
    required this.date,
    required this.userId,
    required this.participants,
    required this.location,
  });

  // Convertir un document Firestore en objet RendezVous
  factory RendezVous.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RendezVous(
      id: doc.id,
      ilotId: data['ilotId'] ?? '',
      ilotNom: data['ilotNom'] ?? '',
      ilotAdresse: data['ilotAdresse'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      location: data['location'] ?? const GeoPoint(0, 0),
    );
  }

  // Convertir l'objet en Map pour le stockage dans Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ilotId': ilotId,
      'ilotNom': ilotNom,
      'ilotAdresse': ilotAdresse,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'participants': participants,
      'location': location,
    };
  }
}