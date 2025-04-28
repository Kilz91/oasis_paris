import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../auth/login_page.dart';
import 'dart:async'; // Ajout de cet import pour StreamSubscription

class ProfilPage extends StatefulWidget {
  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Charger les données utilisateur depuis Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          setState(() {
            userData = doc.data();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } catch (e) {
        print('Erreur lors du chargement des données utilisateur: $e');
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
              _buildButton('Mon Compte', Colors.teal, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountDetailsPage(userData: userData),
                  ),
                ).then(
                  (_) => _loadUserData(),
                ); // Recharger les données après modification
              }),
              SizedBox(height: 16),
              _buildButton('Se déconnecter', Colors.redAccent, () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(title: 'Oasis Paris'),
                  ),
                );
              }),
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
            _buildButton('Se connecter', Colors.deepPurple, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginPage(title: 'Oasis Paris'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  EditProfilePage({this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  String _error = '';

  // Stocker une référence au contexte de navigation qui est sûre à utiliser
  late BuildContext _safeContext;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = widget.userData?['nom'] ?? user?.displayName ?? '';
    _prenomCtrl.text = widget.userData?['prenom'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    _safeContext = context;
    
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier le profil',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageFile != null
                        ? FileImage(_imageFile!)
                        : (user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : AssetImage('assets/profil.png') as ImageProvider),
              ),
              SizedBox(height: 16),
              _buildButton(
                'Changer la photo de profil',
                Colors.grey,
                _pickImage,
              ),
              SizedBox(height: 24),
              _buildField(_nameCtrl, 'Nom'),
              SizedBox(height: 16),
              _buildField(_prenomCtrl, 'Prénom'),
              SizedBox(height: 24),
              _buildButton(
                'Enregistrer les modifications',
                Colors.blue,
                _updateProfile,
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error, style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _error = '');

    if (user == null) {
      setState(() => _error = 'Aucun utilisateur connecté.');
      return;
    }

    try {
      if (_nameCtrl.text.isNotEmpty) {
        await user.updateDisplayName(_nameCtrl.text);
      }

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_pictures/${user.uid}.png',
        );
        final url = await (await ref.putFile(_imageFile!)).ref.getDownloadURL();
        await user.updatePhotoURL(url);
      }

      // Mettre à jour les données dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'nom': _nameCtrl.text,
            'prenom': _prenomCtrl.text,
          });

      // Recharger l'utilisateur pour s'assurer que nous avons les informations les plus récentes
      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(_safeContext).showSnackBar(
          SnackBar(
            content: Text(
              'Profil mis à jour avec succès.',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
        
        Navigator.pop(_safeContext);
      }

    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur : ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _prenomCtrl.dispose();
    super.dispose();
  }
}

class AccountDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  AccountDetailsPage({this.userData});

  @override
  _AccountDetailsPageState createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> with WidgetsBindingObserver {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final _passwordController = TextEditingController();
  String _error = '';
  bool _showDeleteConfirm = false;

  @override
  void initState() {
    super.initState();
    // Ajouter l'observer pour détecter quand l'app revient au premier plan
    WidgetsBinding.instance.addObserver(this);
    userData = widget.userData;
    isLoading = false;
    
    // Charger les données immédiatement si le widget est monté
    if (mounted) {
      _loadUserData();
    }
    
    // Utiliser une variable pour stocker la référence à l'écouteur afin de pouvoir l'annuler plus tard
    _authStateListener = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        _loadUserData(); // Recharger les données quand l'état d'authentification change
      }
    });
  }
  
  // Stocke la référence à l'écouteur
  StreamSubscription<User?>? _authStateListener;
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recharger les données quand l'app revient au premier plan, seulement si le widget est monté
    if (state == AppLifecycleState.resumed && mounted) {
      _loadUserData();
    }
  }
  
  @override
  void dispose() {
    // Annuler l'écouteur pour éviter les callbacks après démontage
    _authStateListener?.cancel();
    _authStateListener = null;
    
    WidgetsBinding.instance.removeObserver(this);
    _passwordController.dispose();
    super.dispose();
  }

  // Méthode améliorée pour charger les données utilisateur avec une vérification du montage
  Future<void> _loadUserData() async {
    // Vérifier si le widget est toujours monté avant de continuer
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && mounted) {
        // Forcer le rechargement de l'utilisateur pour avoir les données les plus récentes
        await user.reload();
        
        // Vérifier à nouveau si le widget est monté après l'opération asynchrone
        if (!mounted) return;
        
        final freshUser = FirebaseAuth.instance.currentUser;
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        // Vérifier encore une fois si le widget est monté après l'opération asynchrone
        if (!mounted) return;
            
        if (doc.exists) {
          // Mise à jour explicite de l'email dans Firestore
          if (freshUser != null && freshUser.email != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'email': freshUser.email});
          }
          
          // Vérifier une dernière fois si le widget est monté avant de récupérer les données
          if (!mounted) return;
          
          // Récupérer à nouveau les données après la mise à jour
          final updatedDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          // Vérifier si le widget est toujours monté avant de mettre à jour l'état
          if (!mounted) return;
          
          setState(() {
            userData = updatedDoc.data();
            
            // S'assurer que l'email est toujours à jour
            if (userData != null && freshUser?.email != null) {
              userData!['email'] = freshUser!.email;
              print("Email mis à jour dans l'UI: ${freshUser.email}");
            }
            
            isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() => isLoading = false);
        }
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
      // Vérifier si le widget est toujours monté avant de mettre à jour l'état
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mon Compte', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Text('Aucun utilisateur connecté'),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mon Compte', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Compte', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage:
                    user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : AssetImage('assets/profil.png') as ImageProvider,
              ),
            ),
            SizedBox(height: 24),
            _buildInfoCard('Informations personnelles', [
              _buildInfoRow('Nom', userData?['nom'] ?? 'Non renseigné'),
              _buildInfoRow('Prénom', userData?['prenom'] ?? 'Non renseigné'),
              _buildInfoRow('Email', userData?['email'] ?? user.email ?? 'Email non disponible'),
              _buildInfoRow('Téléphone', userData?['telephone'] ?? 'Non renseigné'),
            ]),
            SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  _buildButton('Modifier mon profil', Colors.teal, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(userData: userData),
                      ),
                    ).then((_) => setState(() {}));
                  }),
                  SizedBox(height: 16),
                  _buildButton('Modifier mon email', Colors.blue, () {
                    _showEmailChangeDialog(context);
                  }),
                  SizedBox(height: 16),
                  _buildButton('Modifier mon numéro de téléphone', Colors.green, () {
                    _showPhoneChangeDialog(context);
                  }),
                  SizedBox(height: 16),
                  _buildButton('Modifier mon mot de passe', Colors.blue, () {
                    _showPasswordChangeDialog(context);
                  }),
                  SizedBox(height: 16),
                  _buildButton('Supprimer mon compte', Colors.red, () {
                    setState(() => _showDeleteConfirm = true);
                  }),
                  if (_showDeleteConfirm) ...[
                    SizedBox(height: 24),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Attention ! Cette action est irréversible.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pour confirmer la suppression, entrez votre mot de passe :',
                              style: TextStyle(color: Colors.black),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showDeleteConfirm = false;
                                      _passwordController.clear();
                                      _error = '';
                                    });
                                  },
                                  child: Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: _deleteAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text(
                                    'Confirmer la suppression',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            if (_error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  _error,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
  
  void _showPasswordChangeDialog(BuildContext context) {
    final _currentPasswordCtrl = TextEditingController();
    final _newPasswordCtrl = TextEditingController();
    final _confirmPasswordCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier mon mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                );
                return;
              }
              
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  // Réauthentifier l'utilisateur
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: _currentPasswordCtrl.text,
                  );
                  await user.reauthenticateWithCredential(cred);
                  
                  // Changer le mot de passe
                  await user.updatePassword(_newPasswordCtrl.text);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mot de passe modifié avec succès')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text('Modifier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Méthode complètement refaite pour la modification d'email
  void _showEmailChangeDialog(BuildContext context) {
    // Contrôleurs pour les champs de texte
    final currentPasswordController = TextEditingController();
    final newEmailController = TextEditingController();
    
    // Variable pour stocker les messages d'erreur
    String errorMessage = '';
    
    // Récupération de l'utilisateur actuel
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      newEmailController.text = currentUser.email ?? '';
    }
    
    // Fonction pour gérer la tentative de changement d'email
    Future<void> handleEmailChange(Function setDialogState) async {
      // Vérifications préliminaires
      if (currentPasswordController.text.isEmpty) {
        setDialogState(() {
          errorMessage = 'Veuillez entrer votre mot de passe actuel';
        });
        return;
      }
      
      if (newEmailController.text == currentUser?.email) {
        setDialogState(() {
          errorMessage = 'Le nouvel email est identique à l\'email actuel';
        });
        return;
      }
      
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmailController.text)) {
        setDialogState(() {
          errorMessage = 'Veuillez entrer un email valide';
        });
        return;
      }
      
      // Vérifier si l'utilisateur est toujours connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setDialogState(() {
          errorMessage = 'Vous n\'êtes plus connecté';
        });
        return;
      }
      
      try {
        // Stocker les emails pour référence
        final String oldEmail = user.email ?? '';
        final String newEmail = newEmailController.text;
        
        // Réauthentifier l'utilisateur
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPasswordController.text,
        );
        await user.reauthenticateWithCredential(cred);
        
        // Mettre à jour les données dans Firestore
        await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'pendingEmail': newEmail,
            'emailVerificationRequested': true,
          });
        
        // Envoyer l'email de vérification
        await user.verifyBeforeUpdateEmail(newEmail);
        
        // Fermer la boîte de dialogue de changement d'email
        Navigator.pop(context);
        
        // Afficher le dialogue d'information
        showVerificationDialog(context, oldEmail, newEmail);
      } catch (e) {
        setDialogState(() {
          errorMessage = 'Erreur: ${e.toString()}';
        });
      }
    }
    
    // Afficher la boîte de dialogue
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modifier mon email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Nouvel email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Pour des raisons de sécurité, un email de vérification sera envoyé à votre nouvelle adresse.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                if (errorMessage.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => handleEmailChange(setDialogState),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Envoyer vérification', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  // Méthode séparée pour afficher le dialogue de vérification
  void showVerificationDialog(BuildContext context, String oldEmail, String newEmail) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Vérification requise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nous avons envoyé un email de vérification à $newEmail'
            ),
            SizedBox(height: 16),
            Text(
              'Étapes à suivre :'
            ),
            SizedBox(height: 8),
            Text(
              '1. Ouvrez l\'email envoyé à $newEmail',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '2. Cliquez sur le lien "Vérifier mon adresse email"',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '3. Une fois vérifié, votre email sera mis à jour automatiquement',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text(
              'Important : Votre adresse email restera $oldEmail jusqu\'à la vérification complète.',
              style: TextStyle(color: Colors.blue[800]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Veuillez vérifier $newEmail pour confirmer le changement'),
                  duration: Duration(seconds: 5),
                ),
              );
            },
            child: Text('Compris'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await user.verifyBeforeUpdateEmail(newEmail);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Un nouvel email de vérification a été envoyé à $newEmail')),
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                );
              }
            },
            child: Text('Renvoyer l\'email'),
          ),
        ],
      ),
    );
  }

  void _showPhoneChangeDialog(BuildContext context) {
    final _currentPasswordCtrl = TextEditingController();
    final _newPhoneCtrl = TextEditingController();
    
    _newPhoneCtrl.text = userData?['telephone'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier mon numéro de téléphone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nouveau numéro de téléphone',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _currentPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_currentPasswordCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Veuillez entrer votre mot de passe actuel')),
                );
                return;
              }
              
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  // Réauthentifier l'utilisateur
                  final cred = EmailAuthProvider.credential(
                    email: user.email!,
                    password: _currentPasswordCtrl.text,
                  );
                  await user.reauthenticateWithCredential(cred);
                  
                  // Mettre à jour les données dans Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                        'telephone': _newPhoneCtrl.text,
                      });
                  
                  setState(() {
                    if (userData != null) {
                      userData!['telephone'] = _newPhoneCtrl.text;
                    }
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Numéro de téléphone modifié avec succès.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text('Modifier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _error = '');
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      setState(() => _error = 'Aucun utilisateur connecté.');
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Veuillez entrer votre mot de passe pour confirmer.');
      return;
    }
    
    try {
      // Réauthentifier l'utilisateur
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(cred);
      
      // Supprimer les données utilisateur de Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      
      // Supprimer le compte
      await user.delete();
      
      // Rediriger vers la page de connexion
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(title: 'Oasis Paris'),
        ),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Votre compte a été supprimé')),
      );
    } catch (e) {
      setState(() => _error = 'Erreur : ${e.toString()}');
    }
  }
}
