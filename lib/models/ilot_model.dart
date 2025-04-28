class Ilot {
  final String nom;
  final double latitude;
  final double longitude;
  final String adresse;
  final String type; // Type d'îlot (jardin, parc, etc.)
  final String heuresOuverture; // Heures d'ouverture ou indication nocturne

  Ilot({
    required this.nom,
    required this.latitude,
    required this.longitude,
    this.adresse = '',
    this.type = '', // Valeur par défaut vide
    this.heuresOuverture = '', // Valeur par défaut vide
  });

  factory Ilot.fromJson(Map<String, dynamic> json) {
    // Récupérer le nom et l'adresse de l'espace vert
    final nom = json['nom'] ?? 'Nom inconnu';
    final adresse = json['adresse'] ?? '';
    
    // Récupérer le type d'espace vert (jardin, parc, etc.)
    final ilotType = json['type'] ?? 'Type inconnu';
    
    // Construire les informations sur les heures d'ouverture
    String heuresOuverture = '';
    
    // Vérifier si l'îlot est ouvert 24h/24
    if (json['ouvert_24h'] == 'Oui') {
      heuresOuverture = 'Ouvert 24h/24';
    } 
    // Vérifier l'ouverture nocturne en été
    else if (json['ouverture_estivale_nocturne'] == 'Oui') {
      heuresOuverture = 'Ouvert la nuit en été';
    }
    // Si non, essayer de trouver les horaires spécifiques par jour
    else {
      List<String> jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
      Map<String, String?> horaires = {};
      bool hasHoraires = false;
      
      // Récupérer les horaires pour chaque jour
      for (String jour in jours) {
        String? horaire = json['horaires_$jour'];
        if (horaire != null && horaire.isNotEmpty) {
          horaires[jour] = horaire;
          hasHoraires = true;
        }
      }
      
      // S'il y a des horaires spécifiques, les formater
      if (hasHoraires) {
        List<String> horairesList = [];
        jours.forEach((jour) {
          if (horaires[jour] != null) {
            horairesList.add('$jour: ${horaires[jour]}');
          }
        });
        heuresOuverture = horairesList.join('\n');
      } 
      // Sinon vérifier s'il y a une période générale
      else if (json['horaires_periode'] != null && json['horaires_periode'].isNotEmpty) {
        heuresOuverture = json['horaires_periode'];
      }
      // Si pas d'information disponible
      else {
        heuresOuverture = 'Horaires non disponibles';
      }
    }
    
    print('---');
    print('Nom: $nom');
    print('Adresse: $adresse');
    print('Type d\'îlot: $ilotType');
    print('Heures d\'ouverture: $heuresOuverture');
    
    final geoShape = json['geo_shape'];
    
    // Extraction des coordonnées depuis geo_point_2d pour plus de précision
    if (json['geo_point_2d'] != null && json['geo_point_2d'] is Map) {
      final geoPoint = json['geo_point_2d'];
      final lat = geoPoint['lat'];
      final lon = geoPoint['lon'];
      
      if (lat is num && lon is num) {
        return Ilot(
          nom: nom,
          longitude: lon.toDouble(),
          latitude: lat.toDouble(),
          adresse: adresse,
          type: ilotType,
          heuresOuverture: heuresOuverture
        );
      }
    }
    
    // Si geo_point_2d n'est pas disponible, essayer avec geo_shape
    if (geoShape != null && geoShape is Map<String, dynamic>) {
      final geometry = geoShape['geometry'];
      
      if (geometry != null && geometry is Map<String, dynamic>) {
        final coordinates = geometry['coordinates'];
        final geoType = geometry['type']; // Renommé pour éviter la confusion

        dynamic firstCoord;

        if (geoType == 'MultiPolygon' &&
            coordinates is List &&
            coordinates.isNotEmpty) {
          final firstPolygon = coordinates[0];
          if (firstPolygon is List && firstPolygon.isNotEmpty) {
            firstCoord = firstPolygon[0][0]; // Ajustement pour prendre le premier point
          }
        }
        else if (geoType == 'Polygon' &&
            coordinates is List &&
            coordinates.isNotEmpty) {
          firstCoord = coordinates[0][0];
        }

        if (firstCoord is List && firstCoord.length >= 2) {
          final lon = firstCoord[0];
          final lat = firstCoord[1];

          if (lon is num && lat is num) {
            return Ilot(
              nom: nom,
              longitude: lon.toDouble(),
              latitude: lat.toDouble(),
              adresse: adresse,
              type: ilotType,
              heuresOuverture: heuresOuverture
            );
          }
        }
      }
    }

    // Si aucune coordonnée n'est valide
    return Ilot(
      nom: nom, 
      latitude: 0.0, 
      longitude: 0.0, 
      adresse: adresse,
      type: ilotType,
      heuresOuverture: heuresOuverture
    );
  }
}
