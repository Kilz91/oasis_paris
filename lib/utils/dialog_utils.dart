import 'package:flutter/material.dart';
import '../widgets/profile/form_field.dart';

class DialogUtils {
  // Afficher un dialogue de confirmation simple
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Afficher un dialogue avec un formulaire à un champ
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    String? initialValue,
    String label = '',
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color confirmColor = Colors.teal,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);
    
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: ProfileFormField(
          controller: controller,
          label: label,
          obscureText: obscureText,
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result;
  }

  // Afficher une notification toast (snackbar)
  static void showToast({
    required BuildContext context,
    required String message,
    bool isError = false,
    int durationSeconds = 3,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  // Afficher un dialogue de formulaire personnalisé
  static Future<Map<String, dynamic>?> showFormDialog({
    required BuildContext context,
    required String title,
    required List<FormField> fields,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color confirmColor = Colors.teal,
    String? warningText,
  }) async {
    final formData = <String, dynamic>{};
    final controllers = <String, TextEditingController>{};
    
    // Créer les contrôleurs pour chaque champ
    for (var field in fields) {
      controllers[field.key] = TextEditingController(text: field.initialValue);
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (warningText != null) ...[
                Text(
                  warningText,
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 16),
              ],
              ...fields.map((field) {
                return Column(
                  children: [
                    ProfileFormField(
                      controller: controllers[field.key]!,
                      label: field.label,
                      obscureText: field.isPassword,
                      keyboardType: field.keyboardType,
                    ),
                    SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () {
              // Collecter les valeurs des champs
              for (var field in fields) {
                formData[field.key] = controllers[field.key]!.text;
              }
              Navigator.pop(context, true);
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    // Nettoyer les contrôleurs
    controllers.values.forEach((controller) => controller.dispose());
    
    // Retourner les données si le dialogue a été confirmé
    return result == true ? formData : null;
  }
}

// Classe pour définir un champ de formulaire
class FormField {
  final String key;
  final String label;
  final String? initialValue;
  final bool isPassword;
  final TextInputType keyboardType;

  FormField({
    required this.key,
    required this.label,
    this.initialValue,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  // Champ pour adresse email
  static FormField email({
    String key = 'email',
    String label = 'Email',
    String? initialValue,
  }) {
    return FormField(
      key: key,
      label: label,
      initialValue: initialValue,
      keyboardType: TextInputType.emailAddress,
    );
  }

  // Champ pour mot de passe
  static FormField password({
    String key = 'password',
    String label = 'Mot de passe',
    String? initialValue,
  }) {
    return FormField(
      key: key,
      label: label,
      initialValue: initialValue,
      isPassword: true,
    );
  }

  // Champ pour numéro de téléphone
  static FormField phone({
    String key = 'phone',
    String label = 'Téléphone',
    String? initialValue,
  }) {
    return FormField(
      key: key,
      label: label,
      initialValue: initialValue,
      keyboardType: TextInputType.phone,
    );
  }
}