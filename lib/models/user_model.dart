import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? photoURL;
  final List<String> friends;
  final Timestamp? createdAt;
  final Timestamp? lastLogin;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.photoURL,
    List<String>? friends,
    this.createdAt,
    this.lastLogin,
    this.settings,
  }) : friends = friends ?? [];

  // Getter pour le nom complet
  String get displayName => '$firstName $lastName'.trim();

  // Factory pour créer un UserModel à partir des données Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      firstName: map['prenom'] ?? '',
      lastName: map['nom'] ?? '',
      phoneNumber: map['telephone'],
      photoURL: map['photoURL'],
      friends: List<String>.from(map['friends'] ?? []),
      createdAt: map['createdAt'] as Timestamp?,
      lastLogin: map['lastLogin'] as Timestamp?,
      settings: map['settings'] as Map<String, dynamic>?,
    );
  }

  // Convertir le modèle en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'prenom': firstName,
      'nom': lastName,
      'telephone': phoneNumber,
      'photoURL': photoURL,
      'friends': friends,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastLogin': lastLogin ?? FieldValue.serverTimestamp(),
      'settings': settings ?? {},
    };
  }

  // Créer une copie du modèle avec des valeurs modifiées
  UserModel copyWith({
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoURL,
    List<String>? friends,
    Timestamp? lastLogin,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      friends: friends ?? List.from(this.friends),
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      settings: settings ?? (this.settings != null ? Map.from(this.settings!) : null),
    );
  }
}