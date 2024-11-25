import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naffa_money/screens/auth/login_screen.dart';
import 'package:naffa_money/screens/distributor/distributor_home_screen.dart';
import 'package:naffa_money/screens/home/home_screen.dart';
import 'firebase_options.dart';
import 'screens/auth/PhoneCollectionScreen.dart';

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

  // Fonction pour vérifier si l'utilisateur est un distributeur
  bool isDistributor(User? user) {
    return user?.email?.endsWith('@naffamoney.sn') ?? false;
  }

  // Fonction pour vérifier si l'utilisateur a un numéro de téléphone
  Future<bool> hasPhoneNumber(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      print('Checking phone number for user $userId'); // Debug print

      if (!docSnapshot.exists) {
        print('User document does not exist'); // Debug print
        return false;
      }

      final userData = docSnapshot.data();
      if (userData == null) {
        print('User data is null'); // Debug print
        return false;
      }

      final phone = userData['phone'] as String?;
      print('Phone number found: $phone'); // Debug print
      return phone != null && phone.isNotEmpty;
    } catch (e) {
      print('Error checking phone number: $e'); // Debug print
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        // Afficher un écran de chargement pendant la vérification de l'authentification
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }

        // Si l'utilisateur n'est pas connecté
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return LoginScreen();
        }

        // L'utilisateur est connecté
        final User user = authSnapshot.data!;
        print('User authenticated: ${user.email}'); // Debug print

        // Si c'est un distributeur, rediriger directement
        if (isDistributor(user)) {
          print('User is distributor, redirecting to DistributorHomeScreen'); // Debug print
          return DistributorHomeScreen();
        }

        // Pour les utilisateurs normaux, vérifier le numéro de téléphone
        return FutureBuilder<bool>(
          future: hasPhoneNumber(user.uid),
          builder: (context, phoneSnapshot) {
            if (phoneSnapshot.connectionState == ConnectionState.waiting) {
              return LoadingScreen();
            }

            if (phoneSnapshot.hasError) {
              print('Error in phone check: ${phoneSnapshot.error}'); // Debug print
              return ErrorScreen(error: phoneSnapshot.error.toString());
            }

            final hasPhone = phoneSnapshot.data ?? false;
            print('Has phone number: $hasPhone'); // Debug print

            if (hasPhone) {
              print('Redirecting to HomeScreen'); // Debug print
              return HomeScreen();
            } else {
              print('Redirecting to PhoneCollectionScreen'); // Debug print
              return PhoneCollectionScreen(userId: user.uid);
            }
          },
        );
      },
    );
  }
}

// Widget d'écran de chargement réutilisable
class LoadingScreen extends StatelessWidget {
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

  const ErrorScreen({Key? key, required this.error}) : super(key: key);

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