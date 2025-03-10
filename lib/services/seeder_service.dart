// lib/services/distributor_seeder.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DistributorSeeder {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _distributorsData = [
    {
      'name': 'Point NaffaMoney Plateau',
      'email': 'plateau@naffamoney.com',
      'phone': '+221771111111',
      'password': 'Password123!',
      'address': 'Avenue Léopold Sédar Senghor, Plateau',
      'zone': 'Plateau',
      'balance': 5000000,
    },
    {
      'name': 'NaffaMoney Médina',
      'email': 'medina@naffamoney.sn',
      'phone': '+221772222222',
      'password': 'Password123!',
      'address': 'Rue 11 x 6, Médina',
      'zone': 'Médina',
      'balance': 3000000,
    },
    {
      'name': 'Point Service Fann',
      'email': 'fann@naffamoney.sn',
      'phone': '+221773333333',
      'password': 'Password123!',
      'address': 'Avenue Cheikh Anta Diop, Fann',
      'zone': 'Fann',
      'balance': 4000000,
    },
    {
      'name': 'NaffaMoney Ouakam',
      'email': 'ouakam@naffamoney.sn',
      'phone': '+221774444444',
      'password': 'Password123!',
      'address': 'Route de Ouakam',
      'zone': 'Ouakam',
      'balance': 2500000,
    },
  ];

  Future<void> seedDistributors() async {
    try {
      for (var data in _distributorsData) {
        // Vérifier si le distributeur existe déjà
        final existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: data['email'])
            .get();

        if (existingUsers.docs.isNotEmpty) {
          print('Le distributeur ${data['email']} existe déjà');
          continue;
        }

        // Créer l'utilisateur dans Firebase Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: data['email'],
          password: data['password'],
        );

        // Créer le profil dans Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'name': data['name'],
          'email': data['email'],
          'phone': data['phone'],
          'address': data['address'],
          'zone': data['zone'],
          'balance': data['balance'],
          'userType': 'distributor',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': null,
          'totalTransactions': 0,
        });

        print('Distributeur créé avec succès: ${data['name']}');

        // Petit délai pour éviter les limitations de Firebase
        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Erreur lors du seeding: $e');
      rethrow;
    }
  }

  Future<void> clearDistributors() async {
    try {
      // Récupérer tous les distributeurs
      final distributors = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'distributor')
          .get();

      // Pour chaque distributeur
      for (var doc in distributors.docs) {
        try {
          // D'abord, essayer de se connecter avec l'email/mot de passe
          final email = doc.data()['email'];

          // Supprimer de Firestore
          await doc.reference.delete();

          // Essayer de supprimer l'utilisateur Auth
          try {
            // Se connecter en tant qu'utilisateur pour le supprimer
            final credential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: 'Password123!',
            );

            if (credential.user != null) {
              await credential.user!.delete();
            }
          } catch (authError) {
            print('Erreur lors de la suppression de l\'utilisateur Auth: $authError');
          }
        } catch (e) {
          print('Erreur lors de la suppression du distributeur ${doc.id}: $e');
        }
      }

      print('Tous les distributeurs ont été supprimés');
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }
}