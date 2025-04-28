import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RendezVousList extends StatelessWidget {
  final User user;
  final Function(String, Map<String, dynamic>, String) onShowDetails;
  final Function(String, Map<String, dynamic>) onManageParticipants;
  final Function(String, Map<String, dynamic>) onProposeParticipant;
  final Function(BuildContext, String) onDeleteRdv;

  const RendezVousList({
    Key? key,
    required this.user,
    required this.onShowDetails,
    required this.onManageParticipants,
    required this.onProposeParticipant,
    required this.onDeleteRdv,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    // Bouton pour modifier les participants (selon le rôle)
                    IconButton(
                      icon: Icon(Icons.person_add, color: Colors.teal),
                      tooltip: isOrganizer ? 'Gérer les participants' : 'Proposer un participant',
                      onPressed: () => isOrganizer 
                        ? onManageParticipants(doc.id, data)
                        : onProposeParticipant(doc.id, data),
                    ),
                    // Bouton pour supprimer le rendez-vous (uniquement pour l'organisateur)
                    if (isOrganizer)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Supprimer le rendez-vous',
                        onPressed: () => onDeleteRdv(context, doc.id),
                      ),
                  ],
                ),
                onTap: () => onShowDetails(doc.id, data, user.uid),
              ),
            );
          },
        );
      },
    );
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
}