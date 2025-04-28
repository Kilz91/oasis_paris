import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../auth/login_page.dart';
import 'dart:async';
import '../../services/profile_service.dart';
import '../../widgets/profile/action_button.dart';
import '../../widgets/profile/profile_info_card.dart';
import '../../widgets/profile/form_field.dart';

class ProfilPage extends StatefulWidget {
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Charger les données utilisateur depuis Firestore
  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final data = await _profileService.getUserData();
      if (mounted) {
        setState(() {
          userData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _profileService.currentUser;

    if (user == null) return _buildNotConnected(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mon Profil', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Profil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage:
                    user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : AssetImage('assets/profil.png') as ImageProvider,
              ),
              SizedBox(height: 24),
              // Afficher uniquement le nom et prénom
              Text(
                '${userData?['prenom'] ?? 'Prénom'} ${userData?['nom'] ?? 'Nom'}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ActionButton(
                text: 'Mon Compte',
                color: const Color.fromRGBO(0, 150, 136, 1),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountDetailsPage(userData: userData),
                    ),
                  ).then((_) => _loadUserData());
                },
              ),
              SizedBox(height: 16),
              ActionButton(
                text: 'Se déconnecter',
                color: Colors.redAccent,
                onPressed: () async {
                  await _profileService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginPage(title: 'Oasis Paris'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotConnected(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Vous devez être connecté pour voir votre profil.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ActionButton(
              text: 'Se connecter',
              color: Colors.deepPurple,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(title: 'Oasis Paris'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AccountDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AccountDetailsPage({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  late TextEditingController _nomController;
  late TextEditingController _prenomController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.userData?['nom'] ?? '');
    _prenomController = TextEditingController(text: widget.userData?['prenom'] ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _profileService.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Mon Compte')),
        body: Center(child: Text('Vous devez être connecté pour voir cette page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Compte', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section photo de profil
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _getImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : AssetImage('assets/profil.png') as ImageProvider),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.teal,
                            radius: 25,
                            child: Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Changer ma photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Informations personnelles
            ProfileInfoCard(
              title: 'Informations personnelles',
              children: [
                ProfileFormField(
                  controller: _prenomController,
                  label: 'Prénom',
                ),
                SizedBox(height: 16),
                ProfileFormField(
                  controller: _nomController,
                  label: 'Nom',
                ),
                SizedBox(height: 24),
                ActionButton(
                  text: 'Enregistrer',
                  color: Colors.teal,
                  onPressed: () => _updateProfile(context),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Informations de connexion
            ProfileInfoCard(
              title: 'Informations de connexion',
              children: [
                ProfileInfoRow(
                  label: 'Email',
                  value: user.email ?? 'Non défini',
                ),
                widget.userData?['pendingEmail'] != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Email en attente de vérification: ${widget.userData?['pendingEmail']}',
                          style: TextStyle(color: Colors.orange),
                        ),
                      )
                    : SizedBox.shrink(),
                SizedBox(height: 16),
                ProfileInfoRow(
                  label: 'Téléphone',
                  value: widget.userData?['telephone'] ?? 'Non défini',
                ),
                SizedBox(height: 24),
                ActionButton(
                  text: 'Changer mon email',
                  color: Colors.blue,
                  onPressed: () => _showEmailChangeDialog(context),
                ),
                SizedBox(height: 16),
                ActionButton(
                  text: 'Changer mon téléphone',
                  color: Colors.blue,
                  onPressed: () => _showPhoneChangeDialog(context),
                ),
                SizedBox(height: 16),
                ActionButton(
                  text: 'Changer mon mot de passe',
                  color: Colors.blue,
                  onPressed: () => _showPasswordChangeDialog(context),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Gestion du compte
            ProfileInfoCard(
              title: 'Gestion du compte',
              children: [
                ActionButton(
                  text: 'Supprimer mon compte',
                  color: Colors.red,
                  onPressed: () => _showDeleteAccountDialog(context),
                ),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Mettre à jour les informations du profil
  Future<void> _updateProfile(BuildContext context) async {
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();

    if (nom.isEmpty || prenom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final success = await _profileService.updateProfile(
      nom: nom,
      prenom: prenom,
      imageFile: _profileImage,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du profil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Afficher le dialogue de changement d'email
  void _showEmailChangeDialog(BuildContext context) {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();

    // Afficher le dialogue avec les champs de saisie
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer mon email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileFormField(
              controller: newEmailController,
              label: 'Nouvel email',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            ProfileFormField(
              controller: passwordController,
              label: 'Mot de passe actuel',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final result = await _profileService.changeEmail(
                password: passwordController.text,
                newEmail: newEmailController.text,
              );

              Navigator.pop(context);

              if (result['success']) {
                _showVerificationEmailSentDialog(context, result['newEmail']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Une erreur est survenue'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Changer'),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue de vérification d'email
  void _showVerificationEmailSentDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email de vérification envoyé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Un email de vérification a été envoyé à $email. '
                'Veuillez cliquer sur le lien pour confirmer votre nouvelle adresse email.'),
            SizedBox(height: 16),
            Text('Vous n\'avez pas reçu l\'email ?',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final success = await _profileService.resendEmailVerification(email);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Email de vérification renvoyé'
                      : 'Erreur lors de l\'envoi de l\'email'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text('Renvoyer l\'email'),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue de changement de numéro de téléphone
  void _showPhoneChangeDialog(BuildContext context) {
    final newPhoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer mon téléphone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileFormField(
              controller: newPhoneController,
              label: 'Nouveau téléphone',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            ProfileFormField(
              controller: passwordController,
              label: 'Mot de passe actuel',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final success = await _profileService.changePhoneNumber(
                password: passwordController.text,
                newPhone: newPhoneController.text,
              );
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Numéro de téléphone mis à jour avec succès'
                      : 'Erreur lors de la mise à jour du téléphone'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text('Changer'),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue de changement de mot de passe
  void _showPasswordChangeDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer mon mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileFormField(
              controller: currentPasswordController,
              label: 'Mot de passe actuel',
              obscureText: true,
            ),
            SizedBox(height: 16),
            ProfileFormField(
              controller: newPasswordController,
              label: 'Nouveau mot de passe',
              obscureText: true,
            ),
            SizedBox(height: 16),
            ProfileFormField(
              controller: confirmPasswordController,
              label: 'Confirmer le nouveau mot de passe',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              // Vérifier que les nouveaux mots de passe correspondent
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Vérifier que le nouveau mot de passe est assez long
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Le mot de passe doit contenir au moins 6 caractères'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final result = await _profileService.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );

              Navigator.pop(context);

              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Mot de passe changé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Une erreur est survenue'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Changer'),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue de suppression de compte
  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer mon compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attention ! Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ProfileFormField(
              controller: passwordController,
              label: 'Mot de passe',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final result = await _profileService.deleteAccount(passwordController.text);
              
              if (result['success']) {
                Navigator.pop(context);  // Fermer la boîte de dialogue
                
                // Rediriger vers la page de connexion
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage(title: 'Oasis Paris')),
                  (route) => false,
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Une erreur est survenue'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
