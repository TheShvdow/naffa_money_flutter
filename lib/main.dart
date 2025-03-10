import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naffa_money/screens/auth/login_screen.dart';
import 'package:naffa_money/screens/distributor/distributor_home_screen.dart';
import 'package:naffa_money/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn().signOut(); // Déconnexion préalable de Google
  await FirebaseAuth.instance.signOut(); // Déconnexion préalable de Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naffa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

   AuthenticationWrapper({super.key});

  // Fonction pour vérifier si l'utilisateur est un distributeur
  bool isDistributor(User? user) {
    return user?.email?.endsWith('@naffamoney.sn') ?? false;
  }

  // Fonction pour vérifier si l'utilisateur a un numéro de téléphone
  Future<bool> hasPhoneNumber(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();

      if (!docSnapshot.exists) {
        print('Document utilisateur non trouvé - ID: $userId');
        return false;
      }

      final userData = docSnapshot.data();
      if (userData == null) {
        print('Données utilisateur null pour ID: $userId');
        return false;
      }

      final phone = userData['phone'] as String?;
      print('Numéro trouvé dans Firestore: $phone');

      final hasValidPhone = phone != null && phone.isNotEmpty;
      print('Le numéro est-il valide ? $hasValidPhone');

      return hasValidPhone;
    } catch (e) {
      print('Erreur de vérification du numéro: $e');
      // En cas d'erreur, on considère qu'il n'y a pas de numéro
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return LoginScreen();
        }

        final User user = authSnapshot.data!;

        if (isDistributor(user)) {
          return DistributorHomeScreen();
        }

        return HomeScreen();
      },
    );
  }
}

// Widget d'écran de chargement réutilisable
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade50,
              ),
              child: Image.asset(
                'assets/logo.png',
                width: 30,
                height: 30,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Chargement...',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget d'écran d'erreur réutilisable
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Une erreur est survenue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                  );
                },
                child: Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Classes d'animation pour les transitions de page
class FadePageRoute<T> extends PageRoute<T> {
  FadePageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
      opacity: animation,
      child: builder(context),
    );
  }
}

// Extension pour faciliter la navigation avec animation
extension NavigationExtension on BuildContext {
  Future<T?> pushWithFade<T extends Object?>(Widget page) {
    return Navigator.of(this).push(
      FadePageRoute<T>(
        builder: (_) => page,
      ),
    );
  }

  Future<T?> pushReplacementWithFade<T extends Object?, TO extends Object?>(
      Widget page) {
    return Navigator.of(this).pushReplacement(
      FadePageRoute<T>(
        builder: (_) => page,
      ),
    );
  }
}