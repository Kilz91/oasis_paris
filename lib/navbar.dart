import 'package:flutter/material.dart';
import 'package:oasis_paris/profil.dart';

class NavbarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Navigation Bar"),
        backgroundColor: Colors.teal,
      ),
      body: Center(child: Text("Bienvenue dans la navbar page")),
      bottomNavigationBar: BottomNavigationBar(
        type:
            BottomNavigationBarType
                .fixed, // Assure-toi que les icônes sont alignées horizontalement
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
        ],
        onTap: (index) {
          switch (index) {
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilPage()),
              );
              break;
            // Pas de navigation pour les autres éléments pour l'instant
          }
        },
      ),
    );
  }
}
