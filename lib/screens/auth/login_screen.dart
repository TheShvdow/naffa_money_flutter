// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _isPhoneLogin = true;

  Future<void> _handlePhoneOrEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithPhoneOrEmail(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (userCredential?.user != null) {
        // La navigation sera gérée automatiquement par le StreamBuilder
        print('Connexion réussie');
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Une erreur est survenue');
    } catch (e) {
      _showError('Erreur de connexion: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    print("Démarrage de la connexion Google");

    try {
      final result = await _authService.signInWithGoogle();
      print("Résultat de la connexion Google: ${result.user?.uid}");

    } catch (e) {
      print("Erreur de connexion Google: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }


  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade50,
                              ),
                              child: Image.asset(
                                'assets/logo.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Naffa',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        // Sélecteur du type de connexion
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: true,
                              label: Text('Téléphone'),
                              icon: Icon(Icons.phone),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Email'),
                              icon: Icon(Icons.email),
                            ),
                          ],
                          selected: {_isPhoneLogin},
                          onSelectionChanged: (Set<bool> newSelection) {
                            setState(() {
                              _isPhoneLogin = newSelection.first;
                              _identifierController.clear();
                            });
                          },
                        ),
                        SizedBox(height: 20),

                        // Champ identifiant (téléphone ou email)
                        TextFormField(
                          controller: _identifierController,
                          decoration: InputDecoration(
                            labelText: _isPhoneLogin ? 'Numéro de téléphone' : 'Email',
                            hintText: _isPhoneLogin
                                ? '+221 XX XXX XX XX'
                                : 'exemple@email.com',
                            prefixIcon: Icon(
                              _isPhoneLogin ? Icons.phone : Icons.email,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: _isPhoneLogin
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ce champ est requis';
                            }
                            if (_isPhoneLogin) {
                              String phone = value.replaceAll(' ', '');
                              if (!phone.startsWith('+221') &&
                                  !phone.startsWith('221') &&
                                  phone.length < 9) {
                                return 'Numéro de téléphone invalide';
                              }
                            } else {
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Email invalide';
                              }
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),

                        // Champ mot de passe
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le mot de passe est requis';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),

                        // Lien "Mot de passe oublié"
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Naviguer vers l'écran de réinitialisation
                            },
                            child: Text('Mot de passe oublié ?'),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Bouton de connexion principal
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handlePhoneOrEmailLogin,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Séparateur
                        Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OU',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Bouton Google
                        OutlinedButton.icon(
                          icon: _isGoogleLoading
                              ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            ),
                          )
                              : Image.asset(
                            'assets/google.png',
                            height: 24,
                          ),
                          label: Text(_isGoogleLoading ? 'Connexion en cours...' : 'Continuer avec Google'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: (_isLoading || _isGoogleLoading) ? null : handleGoogleSignIn,
                        ),
                        SizedBox(height: 20),

                        // Bouton Facebook
                        ElevatedButton.icon(
                          icon: Icon(Icons.facebook),
                          label: Text('Continuer avec Facebook'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: (){},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}