import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io' show Platform;
import '../firebase_options.dart';
import 'auth_service.dart';

class FirebaseService {
  static final AuthService _authService = AuthService();
  
  // Initialiser Firebase et autres services
  static Future<void> initialize() async {
    try {
      // Initialisation de Firebase avec les options spécifiques à la plateforme
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configuration du gestionnaire d'email verification
      _authService.configureEmailVerificationHandler();

      // Activation de Firebase App Check avec configuration spécifique par plateforme
      FirebaseAppCheck instance = FirebaseAppCheck.instance;
      if (Platform.isIOS || Platform.isMacOS) {
        // Pour iOS et macOS, utiliser le provider DeviceCheck
        await instance.activate(
          appleProvider: AppleProvider.appAttest,
          // En mode debug, vous pouvez utiliser AppleProvider.debug
          // appleProvider: AppleProvider.debug,
        );
      } else {
        // Pour Android et autres plateformes
        await instance.activate();
      }
      instance.setTokenAutoRefreshEnabled(true); // Rafraîchissement automatique activé
      
      // Initialisation des données de formatage de date pour la locale française
      await initializeDateFormatting('fr_FR', null);
    } catch (e) {
      print('Erreur lors de l\'initialisation de Firebase ou des données de localisation : $e');
    }
  }
}