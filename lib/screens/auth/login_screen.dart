import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 40),
              Text(
                'Bienvenue sur WaveMoney',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {},
                child: const Text('Connexion avec téléphone'),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                icon: Image.asset('assets/google.png', height: 24),
                label: const Text('Connexion avec Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {},
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                icon: Image.asset('assets/facebook.png', height: 24),
                label: const Text('Connexion avec Facebook'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue[900],
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
