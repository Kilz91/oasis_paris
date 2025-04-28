class AppConstants {
  // Textes de l'application
  static const String appName = 'Oasis Paris';
  
  // Constantes pour Firebase
  static const String usersCollection = 'users';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';
  static const String ilotsCollection = 'ilots';
  static const String notificationsCollection = 'notifications';
  static const String friendRequestsCollection = 'friendRequests';
  static const String rendezvousCollection = 'rendezvous';
  
  // Routes de l'application
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String mapRoute = '/map';
  static const String profileRoute = '/profile';
  static const String friendsRoute = '/friends';
  static const String chatRoute = '/chat';
  static const String notificationsRoute = '/notifications';
  
  // Valeurs par défaut
  static const int defaultMessageLimit = 50;
  static const String defaultUserImagePlaceholder = 'assets/default_user.png';
  static const double defaultMapZoom = 13.0;
  static const double defaultMarkerSize = 40.0;
  
  // Paris coordinates (centre de Paris)
  static const double parisCenterLatitude = 48.8566;
  static const double parisCenterLongitude = 2.3522;
  
  // Messages d'erreur
  static const String errorNoInternet = 'Pas de connexion Internet.';
  static const String errorGeneric = 'Une erreur est survenue. Veuillez réessayer.';
  static const String errorInvalidEmail = 'Adresse email invalide.';
  static const String errorInvalidPassword = 'Mot de passe invalide. Il doit contenir au moins 8 caractères, une majuscule, une minuscule et un chiffre.';
  static const String errorPasswordsDoNotMatch = 'Les mots de passe ne correspondent pas.';
  
  // Messages de succès
  static const String successRegistration = 'Inscription réussie !';
  static const String successPasswordReset = 'Un email de réinitialisation a été envoyé.';
  static const String successProfileUpdate = 'Profil mis à jour avec succès.';
}