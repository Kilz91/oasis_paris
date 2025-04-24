import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat.dart';

class FriendsForChatPage extends StatefulWidget {
  @override
  _FriendsForChatPageState createState() => _FriendsForChatPageState();
}

class _FriendsForChatPageState extends State<FriendsForChatPage> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  // Fonction pour charger les amis
  Future<void> _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final List friendIds = userDoc.data()?['friends'] ?? [];

      List<Map<String, dynamic>> loadedFriends = [];

      for (String id in List<String>.from(friendIds)) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          loadedFriends.add({
            'id': id,
            'name': '${doc['prenom'] ?? ''} ${doc['nom'] ?? ''}'.trim(),
            'firstLetter': '${doc['prenom']?.substring(0, 1)}',
          });
        }
      }

      if (mounted) {
        setState(() {
          friends = loadedFriends;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des amis: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mes messages")),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : friends.isEmpty
              ? Center(
                child: Text(
                  "Aucun ami trouvé",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.separated(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatPage(
                                friendId: friend['id'],
                                friendName: friend['name'],
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              friend['firstLetter'],
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Text(
                            friend['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return Divider(
                    color: Colors.grey[300],
                    thickness: 1,
                    indent: 70, // Pour ne pas chevaucher l'avatar
                  );
                },
              ),
    );
  }
}
