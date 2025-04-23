import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profil.dart'; // N'oublie pas d'importer ta page Profil
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
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
            return _buildLoginForm();
          } else {
            // Affiche un écran de chargement si l'état de la connexion est en cours
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // Formulaire de connexion
  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                    login();
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
                child: Text('Login'),
              ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Redirection vers la page d'inscription
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterPage(title: 'Inscription'),
                ),
              );
            },
            child: Text('Pas encore de compte? Inscrivez-vous!'),
          ),
        ],
      ),
    );
  }

  // Fonction pour se connecter
  Future<void> login() async {
    final auth = FirebaseAuth.instance;

    setState(() {
      _isLoading = true;
    });

    // Vérification de l'email
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un email valide.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Vérification du mot de passe
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le mot de passe doit comporter au moins 6 caractères.',
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vous êtes connecté!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login échoué: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
