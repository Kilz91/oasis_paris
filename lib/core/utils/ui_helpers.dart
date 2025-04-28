import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UIHelpers {
  // Afficher une snackbar
  static void showSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    bool isSuccess = false,
    int durationInSeconds = 3,
  }) {
    final Color backgroundColor = isError
        ? AppTheme.errorColor
        : isSuccess
            ? AppTheme.successColor
            : AppTheme.textDark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: durationInSeconds),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTheme.spacingMedium),
      ),
    );
  }

  // Afficher une boîte de dialogue de confirmation
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // Afficher un indicateur de chargement
  static void showLoading(BuildContext context, {String message = 'Chargement en cours...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  // Masquer l'indicateur de chargement
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Vérifier si l'appareil est en mode sombre
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  // Obtenir la taille de l'écran
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // Obtenir la largeur de l'écran
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Obtenir la hauteur de l'écran
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Vérifier si l'appareil est un téléphone
  static bool isPhone(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide < 600;
  }

  // Vérifier si l'appareil est une tablette
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600;
  }
}