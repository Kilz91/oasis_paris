import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_page.dart';
import 'navbar.dart';

class ProfilPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return _buildNotConnected(context);

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
              Text(
                'Nom: ${user.displayName ?? 'Nom non disponible'}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'Email: ${user.email ?? 'Email non disponible'}',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              SizedBox(height: 24),
              _buildButton('Modifier le profil', Colors.teal, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfilePage()),
                );
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
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _imageFile;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
    _emailCtrl.text = user?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
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
              _buildField(_nameCtrl, 'Pseudo'),
              SizedBox(height: 16),
              _buildField(_emailCtrl, 'Email'),
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
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user?.reauthenticateWithCredential(cred);
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _error = '');

    try {
      await _reauthenticate(user?.email ?? '', _currentPwdCtrl.text);

      if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
        setState(() => _error = 'Les mots de passe ne correspondent pas.');
        return;
      }

      if (_nameCtrl.text.isNotEmpty)
        await user?.updateDisplayName(_nameCtrl.text);

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_pictures/${user?.uid}.png',
        );
        final url = await (await ref.putFile(_imageFile!)).ref.getDownloadURL();
        await user?.updatePhotoURL(url);
      }

      if (_emailCtrl.text.isNotEmpty && _emailCtrl.text != user?.email) {
        await user?.updateEmail(_emailCtrl.text);
        await user?.sendEmailVerification();
      }

      if (_newPwdCtrl.text.isNotEmpty)
        await user?.updatePassword(_newPwdCtrl.text);

      await user?.reload();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil mis à jour avec succès.',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.greenAccent,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Erreur : ${e.toString()}');
    }
  }
}
