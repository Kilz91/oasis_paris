import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Classe utilitaire contenant des fonctions partagées liées aux utilisateurs
class UserUtils {
  /// Convertit un UserModel en Map<String, dynamic>
  static Map<String, dynamic> userModelToMap(UserModel user) {
    return {
      'id': user.uid,
      'nom': user.lastName,
      'prenom': user.firstName,
      'email': user.email,
      'photoURL': user.photoURL,
    };
  }

  /// Récupère les informations des participants à partir de leurs IDs
  static Future<List<Map<String, String>>> fetchParticipantsInfo(List<String> participantIds) async {
    List<Map<String, String>> participantsInfo = [];
    
    for (String id in participantIds) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          participantsInfo.add({
            'id': id,
            'name': '${data['prenom'] ?? ''} ${data['nom'] ?? ''}',
          });
        } else {
          participantsInfo.add({
            'id': id,
            'name': 'Utilisateur inconnu',
          });
        }
      } catch (e) {
        print('Erreur lors de la récupération de l\'utilisateur $id: $e');
      }
    }

    return participantsInfo;
  }
  
  /// Convertit un statut de participant en texte lisible
  static String getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Accepté';
      case 'declined':
        return 'Refusé';
      default:
        return 'Statut inconnu';
    }
  }
  
  /// Compte le nombre de participants acceptés
  static int countAcceptedParticipants(List<String> participantsList, List<String> acceptedParticipantsList) {
    return acceptedParticipantsList.length;
  }
}