import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Function() onEditProfile;
  final bool isLoading;

  const ProfileHeader({
    Key? key,
    required this.userData,
    required this.onEditProfile,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage:
                  user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : AssetImage('assets/profil.png') as ImageProvider,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onEditProfile,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        isLoading
            ? CircularProgressIndicator()
            : Text(
                '${userData?['prenom'] ?? 'Prénom'} ${userData?['nom'] ?? 'Nom'}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
      ],
    );
  }
}

class EditProfilePhotoDialog extends StatefulWidget {
  final String? currentPhotoUrl;
  final Function(File) onPhotoSelected;

  const EditProfilePhotoDialog({
    Key? key,
    this.currentPhotoUrl,
    required this.onPhotoSelected,
  }) : super(key: key);

  @override
  State<EditProfilePhotoDialog> createState() => _EditProfilePhotoDialogState();
}

class _EditProfilePhotoDialogState extends State<EditProfilePhotoDialog> {
  final _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Changer la photo de profil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading)
            Container(
              height: 200,
              width: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_imageFile != null)
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: widget.currentPhotoUrl != null
                      ? NetworkImage(widget.currentPhotoUrl!)
                      : AssetImage('assets/profil.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: Icon(Icons.photo_library),
                label: Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: Icon(Icons.camera_alt),
                label: Text('Caméra'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _imageFile == null
              ? null
              : () {
                  widget.onPhotoSelected(_imageFile!);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
          ),
          child: Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }
}