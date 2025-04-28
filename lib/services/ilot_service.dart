import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/ilot_model.dart';

class IlotService {
  // URL de l'API des îlots de fraîcheur de Paris
  final String apiUrl = 'https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/ilots-de-fraicheur-espaces-verts-frais/records';

  // Récupérer tous les îlots de fraîcheur
  Future<List<Ilot>> fetchAllIlots({int limit = 50}) async {
    final url = Uri.parse('$apiUrl?limit=$limit');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final records = body['results'] as List;

      return records.map<Ilot>((record) {
        try {
          return Ilot.fromJson(record);
        } catch (e) {
          print('Erreur lors du parsing d\'un record: $e');
          return Ilot(nom: 'Nom inconnu', latitude: 0.0, longitude: 0.0);
        }
      }).toList();
    } else {
      throw Exception('Erreur lors de la récupération des données: ${response.statusCode}');
    }
  }

  // Recherche d'îlots par nom ou adresse
  Future<List<Ilot>> searchIlots(String query, {int limit = 20}) async {
    // Encodage de la requête pour l'URL
    final encodedQuery = Uri.encodeComponent(query.toLowerCase());
    
    final url = Uri.parse('$apiUrl?where=lower(nom) like "%25$encodedQuery%25" or lower(adresse) like "%25$encodedQuery%25"&limit=$limit');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final records = body['results'] as List;

      return records.map<Ilot>((record) {
        try {
          return Ilot.fromJson(record);
        } catch (e) {
          print('Erreur lors du parsing d\'un record: $e');
          return Ilot(nom: 'Nom inconnu', latitude: 0.0, longitude: 0.0);
        }
      }).toList();
    } else {
      throw Exception('Erreur lors de la recherche des îlots: ${response.statusCode}');
    }
  }

  // Récupérer les îlots dans un rayon donné (en mètres) autour d'un point
  Future<List<Ilot>> getIlotsNearby(double lat, double lon, {double radius = 1000, int limit = 20}) async {
    final url = Uri.parse('$apiUrl?where=within_circle(geolocalisation, $lat, $lon, $radius)&limit=$limit');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final records = body['results'] as List;

      return records.map<Ilot>((record) {
        try {
          return Ilot.fromJson(record);
        } catch (e) {
          print('Erreur lors du parsing d\'un record: $e');
          return Ilot(nom: 'Nom inconnu', latitude: 0.0, longitude: 0.0);
        }
      }).toList();
    } else {
      throw Exception('Erreur lors de la récupération des îlots proches: ${response.statusCode}');
    }
  }

  // Récupérer un îlot par son ID ou son nom
  Future<Ilot?> getIlotById(String id) async {
    final url = Uri.parse('$apiUrl?where=recordid="$id" or nom="$id"&limit=1');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final records = body['results'] as List;

      if (records.isEmpty) {
        return null;
      }

      try {
        return Ilot.fromJson(records.first);
      } catch (e) {
        print('Erreur lors du parsing de l\'îlot: $e');
        return null;
      }
    } else {
      throw Exception('Erreur lors de la récupération de l\'îlot: ${response.statusCode}');
    }
  }

  // Filtrer les îlots par type
  Future<List<Ilot>> filterIlotsByType(String type, {int limit = 30}) async {
    // Encodage du type pour l'URL
    final encodedType = Uri.encodeComponent(type.toLowerCase());
    
    final url = Uri.parse('$apiUrl?where=lower(type) like "%25$encodedType%25"&limit=$limit');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final records = body['results'] as List;

      return records.map<Ilot>((record) {
        try {
          return Ilot.fromJson(record);
        } catch (e) {
          print('Erreur lors du parsing d\'un record: $e');
          return Ilot(nom: 'Nom inconnu', latitude: 0.0, longitude: 0.0);
        }
      }).toList();
    } else {
      throw Exception('Erreur lors du filtrage des îlots: ${response.statusCode}');
    }
  }

  // Récupérer tous les types d'îlots disponibles
  Future<List<String>> getAllIlotTypes() async {
    final url = Uri.parse('$apiUrl?select=type&group_by=type&limit=100');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final records = body['results'] as List;

      return records
          .map<String>((record) => record['type'] as String)
          .where((type) => type.isNotEmpty)
          .toList();
    } else {
      throw Exception('Erreur lors de la récupération des types d\'îlots: ${response.statusCode}');
    }
  }
}