import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
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
            ElevatedButton(
              onPressed: () {
                if (emailController.text.isNotEmpty && passwordController.text.length >= 6)
                {
                  login();
                }
                // Handle login logic here
              },
              child: Text('Login'),
            ),

            TextButton(onPressed: () {
              final auth = FirebaseAuth.instance;
              auth.createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text);
            }, child: Text('Inscription')),
          ],
        ),
      ),
    );
  }

  Future<void> login() async {
  final auth = FirebaseAuth.instance;

  try {
    await auth.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login successful!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: ${e.toString()}')),
    );
  }
}
}