// lib/services/transfer_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class TransferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> transferMoney({
    required String senderUid,
    required String receiverPhone,
    required double amount,
    String? description,
  }) async {
    // Démarrer une transaction Firestore
    return await _firestore.runTransaction((transaction) async {
      try {
        // Obtenir les documents des deux utilisateurs
        final senderDoc = await transaction.get(
            _firestore.collection('users').doc(senderUid)
        );

        // Trouver le destinataire par numéro de téléphone
        final receiverQuery = await _firestore
            .collection('users')
            .where('phone', isEqualTo: receiverPhone)
            .limit(1)
            .get();

        if (receiverQuery.docs.isEmpty) {
          throw Exception('Destinataire non trouvé');
        }

        final receiverDoc = receiverQuery.docs.first;

        // Vérifier que l'émetteur n'est pas le destinataire
        if (senderUid == receiverDoc.id) {
          throw Exception('Vous ne pouvez pas vous transférer de l\'argent à vous-même');
        }

        // Convertir les données en modèle utilisateur
        final sender = UserModel.fromJson(senderDoc.data()!);
        final receiver = UserModel.fromJson(receiverDoc.data()!);

        // Vérifier le solde
        if (sender.balance < amount) {
          throw Exception('Solde insuffisant');
        }

        // Mettre à jour les soldes
        final newSenderBalance = sender.balance - amount;
        final newReceiverBalance = receiver.balance + amount;

        // Mettre à jour les documents des utilisateurs
        transaction.update(
            senderDoc.reference,
            {'balance': newSenderBalance}
        );

        transaction.update(
            receiverDoc.reference,
            {'balance': newReceiverBalance}
        );

        // Créer une nouvelle transaction
        final transactionData = {
          'senderId': senderUid,
          'senderName': sender.name,
          'receiverId': receiverDoc.id,
          'receiverName': receiver.name,
          'amount': amount,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'transfer',
          'status': 'completed',
          'userId': senderUid,  // Important pour l'index
          'isDebit': true
        };

        // Créer les entrées de transaction pour l'émetteur et le destinataire
        transaction.set(
            _firestore.collection('transactions').doc(),
            {
              ...transactionData,
              'userId': senderUid,
              'isDebit': true,
            }
        );

        transaction.set(
            _firestore.collection('transactions').doc(),
            {
              ...transactionData,
              'userId': receiverDoc.id,
              'isDebit': false,
            }
        );

      } catch (e) {
        print('Erreur pendant le transfert: $e');
        rethrow;
      }
    });
  }

  // Obtenir l'historique des transactions
  Stream<QuerySnapshot> getTransactionHistory(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Vérifier si un numéro existe
  Future<bool> checkReceiverExists(String phone) async {
    final query = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Obtenir les informations du destinataire
  Future<UserModel?> getReceiverInfo(String phone) async {
    final query = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromJson(query.docs.first.data());
    }
    return null;
  }
}