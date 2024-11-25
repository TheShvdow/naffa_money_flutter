import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  // Ajoutez cette méthode dans votre classe AuthService



  Future<UserCredential?> signInWithPhoneOrEmail(
      String identifier,
      String password,
      {String userType = 'client'}
      ) async {
    try {
      // Vérifier si l'identifiant est un numéro de téléphone
      bool isPhone = identifier.startsWith('+221') ||
          identifier.startsWith('221') ||
          (identifier.length >= 9 && int.tryParse(identifier.replaceAll(' ', '')) != null);

      if (isPhone) {
        // Formater le numéro de téléphone
        String formattedPhone = identifier.replaceAll(' ', '');
        if (!formattedPhone.startsWith('+')) {
          formattedPhone = '+221${formattedPhone.startsWith('221') ? formattedPhone.substring(3) : formattedPhone}';
        }

        // Rechercher l'utilisateur par numéro de téléphone
        final QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .where('phone', isEqualTo: formattedPhone)
            .where('userType', isEqualTo: userType)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Aucun utilisateur trouvé avec ce numéro de téléphone',
          );
        }

        // Obtenir l'email associé au numéro de téléphone
        final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
        final email = userData['email'];

        if (email == null || email.isEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'Aucun email associé à ce numéro de téléphone',
          );
        }

        // Connexion avec l'email récupéré
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Connexion directe avec email
        return await _auth.signInWithEmailAndPassword(
          email: identifier,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec ces identifiants';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          message = 'Format d\'email invalide';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Veuillez réessayer plus tard';
          break;
        default:
          message = e.message ?? 'Une erreur est survenue';
      }
      print('Erreur d\'authentification: ${e.code} - $message');
      throw FirebaseAuthException(
        code: e.code,
        message: message,
      );
    } catch (e) {
      print('Erreur inattendue: $e');
      throw FirebaseAuthException(
        code: 'unexpected-error',
        message: 'Une erreur inattendue est survenue',
      );
    }
  }

// Ajouter également une méthode pour vérifier si un numéro existe
  Future<bool> checkPhoneExists(String phone) async {
    try {
      String formattedPhone = phone.replaceAll(' ', '');
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+221${formattedPhone.startsWith('221') ? formattedPhone.substring(3) : formattedPhone}';
      }

      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('phone', isEqualTo: formattedPhone)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du numéro: $e');
      return false;
    }
  }

// Méthode pour récupérer l'utilisateur par numéro de téléphone
  Future<UserModel?> getUserByPhone(String phone) async {
    try {
      String formattedPhone = phone.replaceAll(' ', '');
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+221${formattedPhone.startsWith('221') ? formattedPhone.substring(3) : formattedPhone}';
      }

      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('phone', isEqualTo: formattedPhone)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        return UserModel.fromJson(result.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

// Méthode pour réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Adresse email invalide';
          break;
        case 'user-not-found':
          message = 'Aucun compte associé à cette adresse email';
          break;
        default:
          message = 'Erreur lors de la réinitialisation du mot de passe';
      }
      throw FirebaseAuthException(
        code: e.code,
        message: message,
      );
    }
  }
  Future<String?> getCurrentUserType() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        return doc.data()?['userType'] as String?;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la vérification du type d\'utilisateur: $e');
      return null;
    }
  }
  Future<UserCredential> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      print("Firebase User ID: ${userCredential.user?.uid}");

      // Créer ou mettre à jour l'utilisateur dans Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'id': userCredential.user?.uid,
        'name': userCredential.user?.displayName ?? '',
        'email': userCredential.user?.email ?? '',
        'profilePicture': userCredential.user?.photoURL ?? '',
        'phone': '', // téléphone vide par défaut
        'balance': 0.0,
        'contacts': [],
      }, SetOptions(merge: true)); // merge: true permet de ne pas écraser les données existantes

      return userCredential;
    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }

  // Mise à jour du numéro de téléphone
  Future<void> updateUserPhoneNumber(String userId, String phoneNumber) async {
    try {
      String formattedPhone = phoneNumber.replaceAll(' ', '');
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+221${formattedPhone.startsWith('221') ? formattedPhone.substring(3) : formattedPhone}';
      }

      // Vérifier si le numéro existe déjà
      final QuerySnapshot existingPhone = await _firestore
          .collection('users')
          .where('phone', isEqualTo: formattedPhone)
          .get();

      if (existingPhone.docs.isNotEmpty) {
        throw Exception('Ce numéro de téléphone est déjà utilisé');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .update({'phone': formattedPhone});

      print('Numéro de téléphone mis à jour avec succès: $formattedPhone');
    } catch (e) {
      print('Erreur lors de la mise à jour du numéro: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Sign Out Error: $e');
      rethrow;
    }
  }

  // Obtenir l'utilisateur actuel
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Vérifier si l'utilisateur existe dans Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user?.uid).get();

      if (!userDoc.exists) {
        // Créer un nouveau document utilisateur
        final user = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user?.displayName ?? 'Utilisateur',
          email: userCredential.user?.email ?? '',
          profilePicture: userCredential.user?.phoneNumber ?? '',
          phone: '',
          balance: 0.0,
          contacts: [],
        );

        await _firestore.collection('users').doc(user.id).set(user.toJson());
      }

      return userCredential;
    } catch (e) {
      print('Erreur de connexion par téléphone: $e');
      throw e;
    }
  }

  // Obtenir les données utilisateur de Firestore
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}