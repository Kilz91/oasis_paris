import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class InvitationList extends StatelessWidget {
  final User user;
  final Function(String, String, bool) onRepondreInvitation;

  const InvitationList({
    Key? key,
    required this.user,
    required this.onRepondreInvitation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                          onPressed: () => onRepondreInvitation(doc.id, user.uid, false),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          child: Text('Accepter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () => onRepondreInvitation(doc.id, user.uid, true),
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
}