class ValidationUtils {
  // Validation des emails
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer une adresse email';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }
    
    return null;
  }
  
  // Validation des mots de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Le mot de passe doit contenir au moins un caractère spécial';
    }
    
    return null;
  }
  
  // Validation des numéros de téléphone (format français)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un numéro de téléphone';
    }
    
    // Format français (peut être adapté selon les besoins)
    final phoneRegex = RegExp(r'^(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]*\d{2}){4}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Veuillez entrer un numéro de téléphone valide';
    }
    
    return null;
  }
  
  // Validation des champs texte obligatoires
  static String? validateRequired(String? value, {String field = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$field est obligatoire';
    }
    return null;
  }
  
  // Validation de la correspondance de deux champs (utile pour confirmation de mot de passe)
  static String? validateMatch(String? value1, String? value2, {String message = 'Les champs ne correspondent pas'}) {
    if (value1 != value2) {
      return message;
    }
    return null;
  }
  
  // Validation de la longueur minimale
  static String? validateMinLength(String? value, int minLength, {String field = 'Ce champ'}) {
    if (value == null || value.length < minLength) {
      return '$field doit contenir au moins $minLength caractères';
    }
    return null;
  }
  
  // Validation de la longueur maximale
  static String? validateMaxLength(String? value, int maxLength, {String field = 'Ce champ'}) {
    if (value != null && value.length > maxLength) {
      return '$field ne doit pas dépasser $maxLength caractères';
    }
    return null;
  }
}