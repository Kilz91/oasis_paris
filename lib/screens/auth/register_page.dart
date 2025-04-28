import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout de l'import de Firestore
import '../../widgets/navbar/navbar.dart';
import 'login_page.dart'; // Ajout de l'import pour LoginPage

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
      body: _buildRegisterForm(),
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
                    // Utiliser pushAndRemoveUntil avec MaterialPageRoute pour la page de connexion
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage(title: 'Oasis Paris')),
                      (route) => false, // Cette condition empêche tout retour arrière
                    );
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
    // Capturer NavigatorState et ScaffoldMessengerState avant toute opération asynchrone
    final navigatorState = Navigator.of(context); 
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
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
          // Utiliser scaffoldMessenger au lieu de ScaffoldMessenger.of(context)
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Inscription réussie! Bienvenue sur Oasis Paris.'))
          );
          
          // Utiliser navigatorState au lieu de Navigator.of(context)
          navigatorState.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => NavbarPage()),
            (route) => false, // Cette condition empêche tout retour arrière
          );
        }
      } catch (firestoreError) {
        // Permettre à l'utilisateur de continuer même si l'enregistrement dans Firestore échoue
        print('Erreur Firestore: $firestoreError');

        // Vérifier si le widget est toujours monté
        if (mounted) {
          // Utiliser scaffoldMessenger au lieu de ScaffoldMessenger.of(context)
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Inscription réussie, mais une erreur est survenue lors de l\'enregistrement des données supplémentaires.'))
          );
          
          // Utiliser navigatorState au lieu de Navigator.of(context)
          navigatorState.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => NavbarPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Vérifier si le widget est toujours monté
      if (mounted) {
        // Utiliser scaffoldMessenger au lieu de ScaffoldMessenger.of(context)
        scaffoldMessenger.showSnackBar(
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
