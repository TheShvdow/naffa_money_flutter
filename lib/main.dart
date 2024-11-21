import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naffa_money/screens/auth/login_screen.dart';
import 'package:naffa_money/screens/distributor/distributor_home_screen.dart';
import 'package:naffa_money/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn().isSignedIn();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naffa',
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // Afficher un écran de chargement pendant la vérification
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                    )
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
        bool isDistributor(User? user) {
          return user?.email?.endsWith('@naffamoney.sn') ?? false;
        }

        // Si l'utilisateur est connecté, afficher HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          User? user = snapshot.data;

          if (isDistributor(user)) {
            return DistributorHomeScreen();
          } else {
            return HomeScreen();
          }
        }


        // Si l'utilisateur n'est pas connecté, afficher LoginScreen
        return LoginScreen();
      },
    );
  }
}

// Classe d'animation personnalisée pour les transitions
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