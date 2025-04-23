import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ilot_model.dart';

class IlotsPage extends StatefulWidget {
  const IlotsPage({super.key});

  @override
  State<IlotsPage> createState() => _IlotsPageState();
}

class _IlotsPageState extends State<IlotsPage> {
  late Future<List<Ilot>> _futureIlots;

  @override
  void initState() {
    super.initState();
    _futureIlots = fetchIlots();
  }

  Future<List<Ilot>> fetchIlots() async {
    final url = Uri.parse(
      'https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/ilots-de-fraicheur-espaces-verts-frais/records?limit=50',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      print('Réponse JSON reçue : ${response.body}');

      final records = body['results'] as List;

      if (records.isNotEmpty) {
        print('Premier record JSON :');
        print(jsonEncode(records.first));
      } else {
        print('Aucun record reçu depuis l’API');
      }

      return records.map<Ilot>((record) {
        try {
          return Ilot.fromJson(record);
        } catch (e) {
          print('Erreur lors du parsing d’un record : $e');
          return Ilot(nom: 'Nom inconnu', latitude: 0.0, longitude: 0.0);
        }
      }).toList();
    } else {
      throw Exception('Erreur lors de la récupération des données');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Îlots de fraîcheur à Paris')),
      body: FutureBuilder<List<Ilot>>(
        future: _futureIlots,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun îlot trouvé'));
          }

          final ilots = snapshot.data!;

          return ListView.builder(
            itemCount: ilots.length,
            itemBuilder: (context, index) {
              final ilot = ilots[index];
              print('Affichage : ${ilot.nom}');
              return ListTile(
                leading: const Icon(Icons.park),
                title: Text(ilot.nom),
                subtitle: Text(
                  'Lat: ${ilot.latitude.toStringAsFixed(5)}, Lng: ${ilot.longitude.toStringAsFixed(5)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
