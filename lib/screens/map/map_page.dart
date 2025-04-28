import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/ilot_model.dart';
import '../../services/friend_service.dart';
import '../../services/notification_service.dart';

// Classe permettant de naviguer vers la carte avec un îlot présélectionné
class MapPageWithSelectedIlot extends StatefulWidget {
  final Ilot selectedIlot;

  const MapPageWithSelectedIlot({
    Key? key, 
    required this.selectedIlot,
  }) : super(key: key);

  @override
  State<MapPageWithSelectedIlot> createState() => _MapPageWithSelectedIlotState();
}

class _MapPageWithSelectedIlotState extends State<MapPageWithSelectedIlot> {
  final Completer<GoogleMapController> _controller = Completer();
  final FriendService _friendService = FriendService();
  final NotificationService _notificationService = NotificationService();
  
  // Position qui sera centrée sur l'îlot sélectionné
  late CameraPosition _initialPosition;
  
  Set<Marker> _markers = {};
  Map<String, Ilot> _ilotsMap = {};
  bool _isLoading = true;
  String _error = '';
  late BitmapDescriptor _markerIcon;
  late BitmapDescriptor _selectedMarkerIcon;

  @override
  void initState() {
    super.initState();
    // Initialiser la position de la caméra avec l'îlot sélectionné
    _initialPosition = CameraPosition(
      target: LatLng(widget.selectedIlot.latitude, widget.selectedIlot.longitude),
      zoom: 15.0, // Zoom plus proche pour bien voir l'îlot sélectionné
    );
    _setCustomMarkerIcons();
    _fetchIlots();
  }
  
  Future<void> _setCustomMarkerIcons() async {
    _markerIcon = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _selectedMarkerIcon = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
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
      
      // Vérifier que le widget est toujours monté avant d'appeler setState
      if (mounted) {
        setState(() {
          _ilotsMap = ilotsMap;
          _markers = _createMarkers(ilots);
          _isLoading = false;
        });
        
        // Sélectionner l'îlot passé en paramètre immédiatement
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showIlotDetails(widget.selectedIlot);
        });
      }
    } catch (e) {
      // Vérifier que le widget est toujours monté avant d'appeler setState
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des données: $e';
          _isLoading = false;
        });
      }
    }
  }

  Set<Marker> _createMarkers(List<Ilot> ilots) {
    return ilots.map((ilot) {
      // Ne créez un marqueur que si les coordonnées sont valides
      if (ilot.latitude != 0.0 && ilot.longitude != 0.0) {
        // Utiliser une icône différente pour l'îlot sélectionné
        final isSelected = ilot.nom == widget.selectedIlot.nom;
        
        return Marker(
          markerId: MarkerId(ilot.nom),
          position: LatLng(ilot.latitude, ilot.longitude),
          infoWindow: InfoWindow(
            title: ilot.nom,
            snippet: ilot.adresse.isNotEmpty ? ilot.adresse : 'Îlot de fraîcheur',
          ),
          icon: isSelected ? _selectedMarkerIcon : _markerIcon,
          onTap: () {
            _showIlotDetails(ilot);
          },
          // Animer si c'est l'îlot sélectionné
          zIndex: isSelected ? 2 : 1,
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
            
            // Affichage du type d'îlot
            if (ilot.type.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.category, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Type: ${ilot.type}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Affichage des heures d'ouverture ou ouverture nocturne
            if (ilot.heuresOuverture.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      ilot.heuresOuverture == 'Ouvert la nuit' 
                        ? Icons.nightlight_round 
                        : Icons.access_time,
                      color: Colors.teal
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ilot.heuresOuverture == 'Ouvert la nuit'
                            ? "Ouvert la nuit"
                            : "Horaires: ${ilot.heuresOuverture}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            
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
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
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
                      // Créer le document du rendez-vous
                      final docRef = await FirebaseFirestore.instance.collection('rendezvous').add({
                        'ilotId': ilot.nom,
                        'ilotNom': ilot.nom,
                        'ilotAdresse': ilot.adresse,
                        'date': Timestamp.fromDate(dateTime),
                        'userId': user.uid,
                        'organizerName': user.displayName ?? 'Utilisateur',
                        'participants': selectedParticipants,
                        'acceptedParticipants': [], // Nouvelle liste pour les participants qui ont accepté
                        'location': GeoPoint(ilot.latitude, ilot.longitude),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      
                      // Envoyer une notification à chaque participant
                      for (String participantId in selectedParticipants) {
                        await _notificationService.createRdvInvitation(
                          rdvId: docRef.id,
                          recipientId: participantId,
                          rdvName: ilot.nom,
                          rdvDate: dateTime,
                        );
                      }
                      
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

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final FriendService _friendService = FriendService();
  final NotificationService _notificationService = NotificationService();
  
  // Position centrée sur Paris
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(48.856614, 2.3522219),
    zoom: 12.0,
  );
  
  Set<Marker> _markers = {};
  Map<String, Ilot> _ilotsMap = {};
  bool _isLoading = true;
  String _error = '';
  Map<String, BitmapDescriptor> _markerIcons = {};
  final Map<String, Color> _typeColors = {
    'jardin': Colors.green,
    'parc': Colors.teal,
    'square': Colors.lightGreen,
    'cimetière': Colors.blueGrey,
    'bois': Colors.brown,
    'eau': Colors.blue,
    'fontaine': Colors.lightBlue,
    'espace': Colors.teal,
    'promenade': Colors.lime,
    'terrain': Colors.amber,
  };
  BitmapDescriptor _defaultMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcons();
    _fetchIlots();
  }
  
  Future<void> _setCustomMarkerIcons() async {
    // Créer des icônes différentes pour chaque type d'îlot
    _defaultMarkerIcon = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    
    // Définir des couleurs pour les types d'îlots courants
    _markerIcons['jardin'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _markerIcons['parc'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _markerIcons['square'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    _markerIcons['cimetière'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    _markerIcons['bois'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _markerIcons['fontaine'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    _markerIcons['promenade'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    _markerIcons['inconnu'] = await BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
  }
  
  // Fonction pour obtenir l'icône correspondant à un type d'îlot
  BitmapDescriptor _getMarkerIcon(String type) {
    if (type.isEmpty) {
      return _defaultMarkerIcon;
    }
    
    // Déterminer le type principal de l'îlot à partir de son nom
    String typeKey = 'inconnu';
    type = type.toLowerCase();
    
    for (String key in _markerIcons.keys) {
      if (type.contains(key)) {
        typeKey = key;
        break;
      }
    }
    
    return _markerIcons[typeKey] ?? _defaultMarkerIcon;
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
      
      // Vérifier que le widget est toujours monté avant d'appeler setState
      if (mounted) {
        setState(() {
          _ilotsMap = ilotsMap;
          _markers = _createMarkers(ilots);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Vérifier que le widget est toujours monté avant d'appeler setState
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des données: $e';
          _isLoading = false;
        });
      }
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
          icon: _getMarkerIcon(ilot.type),
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
            
            // Affichage du type d'îlot
            if (ilot.type.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.category, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Type: ${ilot.type}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Affichage des heures d'ouverture ou ouverture nocturne
            if (ilot.heuresOuverture.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      ilot.heuresOuverture == 'Ouvert la nuit' 
                        ? Icons.nightlight_round 
                        : Icons.access_time,
                      color: Colors.teal
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ilot.heuresOuverture == 'Ouvert la nuit'
                            ? "Ouvert la nuit"
                            : "Horaires: ${ilot.heuresOuverture}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            
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
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
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
                      // Créer le document du rendez-vous
                      final docRef = await FirebaseFirestore.instance.collection('rendezvous').add({
                        'ilotId': ilot.nom,
                        'ilotNom': ilot.nom,
                        'ilotAdresse': ilot.adresse,
                        'date': Timestamp.fromDate(dateTime),
                        'userId': user.uid,
                        'organizerName': user.displayName ?? 'Utilisateur',
                        'participants': selectedParticipants,
                        'acceptedParticipants': [], // Nouvelle liste pour les participants qui ont accepté
                        'location': GeoPoint(ilot.latitude, ilot.longitude),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      
                      // Envoyer une notification à chaque participant
                      for (String participantId in selectedParticipants) {
                        await _notificationService.createRdvInvitation(
                          rdvId: docRef.id,
                          recipientId: participantId,
                          rdvName: ilot.nom,
                          rdvDate: dateTime,
                        );
                      }
                      
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

class MesRendezVousPage extends StatefulWidget {
  @override
  _MesRendezVousPageState createState() => _MesRendezVousPageState();
}

class _MesRendezVousPageState extends State<MesRendezVousPage>
    with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes rendez-vous'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Mes rendez-vous'),
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      body: user == null
          ? Center(child: Text('Vous devez être connecté pour voir vos rendez-vous'))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Mes rendez-vous créés ou acceptés
                _buildRendezVousList(user),
                // Tab 2: Invitations en attente
                _buildInvitations(user),
              ],
            ),
    );
  }

  Widget _buildRendezVousList(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rendezvous')
          .where(Filter.or(
            Filter('userId', isEqualTo: user.uid),
            Filter('acceptedParticipants', arrayContains: user.uid)
          ))
          .orderBy('date')
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
                ],
              ),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Aucun rendez-vous confirmé'));
        }
        
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final dateA = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
          final dateB = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
          return dateA.compareTo(dateB);
        });
        
        return ListView.builder(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 4.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final ilotNom = data['ilotNom'] ?? 'Lieu inconnu';
            final ilotAdresse = data['ilotAdresse'] ?? '';
            
            // Gérer les participants qu'ils soient stockés comme Liste ou comme Map
            List<String> participantsList = [];
            if (data['participants'] is List) {
              participantsList = (data['participants'] as List<dynamic>).map((p) => p.toString()).toList();
            } else if (data['participants'] is Map) {
              participantsList = (data['participants'] as Map).keys.map((k) => k.toString()).toList();
            }
            
            // Gérer les participants acceptés
            List<String> acceptedParticipantsList = [];
            if (data['acceptedParticipants'] is List) {
              acceptedParticipantsList = (data['acceptedParticipants'] as List<dynamic>).map((p) => p.toString()).toList();
            }
            
            final isOrganizer = data['userId'] == user.uid;
            
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ilotNom,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isOrganizer)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Créateur',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
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
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '${_countAcceptedParticipants(participantsList, acceptedParticipantsList)} participant${_countAcceptedParticipants(participantsList, acceptedParticipantsList) > 1 ? "s" : ""}',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton pour modifier les participants (uniquement pour l'organisateur)
                    IconButton(
                      icon: Icon(Icons.person_add, color: Colors.teal),
                      tooltip: isOrganizer ? 'Gérer les participants' : 'Proposer un participant',
                      onPressed: () => isOrganizer 
                        ? _modifierParticipants(context, doc.id, data)
                        : _proposerParticipant(context, doc.id, data),
                    ),
                    // Bouton pour supprimer le rendez-vous (uniquement pour l'organisateur)
                    if (isOrganizer)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Supprimer le rendez-vous',
                        onPressed: () => _confirmerSuppressionRdv(context, doc.id),
                      ),
                  ],
                ),
                onTap: () => _showRendezVousDetails(context, doc.id, data, user.uid),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvitations(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rendezvous')
          .where('participants', arrayContains: user.uid)
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}', style: TextStyle(color: Colors.red)),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Aucune invitation en attente'));
        }
        
        // Filter documents to only include pending invitations
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final acceptedParticipants = data['acceptedParticipants'] as List<dynamic>? ?? [];
          
          // Only show invitations where the user is in participants but not in acceptedParticipants
          return !acceptedParticipants.contains(user.uid);
        }).toList();
        
        if (docs.isEmpty) {
          return Center(child: Text('Aucune invitation en attente'));
        }
        
        docs.sort((a, b) {
          final dateA = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
          final dateB = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
          return dateA.compareTo(dateB);
        });
        
        return ListView.builder(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 4.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final ilotNom = data['ilotNom'] ?? 'Lieu inconnu';
            final creatorId = data['userId'];
            
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitation à un rendez-vous',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      ilotNom,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(creatorId).get(),
                      builder: (context, snapshot) {
                        final creatorName = snapshot.hasData && snapshot.data!.exists 
                            ? '${snapshot.data!.get('prenom')} ${snapshot.data!.get('nom')}'
                            : 'Un utilisateur';
                        return Text('Invité par $creatorName');
                      }
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 4),
                        Text(DateFormat('dd/MM/yyyy à HH:mm').format(date)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          child: Text('Refuser'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _repondreInvitation(doc.id, user.uid, false),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          child: Text('Accepter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () => _repondreInvitation(doc.id, user.uid, true),
                        ),
                      ],
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

  // Méthode pour répondre à une invitation
  Future<void> _repondreInvitation(String rdvId, String userId, bool accept) async {
    try {
      final rdvRef = FirebaseFirestore.instance.collection('rendezvous').doc(rdvId);
      
      if (accept) {
        // Si l'utilisateur accepte, mettre à jour son statut et l'ajouter à la liste des participants acceptés
        await rdvRef.update({
          'participants.$userId': 'accepted',
          'acceptedParticipants': FieldValue.arrayUnion([userId])
        });
        
        // Récupérer les données du rendez-vous pour envoyer une notification
        final rdvDoc = await rdvRef.get();
        if (rdvDoc.exists) {
          final rdvData = rdvDoc.data() as Map<String, dynamic>;
          final organizerId = rdvData['userId'] as String;
          final rdvName = rdvData['ilotNom'] as String;
          
          // Envoyer une notification d'acceptation à l'organisateur
          await _notificationService.createRdvAcceptanceNotification(
            rdvId: rdvId,
            rdvName: rdvName,
            organizerId: organizerId,
          );
        }
      } else {
        // Si l'utilisateur refuse, mettre à jour son statut à "declined"
        await rdvRef.update({
          'participants.$userId': 'declined'
        });
      }
        
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Invitation acceptée' : 'Invitation refusée'),
          backgroundColor: accept ? Colors.green : null,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour confirmer qu'on veut quitter un rendez-vous
  Future<void> _confirmerQuitterRdv(BuildContext context, String rdvId, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quitter ce rendez-vous ?'),
        content: Text('Vous ne pourrez plus y accéder après l\'avoir quitté.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Quitter'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        // Mettre à jour le statut à "declined"
        await FirebaseFirestore.instance
          .collection('rendezvous')
          .doc(rdvId)
          .update({
            'participants.$userId': 'declined'
          });
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous avez quitté le rendez-vous')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Méthode pour proposer un ami au créateur du rendez-vous
  Future<void> _proposerParticipant(BuildContext context, String rdvId, Map<String, dynamic> rdvData) async {
    final organizerId = rdvData['userId'] as String;
    final rdvName = rdvData['ilotNom'] as String;
    List<Map<String, dynamic>> allFriends = [];
    String? selectedFriendId;
    String selectedFriendName = '';
    bool isLoading = true;

    // Dialog pour choisir un ami à proposer
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            
            // Charger la liste des amis
            if (isLoading) {
              _friendService.loadFriends().then((friends) {
                setState(() {
                  // Filtrer pour exclure les participants déjà invités
                  final List<dynamic> currentParticipants = rdvData['participants'] ?? [];
                  allFriends = friends.where((friend) => 
                    !currentParticipants.contains(friend['id'])
                  ).toList();
                  isLoading = false;
                });
              }).catchError((error) {
                print('Erreur lors du chargement des amis: $error');
                setState(() {
                  allFriends = [];
                  isLoading = false;
                });
              });
            }

            return AlertDialog(
              title: Text('Proposer un participant'),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choisissez un ami à proposer:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      isLoading
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
                                  'Aucun ami disponible à proposer.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          : Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: ClampingScrollPhysics(),
                                itemCount: allFriends.length,
                                itemBuilder: (context, index) {
                                  final friend = allFriends[index];
                                  return RadioListTile<String>(
                                    title: Text('${friend['prenom']} ${friend['nom']}'),
                                    value: friend['id'],
                                    groupValue: selectedFriendId,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedFriendId = value;
                                        if (value != null) {
                                          final selectedFriend = allFriends.firstWhere(
                                            (f) => f['id'] == value,
                                            orElse: () => {'prenom': '', 'nom': ''},
                                          );
                                          selectedFriendName = '${selectedFriend['prenom']} ${selectedFriend['nom']}';
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
                  onPressed: selectedFriendId == null ? null : () async {
                    try {
                      // Envoyer une notification à l'organisateur pour proposer un nouveau participant
                      await _notificationService.createParticipantRequest(
                        rdvId: rdvId,
                        rdvName: rdvName,
                        organizerId: organizerId,
                        newParticipantId: selectedFriendId!,
                        newParticipantName: selectedFriendName,
                      );
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Proposition envoyée à l\'organisateur'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Proposer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Méthode pour gérer les participants (réservée au créateur)
  Future<void> _modifierParticipants(BuildContext context, String rdvId, Map<String, dynamic> rdvData) async {
    // Récupérer les données des participants
    Map<String, dynamic> participants;
    List<String> participantIds = [];
    List<dynamic> acceptedParticipants = rdvData['acceptedParticipants'] as List<dynamic>? ?? [];
    
    // Gérer les différents formats de 'participants' possibles
    if (rdvData['participants'] is List) {
      // Si participants est une List, convertir en Map avec statut 'pending'
      List<dynamic> participantsList = rdvData['participants'] as List<dynamic>;
      participants = {};
      for (var id in participantsList) {
        participants[id] = 'pending';
        participantIds.add(id.toString());
      }
    } else if (rdvData['participants'] is Map) {
      // Si participants est déjà une Map
      participants = Map<String, dynamic>.from(rdvData['participants']);
      participantIds = participants.keys.toList().cast<String>();
    } else {
      // Initialiser comme Map vide si non défini
      participants = {};
      participantIds = [];
    }
    
    List<Map<String, dynamic>> allFriends = [];
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (isLoading) {
              _friendService.loadFriends().then((friends) {
                setState(() {
                  allFriends = friends;
                  isLoading = false;
                });
              }).catchError((error) {
                print('Erreur lors du chargement des amis: $error');
                setState(() {
                  allFriends = [];
                  isLoading = false;
                });
              });
            }

            return AlertDialog(
              title: Text('Gérer les participants'),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participants actuels:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      isLoading
                        ? Center(child: CircularProgressIndicator())
                        : participantIds.isEmpty
                          ? Text('Aucun participant')
                          : Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: participantIds.length,
                                itemBuilder: (context, index) {
                                  final participantId = participantIds[index];
                                  final friend = allFriends.firstWhere(
                                    (f) => f['id'] == participantId,
                                    orElse: () => {'prenom': '', 'nom': 'Utilisateur inconnu'},
                                  );
                                  
                                  // Ne pas afficher le créateur dans la liste (il est automatiquement accepté)
                                  if (participantId == rdvData['creatorId'] || participantId == rdvData['userId']) {
                                    return SizedBox.shrink();
                                  }

                                  return ListTile(
                                    title: Text('${friend['prenom']} ${friend['nom']}'),
                                    subtitle: Text(_getStatusText(participants[participantId])),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check, color: Colors.green),
                                          onPressed: () {
                                            setState(() {
                                              participants[participantId] = 'accepted';
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              participants[participantId] = 'declined';
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                      SizedBox(height: 16),
                      Text(
                        'Ajouter de nouveaux participants:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      isLoading
                        ? Center(child: CircularProgressIndicator())
                        : Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: allFriends.length,
                              itemBuilder: (context, index) {
                                final friend = allFriends[index];
                                final friendId = friend['id'];
                                // Ne pas afficher les amis qui sont déjà participants
                                if (participantIds.contains(friendId)) {
                                  return SizedBox.shrink();
                                }
                                
                                return ListTile(
                                  title: Text('${friend['prenom']} ${friend['nom']}'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.add, color: Colors.teal),
                                    onPressed: () {
                                      setState(() {
                                        participants[friendId] = 'pending';
                                      });
                                    },
                                  ),
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
                    try {
                      await FirebaseFirestore.instance
                          .collection('rendezvous')
                          .doc(rdvId)
                          .update({'participants': participants, 'acceptedParticipants': acceptedParticipants});
                      
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Participants mis à jour'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Une erreur est survenue'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Méthode pour afficher les détails du rendez-vous
  void _showRendezVousDetails(BuildContext context, String rdvId, Map<String, dynamic> data, String userId) {
    final date = (data['date'] as Timestamp).toDate();
    
    // Gérer participants selon qu'il s'agit d'une liste ou d'une map
    List<String> participants = [];
    if (data['participants'] is List) {
      participants = (data['participants'] as List<dynamic>).map((p) => p.toString()).toList();
    } else if (data['participants'] is Map) {
      participants = (data['participants'] as Map).keys.map((k) => k.toString()).toList();
    }
    
    final acceptedParticipants = data['acceptedParticipants'] as List<dynamic>? ?? [];
    final isOrganizer = userId == (data['creatorId'] ?? data['userId']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                        width: 40,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['ilotNom'] ?? 'Lieu inconnu',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        if (isOrganizer)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Créateur',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                        SizedBox(width: 4),
                        Expanded(child: Text(data['ilotAdresse'] ?? '')),
                      ],
                    ),
                    Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          DateFormat('HH:mm', 'fr_FR').format(date),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Participants (${participants.length}):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Spacer(),
                        // Afficher le bouton "Modifier" seulement pour l'organisateur
                        if (isOrganizer)
                          TextButton.icon(
                            icon: Icon(Icons.edit, size: 16),
                            label: Text('Modifier'),
                            onPressed: () {
                              Navigator.pop(context);
                              _modifierParticipants(context, rdvId, data);
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    participants.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 32.0),
                          child: Text('Aucun participant'),
                        )
                      : FutureBuilder<List<Map<String, String>>>(
                          future: _fetchParticipantsInfo(participants.cast<String>()),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            return Card(
                              elevation: 0,
                              color: Colors.grey[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  children: snapshot.data!.map((user) {
                                    bool hasAccepted = acceptedParticipants.contains(user['id']);
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: hasAccepted ? Colors.teal : Colors.grey,
                                        child: Icon(Icons.person, color: Colors.white),
                                      ),
                                      title: Text(user['name'] ?? 'Utilisateur inconnu'),
                                      trailing: hasAccepted 
                                        ? Icon(Icons.check_circle, color: Colors.teal)
                                        : Icon(Icons.hourglass_empty, color: Colors.orange),
                                      subtitle: Text(hasAccepted ? 'A accepté' : 'En attente'),
                                      dense: true,
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                    
                    // Afficher le bouton "Proposer un participant" pour les participants non-organisateurs
                    if (!isOrganizer)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.person_add),
                            label: Text('Proposer un participant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _proposerParticipant(context, rdvId, data);
                            },
                          ),
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

  // Obtenir la couleur en fonction du statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Obtenir le texte en fonction du statut
  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'A confirmé sa présence';
      case 'pending':
        return 'En attente de réponse';
      case 'declined':
        return 'A décliné l\'invitation';
      default:
        return 'Statut inconnu';
    }
  }

  // Compter les participants qui ont accepté
  int _countAcceptedParticipants(List<dynamic> participants, List<dynamic> acceptedParticipants) {
    int count = 0;
    
    // Compter dans la liste acceptedParticipants
    if (acceptedParticipants.isNotEmpty) {
      count = acceptedParticipants.length;
    } 
    
    // Ajouter le créateur qui est toujours considéré comme participant
    count += 1;
    
    return count;
  }

  Future<List<Map<String, String>>> _fetchParticipantsInfo(List<String> participantIds) async {
    List<Map<String, String>> participantsInfo = [];

    for (String id in participantIds) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (userDoc.exists) {
          String name = '${userDoc['prenom']} ${userDoc['nom']}';
          participantsInfo.add({'id': id, 'name': name});
        }
      } catch (e) {
        print('Erreur lors de la récupération de l\'utilisateur $id: $e');
      }
    }

    return participantsInfo;
  }
}