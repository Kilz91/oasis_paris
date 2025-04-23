import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ilot_model.dart';
import 'services/friend_service.dart'; // Import du FriendService

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final FriendService _friendService = FriendService(); // Instance du FriendService
  
  // Position centrée sur Paris
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(48.856614, 2.3522219),
    zoom: 12.0,
  );
  
  Set<Marker> _markers = {};
  Map<String, Ilot> _ilotsMap = {};
  bool _isLoading = true;
  String _error = '';
  late BitmapDescriptor _markerIcon;

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcon();
    _fetchIlots();
  }
  
  Future<void> _setCustomMarkerIcon() async {
    _markerIcon = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  Future<void> _fetchIlots() async {
    try {
      final ilots = await fetchIlots();
      
      // Créer une map d'îlots pour retrouver facilement les infos par ID
      final ilotsMap = <String, Ilot>{};
      for (var ilot in ilots) {
        if (ilot.latitude != 0.0 && ilot.longitude != 0.0) {
          ilotsMap[ilot.nom] = ilot;
        }
      }
      
      setState(() {
        _ilotsMap = ilotsMap;
        _markers = _createMarkers(ilots);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }
  }

  Set<Marker> _createMarkers(List<Ilot> ilots) {
    return ilots.map((ilot) {
      // Ne créez un marqueur que si les coordonnées sont valides
      if (ilot.latitude != 0.0 && ilot.longitude != 0.0) {
        return Marker(
          markerId: MarkerId(ilot.nom),
          position: LatLng(ilot.latitude, ilot.longitude),
          infoWindow: InfoWindow(
            title: ilot.nom,
            snippet: ilot.adresse.isNotEmpty ? ilot.adresse : 'Îlot de fraîcheur',
          ),
          icon: _markerIcon,
          onTap: () {
            _showIlotDetails(ilot);
          },
        );
      }
      return null;
    })
    .whereType<Marker>()  // Filtrer les nulls
    .toSet();
  }

  // Afficher les détails de l'îlot et proposer de programmer un rendez-vous
  void _showIlotDetails(Ilot ilot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ilot.nom,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 12),
            if (ilot.adresse.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.teal),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ilot.adresse,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.calendar_today),
                label: Text('Programmer un rendez-vous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showProgramRdvDialog(ilot);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Popup pour programmer un rendez-vous
  void _showProgramRdvDialog(Ilot ilot) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    List<String> selectedParticipants = [];
    List<Map<String, dynamic>> allFriends = [];
    bool isLoadingFriends = true;
    
    // Utiliser un StatefulBuilder pour gérer correctement l'état dans le dialog
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // Charger la liste des amis si ce n'est pas déjà fait
            if (isLoadingFriends) {
              _friendService.loadFriends().then((friends) {
                if (mounted) {
                  setState(() {
                    allFriends = friends;
                    isLoadingFriends = false;
                  });
                }
              }).catchError((error) {
                print('Erreur lors du chargement des amis: $error');
                if (mounted) {
                  setState(() {
                    allFriends = [];
                    isLoadingFriends = false;
                  });
                }
              });
            }
            
            // Fonction pour sélectionner une date
            Future<void> _selectDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: Colors.teal),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                  dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
                });
              }
            }

            // Fonction pour sélectionner une heure
            Future<void> _selectTime(BuildContext context) async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: selectedTime,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: Colors.teal),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != selectedTime) {
                setState(() {
                  selectedTime = picked;
                  timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            }
            
            return AlertDialog(
              title: Text('Programmer un rendez-vous'),
              content: Container(
                width: double.maxFinite,  // Définit une largeur maximale
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ilot.nom,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(ilot.adresse),
                      SizedBox(height: 20),
                      
                      // Champ de date
                      TextField(
                        controller: dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      SizedBox(height: 16),
                      
                      // Champ d'heure
                      TextField(
                        controller: timeController,
                        decoration: InputDecoration(
                          labelText: 'Heure',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectTime(context),
                      ),
                      SizedBox(height: 20),
                      
                      // Liste des participants amis
                      Text(
                        'Inviter des amis:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      
                      // Affichage des amis avec gestion correcte de l'état
                      isLoadingFriends
                        ? Container(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : allFriends.isEmpty
                          ? Container(
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(
                                child: Text(
                                  'Aucun ami à inviter.\nAjoutez des amis depuis la page "Mes Amis".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,  // Ajouter cette propriété
                                physics: ClampingScrollPhysics(),  // Ajouter cette propriété pour un meilleur comportement de défilement
                                itemCount: allFriends.length,
                                itemBuilder: (context, index) {
                                  final friend = allFriends[index];
                                  bool isSelected = selectedParticipants.contains(friend['id']);
                                  
                                  return CheckboxListTile(
                                    title: Text('${friend['prenom']} ${friend['nom']}'),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          if (!selectedParticipants.contains(friend['id'])) {
                                            selectedParticipants.add(friend['id']);
                                          }
                                        } else {
                                          selectedParticipants.remove(friend['id']);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () async {
                    if (dateController.text.isEmpty || timeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Veuillez saisir une date et une heure')),
                      );
                      return;
                    }
                    
                    // Combiner la date et l'heure
                    final dateStr = dateController.text;
                    final timeStr = timeController.text;
                    final day = int.parse(dateStr.split('/')[0]);
                    final month = int.parse(dateStr.split('/')[1]);
                    final year = int.parse(dateStr.split('/')[2]);
                    final hour = int.parse(timeStr.split(':')[0]);
                    final minute = int.parse(timeStr.split(':')[1]);
                    
                    final dateTime = DateTime(year, month, day, hour, minute);
                    
                    // Vérifier si l'utilisateur est connecté
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vous devez être connecté pour programmer un rendez-vous')),
                      );
                      Navigator.pop(context);
                      return;
                    }
                    
                    // Créer le rendez-vous dans Firestore
                    try {
                      await FirebaseFirestore.instance.collection('rendezvous').add({
                        'ilotId': ilot.nom,
                        'ilotNom': ilot.nom,
                        'ilotAdresse': ilot.adresse,
                        'date': Timestamp.fromDate(dateTime),
                        'userId': user.uid,
                        'participants': selectedParticipants,
                        'location': GeoPoint(ilot.latitude, ilot.longitude),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rendez-vous programmé avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la programmation du rendez-vous: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Programmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Ilot>> fetchIlots() async {
    final url = Uri.parse(
      'https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/ilots-de-fraicheur-espaces-verts-frais/records?limit=50',
    );

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
      throw Exception('Erreur lors de la récupération des données');
    }
  }

  // Afficher la page des rendez-vous
  void _showMesRendezVous() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MesRendezVousPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carte des îlots de fraîcheur'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Carte des îlots de fraîcheur'),
          backgroundColor: Colors.teal,
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des îlots de fraîcheur'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          // Bouton "Mes RDV" positionné en bas à droite
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _showMesRendezVous,
              label: Text('Mes RDV'),
              icon: Icon(Icons.event),
              backgroundColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}

// Page pour afficher les rendez-vous de l'utilisateur
class MesRendezVousPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes rendez-vous'),
        backgroundColor: Colors.teal,
      ),
      body: user == null
          ? Center(child: Text('Vous devez être connecté pour voir vos rendez-vous'))
          : SafeArea(
              child: Column(
                children: [
                  // Message d'information sur l'index
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      color: Colors.yellow[100],
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Très important !
                          children: [
                            Text(
                              "Attention: Vous devez créer un index dans Firebase pour que la liste des rendez-vous fonctionne correctement.",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Suivez le lien dans le message d'erreur de la console pour créer l'index nécessaire.",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Le reste utilise Expanded pour donner une taille définie au ListView
                  Expanded(
                    child: _buildRendezVousList(user),
                  ),
                ],
              ),
            ),
    );
  }

  // Extraction du code du StreamBuilder dans une méthode séparée pour plus de clarté
  Widget _buildRendezVousList(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rendezvous')
          .where('userId', isEqualTo: user.uid)
          // Commentez temporairement le orderBy jusqu'à ce que l'index soit créé
          // .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Pour résoudre ce problème, vous devez créer un index dans Firebase. Suivez le lien fourni dans la console pour le faire.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Aucun rendez-vous programmé'));
        }
        
        // Trier les documents manuellement par date
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final dateA = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
          final dateB = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
          return dateA.compareTo(dateB);
        });
        
        return ListView.builder(
          physics: AlwaysScrollableScrollPhysics(), // Important pour éviter des problèmes de défilement
          padding: EdgeInsets.symmetric(vertical: 4.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final ilotNom = data['ilotNom'] ?? 'Lieu inconnu';
            final ilotAdresse = data['ilotAdresse'] ?? '';
            
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: ListTile(
                title: Text(
                  ilotNom,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ilotAdresse),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14),
                        SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy à HH:mm').format(date),
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmerSuppressionRdv(context, doc.id),
                ),
                onTap: () {
                  // Afficher les détails du rendez-vous
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildRendezVousDetails(context, data, doc.id),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Méthode pour confirmer la suppression d'un rendez-vous
  Future<void> _confirmerSuppressionRdv(BuildContext context, String rdvId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ce rendez-vous ?'),
        content: Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('rendezvous').doc(rdvId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rendez-vous supprimé')),
      );
    }
  }

  Widget _buildRendezVousDetails(BuildContext context, Map<String, dynamic> data, String rdvId) {
    final date = (data['date'] as Timestamp).toDate();
    final participants = data['participants'] as List<dynamic>;
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['ilotNom'] ?? 'Lieu inconnu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          SizedBox(height: 8),
          Text(data['ilotAdresse'] ?? ''),
          Divider(),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                DateFormat('EEEE dd MMMM yyyy à HH:mm', 'fr_FR').format(date),
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Participants:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          participants.isEmpty
              ? Text('Aucun participant')
              : FutureBuilder<List<Map<String, String>>>(
                  future: _fetchParticipantsInfo(participants.cast<String>()),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }
                    return Column(
                      children: snapshot.data!.map((user) {
                        return ListTile(
                          leading: Icon(Icons.person),
                          title: Text(user['name'] ?? 'Utilisateur inconnu'),
                          dense: true,
                        );
                      }).toList(),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<List<Map<String, String>>> _fetchParticipantsInfo(List<String> participantIds) async {
    try {
      final results = await Future.wait(
        participantIds.map((id) async {
          final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
          if (!doc.exists) return {'id': id, 'name': 'Utilisateur inconnu'};
          final data = doc.data();
          return {
            'id': id,
            'name': '${data?['prenom'] ?? ''} ${data?['nom'] ?? ''}',
          };
        }),
      );
      return results;
    } catch (e) {
      print('Erreur lors de la récupération des participants: $e');
      return participantIds.map((id) => {'id': id, 'name': 'Utilisateur inconnu'}).toList();
    }
  }
}