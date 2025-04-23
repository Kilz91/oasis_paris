import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout de l'import de Firestore
import 'profil.dart'; // N'oublie pas d'importer ta page Profil

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.title});

  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final telephoneController = TextEditingController();
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<User?>(
        // Écoute l'état de connexion
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              // L'utilisateur est connecté
              Future.microtask(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilPage()),
                );
              });
            }
            // Si l'utilisateur n'est pas connecté, afficher la page de login
            return _buildRegisterForm();
          } else {
            // Affiche un écran de chargement si l'état de la connexion est en cours
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Formulaire de connexion
  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: nomController,
            decoration: InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 16),
          TextField(
            controller: prenomController,
            decoration: InputDecoration(
              labelText: 'Prenom',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          TextField(
            controller: telephoneController,
            decoration: InputDecoration(
              labelText: 'Teléphone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 24),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                onPressed: () {
                  if (emailController.text.isNotEmpty &&
                      passwordController.text.length >= 6) {
                    // Rediriger vers la page de login
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Veuillez entrer un email et un mot de passe valides.',
                        ),
                      ),
                    );
                  }
                },
                child: Text('Retour à Login'),
              ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty &&
                  passwordController.text.length >= 6) {
                signUp(); // Appel à la méthode signUp
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Veuillez entrer un email et un mot de passe valides pour l\'inscription.',
                    ),
                  ),
                );
              }
            },
            child: Text('Inscription'),
          ),
        ],
      ),
    );
  }

  // Fonction pour s'inscrire
  Future<void> signUp() async {
    final auth = FirebaseAuth.instance;

    setState(() {
      _isLoading = true;
    });

    try {
      // Création du compte utilisateur avec email et mot de passe uniquement
      final UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      
      // Récupérer l'ID de l'utilisateur créé
      final String uid = userCredential.user!.uid;
      
      try {
        // Stocker les informations supplémentaires dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': emailController.text,
          'telephone': telephoneController.text,
          'nom': nomController.text,
          'prenom': prenomController.text,
          'dateCreation': FieldValue.serverTimestamp(), // Ajout d'un timestamp de création
        });
        
// Vérifier si le widget est toujours monté avant d'utiliser le contexte
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie! Données enregistrées dans Firestore'))
        );
}
      } catch (firestoreError) {
        // Permettre à l'utilisateur de continuer même si l'enregistrement dans Firestore échoue
        print('Erreur Firestore: $firestoreError');

        // Vérifier si le widget est toujours monté avant d'utiliser le contexte
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie, mais une erreur est survenue lors de l\'enregistrement des données supplémentaires.'))
        );
      }
}
    } catch (e) {
// Vérifier si le widget est toujours monté avant d'utiliser le contexte
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inscription échouée: ${e.toString()}')),
      );
}
    } finally {
// Vérifier si le widget est toujours monté avant de mettre à jour son état
      if (mounted) {
      setState(() {
        _isLoading = false;
      });
}
    }
  }
}
