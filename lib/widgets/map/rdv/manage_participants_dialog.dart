import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/friend_service.dart';

class ManageParticipantsDialog extends StatefulWidget {
  final String rdvId;
  final Map<String, dynamic> rdvData;

  const ManageParticipantsDialog({
    Key? key,
    required this.rdvId,
    required this.rdvData,
  }) : super(key: key);

  @override
  State<ManageParticipantsDialog> createState() => _ManageParticipantsDialogState();
}

class _ManageParticipantsDialogState extends State<ManageParticipantsDialog> {
  late Map<String, dynamic> participants;
  late List<String> participantIds;
  late List<dynamic> acceptedParticipants;
  List<Map<String, dynamic>> allFriends = [];
  bool isLoading = true;
  
  final FriendService _friendService = FriendService();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadFriends();
  }
  
  void _initializeData() {
    // Récupérer les données des participants
    acceptedParticipants = widget.rdvData['acceptedParticipants'] as List<dynamic>? ?? [];
    
    // Gérer les différents formats de 'participants' possibles
    if (widget.rdvData['participants'] is List) {
      // Si participants est une List, convertir en Map avec statut 'pending'
      List<dynamic> participantsList = widget.rdvData['participants'] as List<dynamic>;
      participants = {};
      participantIds = [];
      for (var id in participantsList) {
        participants[id] = 'pending';
        participantIds.add(id.toString());
      }
    } else if (widget.rdvData['participants'] is Map) {
      // Si participants est déjà une Map
      participants = Map<String, dynamic>.from(widget.rdvData['participants']);
      participantIds = participants.keys.toList().cast<String>();
    } else {
      // Initialiser comme Map vide si non défini
      participants = {};
      participantIds = [];
    }
  }
  
  Future<void> _loadFriends() async {
    try {
      final friendModels = await _friendService.loadFriends();
      if (mounted) {
        setState(() {
          // Convertir List<UserModel> en List<Map<String, dynamic>>
          allFriends = friendModels.map((user) => {
            'id': user.uid,
            'prenom': user.firstName,
            'nom': user.lastName,
            'email': user.email,
            'photoURL': user.photoURL,
          }).toList();
          isLoading = false;
        });
      }
    } catch (error) {
      print('Erreur lors du chargement des amis: $error');
      if (mounted) {
        setState(() {
          allFriends = [];
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildCurrentParticipantsList(),
              SizedBox(height: 16),
              Text(
                'Ajouter de nouveaux participants:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildAddParticipantsList(),
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
          onPressed: _saveChanges,
          child: Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _buildCurrentParticipantsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (participantIds.isEmpty) {
      return Text('Aucun participant');
    }
    
    return Container(
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
          if (participantId == widget.rdvData['creatorId'] || participantId == widget.rdvData['userId']) {
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
                      if (!acceptedParticipants.contains(participantId)) {
                        acceptedParticipants.add(participantId);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      participants[participantId] = 'declined';
                      acceptedParticipants.remove(participantId);
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddParticipantsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return Container(
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
                  participantIds.add(friendId);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('rendezvous')
          .doc(widget.rdvId)
          .update({
            'participants': participants, 
            'acceptedParticipants': acceptedParticipants
          });
      
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
}