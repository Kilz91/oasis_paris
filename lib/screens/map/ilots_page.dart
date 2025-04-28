import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/ilot_model.dart';
import 'map_page.dart';  // Ajout de l'import pour accéder à MapPageWithSelectedIlot

class IlotsPage extends StatefulWidget {
  const IlotsPage({super.key});

  @override
  State<IlotsPage> createState() => _IlotsPageState();
}

class _IlotsPageState extends State<IlotsPage> {
  late Future<List<Ilot>> _futureIlots;
  List<Ilot> _allIlots = [];
  List<Ilot> _filteredIlots = [];
  TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tous';
  final List<String> _filterOptions = ['Tous', 'Nom', 'Type', 'Adresse'];

  @override
  void initState() {
    super.initState();
    _futureIlots = fetchIlots();
    _searchController.addListener(_filterIlots);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        print('Aucun record reçu depuis l\'API');
      }

      _allIlots = records.map<Ilot>((record) {
        try {
          return Ilot.fromJson(record);
        } catch (e) {
          print('Erreur lors du parsing d\'un record : $e');
          return Ilot(nom: 'Nom inconnu', latitude: 0.0, longitude: 0.0);
        }
      }).toList();
      
      _filteredIlots = List.from(_allIlots);
      return _allIlots;
    } else {
      throw Exception('Erreur lors de la récupération des données');
    }
  }

  void _filterIlots() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredIlots = List.from(_allIlots);
      });
      return;
    }
    
    setState(() {
      switch (_selectedFilter) {
        case 'Nom':
          _filteredIlots = _allIlots
              .where((ilot) => ilot.nom.toLowerCase().contains(query))
              .toList();
          break;
        case 'Type':
          _filteredIlots = _allIlots
              .where((ilot) => ilot.type.toLowerCase().contains(query))
              .toList();
          break;
        case 'Adresse':
          _filteredIlots = _allIlots
              .where((ilot) => ilot.adresse.toLowerCase().contains(query))
              .toList();
          break;
        default: // 'Tous'
          _filteredIlots = _allIlots
              .where((ilot) => 
                ilot.nom.toLowerCase().contains(query) ||
                ilot.type.toLowerCase().contains(query) ||
                ilot.adresse.toLowerCase().contains(query) ||
                ilot.heuresOuverture.toLowerCase().contains(query))
              .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Îlots de fraîcheur à Paris')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Rechercher un îlot',
                        hintText: 'Entrez un mot-clé...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                      ),
                    ),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: _selectedFilter == filter,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                    _filterIlots();
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Ilot>>(
              future: _futureIlots,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun îlot trouvé'));
                }

                // Une fois les données chargées
                if (_allIlots.isEmpty) {
                  // Initialiser les listes au premier chargement
                  _allIlots = snapshot.data!;
                  _filteredIlots = List.from(_allIlots);
                }

                return _filteredIlots.isEmpty
                  ? Center(child: Text('Aucun résultat trouvé pour cette recherche'))
                  : ListView.builder(
                      itemCount: _filteredIlots.length,
                      itemBuilder: (context, index) {
                        final ilot = _filteredIlots[index];
                        return ListTile(
                          leading: const Icon(Icons.park),
                          title: Text(ilot.nom),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Type: ${ilot.type}'),
                              Text('Adresse: ${ilot.adresse}', 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            _showIlotDetails(context, ilot);
                          },
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showIlotDetails(BuildContext context, Ilot ilot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(bottom: 20),
                      ),
                    ),
                    Text(
                      ilot.nom,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.category),
                      title: Text('Type'),
                      subtitle: Text(ilot.type),
                    ),
                    ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text('Adresse'),
                      subtitle: Text(ilot.adresse),
                    ),
                    ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text('Horaires'),
                      subtitle: Text(ilot.heuresOuverture),
                    ),
                    ListTile(
                      leading: Icon(Icons.map),
                      title: Text('Coordonnées'),
                      subtitle: Text(
                        'Latitude: ${ilot.latitude.toStringAsFixed(5)}\nLongitude: ${ilot.longitude.toStringAsFixed(5)}',
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Fermer la feuille modale
                          Navigator.pop(context);
                          
                          // Naviguer vers la page de carte en passant l'îlot
                          _navigateToMapWithIlot(context, ilot);
                        },
                        icon: Icon(Icons.directions),
                        label: Text('Voir sur la carte'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Nouvelle méthode pour naviguer vers la carte avec l'îlot sélectionné
  void _navigateToMapWithIlot(BuildContext context, Ilot ilot) {
    // Importer la page map dans votre fichier
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => MapPageWithSelectedIlot(
          selectedIlot: ilot,
        ),
      ),
    );
  }
}
