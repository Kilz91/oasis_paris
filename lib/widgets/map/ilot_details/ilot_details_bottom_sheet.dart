import 'package:flutter/material.dart';
import 'package:oasis_paris/models/ilot_model.dart';

class IlotDetailsBottomSheet extends StatelessWidget {
  final Ilot ilot;
  final Function(Ilot) onProgrammerRendezVous;

  const IlotDetailsBottomSheet({
    Key? key,
    required this.ilot,
    required this.onProgrammerRendezVous,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                onProgrammerRendezVous(ilot);
              },
            ),
          ),
        ],
      ),
    );
  }
}