class Ilot {
  final String nom;
  final double latitude;
  final double longitude;
  final String adresse; // Ajout du champ adresse

  Ilot({
    required this.nom,
    required this.latitude,
    required this.longitude,
    this.adresse = '', // Valeur par défaut vide
  });

  factory Ilot.fromJson(Map<String, dynamic> json) {
    // Récupérer le nom et l'adresse de l'espace vert
    final nom = json['nom'] ?? 'Nom inconnu';
    final adresse = json['adresse'] ?? ''; // Récupérer l'adresse depuis JSON
    final geoShape = json['geo_shape'];

    print('---');
    print('Nom: $nom');
    print('Adresse: $adresse'); // Imprimer l'adresse pour vérifier
    print(
      'GeoShape: $geoShape',
    ); // Imprimer le geoShape complet pour vérifier son contenu

    // Vérification si 'geo_shape' existe et est un Map
    if (geoShape != null && geoShape is Map<String, dynamic>) {
      final geometry = geoShape['geometry'];
      print(
        'Geometry: $geometry',
      ); // Imprimer la geometry pour vérifier son contenu

      // Vérification si 'geometry' existe et est un Map
      if (geometry != null && geometry is Map<String, dynamic>) {
        final coordinates = geometry['coordinates'];
        final type = geometry['type'];

        print(
          'Coordinates: $coordinates',
        ); // Imprimer les coordinates pour les vérifier
        print('Type: $type'); // Imprimer le type pour le débogage

        dynamic firstCoord;

        // Cas pour MultiPolygon
        if (type == 'MultiPolygon' &&
            coordinates is List &&
            coordinates.isNotEmpty) {
          final firstPolygon = coordinates[0];
          if (firstPolygon is List && firstPolygon.isNotEmpty) {
            firstCoord = firstPolygon[0];
          }
        }
        // Cas pour Polygon
        else if (type == 'Polygon' &&
            coordinates is List &&
            coordinates.isNotEmpty) {
          firstCoord = coordinates[0][0];
        }

        print('FirstCoord: $firstCoord'); // Imprimer firstCoord pour vérifier

        // Si 'firstCoord' est valide
        if (firstCoord is List && firstCoord.length == 2) {
          final lon = firstCoord[0];
          final lat = firstCoord[1];

          // Vérification du type de données pour les coordonnées
          if (lon is num && lat is num) {
            print(
              'Position valide: Lon = $lon, Lat = $lat',
            ); // Imprimer la position
            return Ilot(
              nom: nom,
              longitude: lon.toDouble(),
              latitude: lat.toDouble(),
              adresse: adresse,
            );
          } else {
            print('Les coordonnées ne sont pas valides.');
          }
        }
      }
    }

    // Si la géométrie ou les coordonnées sont invalides
    print('Retour par défaut avec coordonnées 0.0, 0.0');
    return Ilot(nom: nom, latitude: 0.0, longitude: 0.0, adresse: adresse);
  }
}
