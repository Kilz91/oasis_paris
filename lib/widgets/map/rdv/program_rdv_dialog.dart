import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/ilot_model.dart';
import '../../../services/friend_service.dart';
import '../../../services/notification_service.dart';

class ProgramRdvDialog extends StatefulWidget {
  final Ilot ilot;
  
  const ProgramRdvDialog({
    Key? key,
    required this.ilot,
  }) : super(key: key);

  @override
  State<ProgramRdvDialog> createState() => _ProgramRdvDialogState();
}

class _ProgramRdvDialogState extends State<ProgramRdvDialog> {
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<String> selectedParticipants = [];
  List<Map<String, dynamic>> allFriends = [];
  bool isLoadingFriends = true;
  
  final FriendService _friendService = FriendService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }
  
  Future<void> _loadFriends() async {
    try {
      final friends = await _friendService.loadFriends();
      if (mounted) {
        setState(() {
          allFriends = friends;
          isLoadingFriends = false;
        });
      }
    } catch (error) {
      print('Erreur lors du chargement des amis: $error');
      if (mounted) {
        setState(() {
          allFriends = [];
          isLoadingFriends = false;
        });
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Programmer un rendez-vous'),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.ilot.nom,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(widget.ilot.adresse),
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
              
              _buildFriendsList(),
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
          onPressed: _createRendezVous,
          child: Text('Programmer'),
        ),
      ],
    );
  }

  Widget _buildFriendsList() {
    if (isLoadingFriends) {
      return Container(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (allFriends.isEmpty) {
      return Container(
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
      );
    }
    
    return Container(
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
    );
  }

  Future<void> _createRendezVous() async {
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
        'ilotId': widget.ilot.nom,
        'ilotNom': widget.ilot.nom,
        'ilotAdresse': widget.ilot.adresse,
        'date': Timestamp.fromDate(dateTime),
        'userId': user.uid,
        'organizerName': user.displayName ?? 'Utilisateur',
        'participants': selectedParticipants,
        'acceptedParticipants': [], // Nouvelle liste pour les participants qui ont accepté
        'location': GeoPoint(widget.ilot.latitude, widget.ilot.longitude),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Envoyer une notification à chaque participant
      for (String participantId in selectedParticipants) {
        await _notificationService.createRdvInvitation(
          rdvId: docRef.id,
          recipientId: participantId,
          rdvName: widget.ilot.nom,
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
  }
  
  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }
}