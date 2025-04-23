import 'package:flutter/material.dart';

/// Cette classe permet de capturer et d'utiliser un BuildContext de manière sécurisée,
/// même après que le widget a été désactivé ou supprimé de l'arbre.
///
/// Utilisez cette classe pour stocker une référence au contexte que vous pourriez
/// utiliser plus tard dans des opérations asynchrones ou des callbacks.
class SafeContext {
  BuildContext? _context;
  
  /// Capture le contexte actuel pour une utilisation ultérieure.
  void capture(BuildContext context) {
    _context = context;
  }
  
  /// Libère la référence au contexte.
  void release() {
    _context = null;
  }
  
  /// Exécute une action avec le contexte s'il est toujours valide.
  /// Retourne true si l'action a pu être exécutée, false sinon.
  bool run(void Function(BuildContext context) action) {
    final ctx = _context;
    if (ctx != null && _isContextValid(ctx)) {
      action(ctx);
      return true;
    }
    return false;
  }
  
  /// Exécute une action avec le contexte s'il est toujours valide.
  /// Retourne le résultat de l'action ou null si le contexte n'est pas valide.
  T? runWithResult<T>(T Function(BuildContext context) action) {
    final ctx = _context;
    if (ctx != null && _isContextValid(ctx)) {
      return action(ctx);
    }
    return null;
  }
  
  /// Vérifie si le contexte est encore valide (monté dans l'arbre).
  bool _isContextValid(BuildContext context) {
    try {
      // Si le widget n'est plus monté, cela lèvera une exception
      return context.mounted;
    } catch (e) {
      return false;
    }
  }
  
  /// Renvoie true si un contexte est actuellement capturé et semble valide.
  bool get hasValidContext {
    final ctx = _context;
    return ctx != null && _isContextValid(ctx);
  }
  
  /// Méthode pratique pour afficher un SnackBar en toute sécurité.
  void showSnackBar(SnackBar snackBar) {
    run((context) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }
  
  /// Méthode pratique pour naviguer en arrière en toute sécurité.
  bool pop<T>([T? result]) {
    return runWithResult((context) {
      Navigator.of(context).pop(result);
      return true;
    }) ?? false;
  }
  
  /// Méthode pratique pour naviguer vers une nouvelle route en toute sécurité.
  bool push(Route route) {
    return runWithResult((context) {
      Navigator.of(context).push(route);
      return true;
    }) ?? false;
  }
  
  /// Méthode pratique pour naviguer vers une nouvelle route nommée en toute sécurité.
  bool pushNamed(String routeName, {Object? arguments}) {
    return runWithResult((context) {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
      return true;
    }) ?? false;
  }
  
  /// Méthode pratique pour remplacer la route actuelle en toute sécurité.
  bool pushReplacement(Route route) {
    return runWithResult((context) {
      Navigator.of(context).pushReplacement(route);
      return true;
    }) ?? false;
  }
  
  /// Méthode pratique pour accéder à Theme.of(context) en toute sécurité.
  ThemeData? getTheme() {
    return runWithResult((context) => Theme.of(context));
  }
  
  /// Méthode pratique pour accéder à MediaQuery.of(context) en toute sécurité.
  MediaQueryData? getMediaQuery() {
    return runWithResult((context) => MediaQuery.of(context));
  }
}