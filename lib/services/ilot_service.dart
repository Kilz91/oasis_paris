import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ilot_model.dart';

class IlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _ilotsCollection = FirebaseFirestore.instance.collection('ilots');

  // Récupérer tous les îlots
  Future<List<Ilot>> getAllIlots() async {
    try {
      QuerySnapshot snapshot = await _ilotsCollection.get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Ilot.fromJson(data);
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des îlots : $e');
      return [];
    }
  }

  // Récupérer un îlot par son ID
  Future<Ilot?> getIlotById(String id) async {
    try {
      DocumentSnapshot doc = await _ilotsCollection.doc(id).get();
      if (doc.exists) {
        return Ilot.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'îlot : $e');
      return null;
    }
  }

  // Récupérer les îlots par type
  Future<List<Ilot>> getIlotsByType(String type) async {
    try {
      QuerySnapshot snapshot = await _ilotsCollection
          .where('type', isEqualTo: type)
          .get();
      
      return snapshot.docs.map((doc) {
        return Ilot.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des îlots par type : $e');
      return [];
    }
  }

  // Importer des îlots depuis les données JSON
  Future<void> importIlots(List<Map<String, dynamic>> ilotsData) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var data in ilotsData) {
        DocumentReference docRef = _ilotsCollection.doc();
        batch.set(docRef, data);
      }
      
      await batch.commit();
      print('Importation des îlots réussie');
    } catch (e) {
      print('Erreur lors de l\'importation des îlots : $e');
    }
  }
}