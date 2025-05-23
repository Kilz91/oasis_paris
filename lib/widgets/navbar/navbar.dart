import 'package:flutter/material.dart';
import 'package:oasis_paris/screens/chat/chat.dart';
import 'package:oasis_paris/screens/profile/profil.dart';
import 'package:oasis_paris/screens/map/ilots_page.dart';
import 'package:oasis_paris/screens/friends/friend_page.dart';
import 'package:oasis_paris/screens/map/map_page.dart';
import 'package:oasis_paris/screens/friends/friends_for_chat.dart';

class NavbarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapPage(), // Utiliser directement la carte comme page d'accueil
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/map.png', width: 30, height: 30),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/recherche.png', width: 30, height: 30),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/reglages.png', width: 30, height: 30),
            label: 'Réglages',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/friends.png', width: 30, height: 30),
            label: 'Amis',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/chat.png', width: 30, height: 30),
            label: 'Messages',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Reste sur la page de carte (déjà affichée)
              break;
            case 1:
              // Navigation vers la page de liste des îlots
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IlotsPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FriendPage()),
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FriendsForChatPage()),
              );
              break;
          }
        },
      ),
    );
  }
}
