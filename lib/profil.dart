import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_page.dart';

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
                radius: 50,
                backgroundImage:
                    user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : AssetImage('assets/profil.png') as ImageProvider,
              ),
              SizedBox(height: 16),
              // Afficher les données de Firestore
              Text(
                'Nom: ${userData?['nom'] ?? 'Non renseigné'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Prénom: ${userData?['prenom'] ?? 'Non renseigné'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Email: ${userData?['email'] ?? user.email ?? 'Email non disponible'}',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              Text(
                'Téléphone: ${userData?['telephone'] ?? 'Non renseigné'}',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              SizedBox(height: 24),
              _buildButton('Modifier le profil', Colors.teal, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(userData: userData),
                  ),
                ).then(
                  (_) => _loadUserData(),
                ); // Recharger les données après la modification
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
  final _emailCtrl = TextEditingController();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  String _error = '';

  // Stocker une référence au contexte de navigation qui est sûre à utiliser
  // Cela évite d'essayer d'accéder à un widget ancêtre lorsque l'élément est déjà désactivé
  late BuildContext _context;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = widget.userData?['nom'] ?? user?.displayName ?? '';
    _prenomCtrl.text = widget.userData?['prenom'] ?? '';
    _emailCtrl.text = widget.userData?['email'] ?? user?.email ?? '';
    _phoneCtrl.text = widget.userData?['telephone'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
// Stocker une référence au contexte actif qui est sûre à utiliser plus tard
    _safeContext = context;

    // Stocker le contexte actif pour une utilisation ultérieure
    _context = context;
    
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
              SizedBox(height: 16),
              _buildField(_emailCtrl, 'Email'),
              SizedBox(height: 16),
              _buildField(_phoneCtrl, 'Téléphone'),
              SizedBox(height: 16),
              _buildField(
                _currentPwdCtrl,
                'Mot de passe actuel',
                obscure: true,
              ),
              SizedBox(height: 16),
              _buildField(_newPwdCtrl, 'Nouveau mot de passe', obscure: true),
              SizedBox(height: 16),
              _buildField(
                _confirmPwdCtrl,
                'Confirmer le nouveau mot de passe',
                obscure: true,
              ),
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
      child: Text(text, style: TextStyle(color: Colors.white)),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _reauthenticate(String email, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    // Seulement si l'utilisateur existe
    if (user != null && password.isNotEmpty) {
      final cred = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(cred);
    } else {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Veuillez entrer votre mot de passe actuel pour continuer.',
      );
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
      // Vérifier si une modification sensible est tentée pour déterminer si la réauthentification est nécessaire
      bool needsReauth = false;
      if (_emailCtrl.text != user.email || _newPwdCtrl.text.isNotEmpty) {
        needsReauth = true;
      }
      
      // Réauthentification seulement si nécessaire
      if (needsReauth) {
        if (_currentPwdCtrl.text.isEmpty) {
          setState(() => _error = 'Mot de passe actuel requis pour changer l\'email ou le mot de passe.');
          return;
        }
        await _reauthenticate(user.email ?? '', _currentPwdCtrl.text);
      }

      if (_newPwdCtrl.text.isNotEmpty) {
        if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
          setState(() => _error = 'Les mots de passe ne correspondent pas.');
          return;
        }
        await user.updatePassword(_newPwdCtrl.text);
      }

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

      // Modifier l'email en dernier pour éviter des problèmes d'authentification
      if (_emailCtrl.text.isNotEmpty && _emailCtrl.text != user.email) {
        await user.updateEmail(_emailCtrl.text);
        await user.sendEmailVerification();
      }

      if (_newPwdCtrl.text.isNotEmpty)
        await user?.updatePassword(_newPwdCtrl.text);

      // Mettre à jour les données dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
            'nom': _nameCtrl.text,
            'prenom': _prenomCtrl.text,
            'email': _emailCtrl.text,
            'telephone': _phoneCtrl.text,
          });

      // Mettre à jour les données dans Firestore avec l'ID utilisateur existant
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nom': _nameCtrl.text,
        'prenom': _prenomCtrl.text,
        'email': _emailCtrl.text,
        'telephone': _phoneCtrl.text,
      });

      // Recharger l'utilisateur pour s'assurer que nous avons les informations les plus récentes
      await user.reload();

      // Utiliser _context plutôt que le BuildContext du widget qui peut être déjà désactivé
      if (mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil mis à jour avec succès.',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.greenAccent,
          ),

          backgroundColor: Colors.greenAccent,
        ),
      );

      // Utiliser le contexte sûr pour la navigation
      Navigator.pop(_safeContext);

        );
        
        Navigator.pop(_context);
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
    _emailCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}
