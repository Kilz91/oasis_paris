import 'package:flutter/material.dart';

import 'package:badges/badges.dart' as badges;

// Import des services
import 'services/friend_service.dart';

// Import des widgets
import 'widgets/widget_friend/friends_list.dart';
import 'widgets/widget_friend/sent_requests_list.dart';
import 'widgets/widget_friend/friend_requests_dialog.dart';
import 'widgets/widget_friend/add_friend_dialog.dart';
import 'widgets/widget_friend/empty_friends_state.dart';

class FriendPage extends StatefulWidget {
  @override
  _FriendPageState createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  late BuildContext _safeContext;
  bool isLoading = true;
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> friendRequests = []; 
  List<Map<String, dynamic>> sentRequests = [];
  final FriendService _friendService = FriendService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Charger toutes les données nécessaires
  Future<void> _loadAllData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedFriends = await _friendService.loadFriends();
      final loadedRequests = await _friendService.loadFriendRequests();
      final loadedSentRequests = await _friendService.loadSentRequests();

      setState(() {
        friends = loadedFriends;
        friendRequests = loadedRequests;
        sentRequests = loadedSentRequests;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Charger les données des amis
  Future<void> loadFriendData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // Récupération des données
      
      if (mounted) {
        setState(() {
          // Mettre à jour l'état avec les données chargées
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des amis: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Accepter un ami
  Future<void> accepterAmi(String userId) async {
    try {
      // Votre code pour accepter l'ami
      
      // Au lieu de:
      // ScaffoldMessenger.of(context).showSnackBar(...);
      
      // Utilisez:
      if (mounted) {
        ScaffoldMessenger.of(_safeContext).showSnackBar(
          SnackBar(content: Text('Ami accepté avec succès')),
        );
      }
      
      // Puis chargez les données à nouveau:
      if (mounted) {
        setState(() {
          // Mettre à jour l'état
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(_safeContext).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }
  // Afficher la popup des demandes d'amis
  void _showFriendRequestsDialog() {
    showDialog(
      context: context,
      builder: (context) => FriendRequestsDialog(
        friendRequests: friendRequests,
        refreshCallback: _loadAllData,
      ),
    );
  }

  // Afficher la popup d'ajout d'ami
  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AddFriendDialog(
        refreshCallback: _loadAllData,
        friends: friends,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _safeContext = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Amis', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: badges.Badge(
              position: badges.BadgePosition.topEnd(top: 5, end: 0),
              showBadge: friendRequests.isNotEmpty,
              badgeContent: Text(
                friendRequests.length.toString(),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(5),
              ),
              child: IconButton(
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: _showFriendRequestsDialog,
                tooltip: 'Demandes d\'amis',
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAddFriendDialog,
                      icon: Icon(Icons.person_add),
                      label: Text('Ajouter un ami'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    // Affichage des demandes d'amis envoyées
                    if (sentRequests.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Demandes envoyées',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      SentRequestsList(
                        sentRequests: sentRequests,
                        refreshCallback: _loadAllData,
                      ),
                    ],
                    
                    SizedBox(height: 16),
                    Text(
                      'Mes amis',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: friends.isEmpty && sentRequests.isEmpty
                          ? EmptyFriendsState()
                          : FriendsList(
                              friends: friends,
                              refreshCallback: _loadAllData,
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}