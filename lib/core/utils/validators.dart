class Validators {
  // Validation d'email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email);
  }

  // Validation de mot de passe (au moins 8 caractères, 1 lettre majuscule, 1 lettre minuscule, 1 chiffre)
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    
    return hasUppercase && hasLowercase && hasDigit;
  }

  // Validation de numéro de téléphone français
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(
      r'^(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]*\d{2}){4}$',
    );
    return phoneRegex.hasMatch(phone);
  }

  // Validation de texte non vide
  static bool isNotEmpty(String? text) {
    return text != null && text.trim().isNotEmpty;
  }

  // Validation de longueur minimale
  static bool hasMinLength(String? text, int minLength) {
    return text != null && text.length >= minLength;
  }

  // Validation de longueur maximale
  static bool hasMaxLength(String? text, int maxLength) {
    return text != null && text.length <= maxLength;
  }

  // Validation d'égalité entre deux chaînes (par exemple pour confirmation de mot de passe)
  static bool areEqual(String? value1, String? value2) {
    return value1 == value2;
  }
}