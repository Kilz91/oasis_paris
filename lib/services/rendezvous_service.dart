import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rendezvous_model.dart';

class RendezvousService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _rdvCollection = FirebaseFirestore.instance.collection('rendezvous');

  // Créer un nouveau rendez-vous
  Future<String?> createRendezvous(RendezVous rdv) async {
    try {
      DocumentReference docRef = await _rdvCollection.add(rdv.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du rendez-vous : $e');
      return null;
    }
  }

  // Obtenir un rendez-vous par ID
  Future<RendezVous?> getRendezvousById(String id) async {
    try {
      DocumentSnapshot doc = await _rdvCollection.doc(id).get();
      if (doc.exists) {
        return RendezVous.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du rendez-vous : $e');
      return null;
    }
  }

  // Récupérer les rendez-vous d'un utilisateur
  Future<List<RendezVous>> getUserRendezvous(String userId) async {
    try {
      QuerySnapshot snapshot = await _rdvCollection
          .where('participants', arrayContains: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        return RendezVous.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des rendez-vous : $e');
      return [];
    }
  }

  // Mettre à jour un rendez-vous
  Future<void> updateRendezvous(String id, Map<String, dynamic> data) async {
    try {
      await _rdvCollection.doc(id).update(data);
    } catch (e) {
      print('Erreur lors de la mise à jour du rendez-vous : $e');
    }
  }

  // Supprimer un rendez-vous
  Future<void> deleteRendezvous(String id) async {
    try {
      await _rdvCollection.doc(id).delete();
    } catch (e) {
      print('Erreur lors de la suppression du rendez-vous : $e');
    }
  }

  // Ajouter un participant à un rendez-vous
  Future<void> addParticipant(String rdvId, String userId) async {
    try {
      await _rdvCollection.doc(rdvId).update({
        'participants': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('Erreur lors de l\'ajout du participant : $e');
    }
  }

  // Retirer un participant d'un rendez-vous
  Future<void> removeParticipant(String rdvId, String userId) async {
    try {
      await _rdvCollection.doc(rdvId).update({
        'participants': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('Erreur lors du retrait du participant : $e');
    }
  }

  // Flux de données pour les rendez-vous d'un utilisateur
  Stream<List<RendezVous>> userRendezvousStream(String userId) {
    return _rdvCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return RendezVous.fromFirestore(doc);
          }).toList();
        });
  }
}