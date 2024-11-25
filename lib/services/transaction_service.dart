// lib/services/transfer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/distributor_model.dart';
import '../models/scheduled_transfert.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> transferMoney({
    required String transactionId,
    required String senderUid,
    required String receiverPhone,
    required double amount,
  }) async {
    // Démarrer une transaction Firestore
    return await _firestore.runTransaction((transaction) async {
      try {
        // Obtenir les documents des deux utilisateurs
        final senderDoc = await transaction.get(
          _firestore.collection('users').doc(senderUid),
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
        final receiver = UserModel.fromJson(receiverDoc.data());

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
          {'balance': newSenderBalance},
        );

        transaction.update(
          receiverDoc.reference,
          {'balance': newReceiverBalance},
        );

        // Créer les données de transaction pour l'émetteur
        final transactionData = TransactionModel(
          id: const Uuid().v4(),
          transactionId: transactionId,
          type: 'transfert',
          amount: amount,
          senderId: senderUid,
          senderName: sender.name,
          senderPhone: sender.phone,
          receiverId: receiverDoc.id,
          receiverName: receiver.name,
          receiverPhone: receiver.phone,
          timestamp: DateTime.now(),
          isDebit: true,
          status: 'pending',
        ).toJson();

        // Créer la transaction
        await _firestore.collection('transactions').add(transactionData);
      } catch (e) {
        print('Erreur pendant le transfert: $e');
        rethrow;
      }
    });
  }

  Future<void> transferMultiple({
    required String transactionId,
    required String senderUid,
    required List<String> receivers,
    required List<double> amounts,
  }) async {
    return await _firestore.runTransaction((transaction) async {
      try {
        // Obtenir le document de l'utilisateur émetteur
        final senderDoc = await transaction.get(
          _firestore.collection('users').doc(senderUid),
        );

        // Convertir les données de l'émetteur en modèle utilisateur
        final sender = UserModel.fromJson(senderDoc.data()!);
        double remainingBalance = sender.balance;

        // Traiter chaque transfert
        for (int i = 0; i < receivers.length; i++) {
          final receiverPhone = receivers[i];
          final receiverAmount = amounts[i];

          // Transaction pour l'émetteur (débit)
          var senderTransactionData = TransactionModel(
            transactionId: transactionId,
            type: 'transfert multiple',
            amount: receiverAmount,
            senderId: senderUid,
            senderName: sender.name,
            senderPhone: sender.phone,
            receiverPhone: receiverPhone,
            timestamp: DateTime.now(),
            isDebit: true,
            status: 'pending',
          ).toJson();

          // Vérifier si le solde restant est suffisant
          if (remainingBalance < receiverAmount) {
            senderTransactionData.addAll({
              'status': 'failed',
              'failureReason': 'Solde insuffisant',
            });

            // Créer la transaction échouée
            transaction.set(
              _firestore.collection('transactions').doc(),
              senderTransactionData,
            );
            continue;
          }

          try {
            // Trouver le destinataire
            final receiverQuery = await _firestore
                .collection('users')
                .where('phone', isEqualTo: receiverPhone)
                .limit(1)
                .get();

            if (receiverQuery.docs.isEmpty) {
              senderTransactionData.addAll({
                'status': 'failed',
                'failureReason': 'Destinataire non trouvé',
              });

              // Créer la transaction échouée
              transaction.set(
                _firestore.collection('transactions').doc(),
                senderTransactionData,
              );
              continue;
            }

            final receiverDoc = receiverQuery.docs.first;
            final receiver = UserModel.fromJson(receiverDoc.data());

            // Mettre à jour le solde du destinataire
            final newReceiverBalance = receiver.balance + receiverAmount;
            transaction.update(
              receiverDoc.reference,
              {'balance': newReceiverBalance},
            );

            // Mettre à jour le solde de l'émetteur
            remainingBalance -= receiverAmount;
            transaction.update(
              senderDoc.reference,
              {'balance': remainingBalance},
            );

            // Compléter les informations pour la transaction de l'émetteur
            senderTransactionData.addAll({
              'receiverId': receiverDoc.id,
              'receiverName': receiver.name,
              'receiverPhone': receiver.phone,
              'status': 'completed',
            });

            // Créer la transaction
            transaction.set(
              _firestore.collection('transactions').doc(),
              senderTransactionData,
            );
          } catch (e) {
            senderTransactionData.addAll({
              'status': 'failed',
              'failureReason': e.toString(),
            });

            // Créer la transaction échouée
            transaction.set(
              _firestore.collection('transactions').doc(),
              senderTransactionData,
            );
          }
        }
      } catch (e) {
        print('Erreur pendant le transfert multiple: $e');
        rethrow;
      }
    });
  }

  Future<void> transferScheduled({
    required String senderUid,
    required String receiverPhone,
    required double amount,
    required DateTime scheduleDate,
  }) async {
    // Démarrer une transaction Firestore
    return await _firestore.runTransaction((transaction) async {
      try {
        // Obtenir le document de l'utilisateur émetteur
        final senderDoc = await transaction.get(
          _firestore.collection('users').doc(senderUid),
        );

        // Convertir les données de l'émetteur en modèle utilisateur
        final sender = UserModel.fromJson(senderDoc.data()!);

        // Vérifier que l'émetteur a un solde suffisant
        if (sender.balance < amount) {
          throw Exception('Solde insuffisant');
        }

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
        final receiver = UserModel.fromJson(receiverDoc.data());

        // Mettre à jour le solde du destinataire
        final newReceiverBalance = receiver.balance + amount;
        transaction.update(
          receiverDoc.reference,
          {'balance': newReceiverBalance},
        );

        // Mettre à jour le solde de l'émetteur
        final newSenderBalance = sender.balance - amount;
        transaction.update(
          senderDoc.reference,
          {'balance': newSenderBalance},
        );

        // Créer la transaction programmée
        final transactionData = TransactionModel(
          transactionId: const Uuid().v4(),
          type: 'transfert programmé',
          amount: amount,
          senderId: senderUid,
          senderName: sender.name,
          receiverId: receiverDoc.id,
          receiverName: receiver.name,
          timestamp: scheduleDate,
          isDebit: true,
          status: 'pending',
        ).toJson();

        transaction.set(
          _firestore.collection('transactions').doc(),
          transactionData,
        );
      } catch (e) {
        print('Erreur pendant le transfert programmé: $e');
        rethrow;
      }
    });
  }

  Future<void> createTransaction({
    required String type,
    required double amount,
    required String senderUid,
    String? senderName,
    String? receiverUid,
    String? receiverName,
    required bool isDebit,
  }) async {
    final transactionData = TransactionModel(
      id: Uuid().v4(),
      type: type,
      amount: amount,
      senderId: senderUid,
      senderName: senderName,
      receiverId: receiverUid,
      receiverName: receiverName,
      timestamp: DateTime.now(),
      isDebit: isDebit,

    ).toJson();

    await _firestore.collection('transactions').add(transactionData);
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
  Future<void> cancelTransaction(String transactionId) async {
    try {
      // Recherche de la transaction
      final QuerySnapshot transactionQuery = await _firestore
          .collection('transactions')
          .where('id', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (transactionQuery.docs.isEmpty) {
        throw Exception('Transaction non trouvée');
      }

      final transactionDoc = transactionQuery.docs.first;
      final transactionData = transactionDoc.data() as Map<String, dynamic>;

      // Vérifications avant la transaction
      final now = DateTime.now();
      final createdAt = (transactionData['timestamp'] as Timestamp).toDate();
      if (now.difference(createdAt).inMinutes > 30) {
        throw Exception('Le délai d\'annulation de 30 minutes est dépassé');
      }

      if (transactionData['status'] != 'pending') {
        throw Exception('Cette transaction ne peut plus être annulée');
      }

      // Récupérer les références des utilisateurs avant d'écrire
      final senderRef = _firestore.collection('users').doc(transactionData['senderId']);
      final receiverRef = _firestore.collection('users').doc(transactionData['receiverId']);

      final senderSnapshot = await senderRef.get();
      final receiverSnapshot = await receiverRef.get();

      if (!senderSnapshot.exists || !receiverSnapshot.exists) {
        throw Exception('L\'expéditeur ou le destinataire est introuvable');
      }

      final senderData = senderSnapshot.data() as Map<String, dynamic>;
      final receiverData = receiverSnapshot.data() as Map<String, dynamic>;

      // Exécuter la transaction
      await _firestore.runTransaction((transaction) async {
        final updatedSenderBalance = senderData['balance'] + transactionData['amount'];
        final updatedReceiverBalance = receiverData['balance'] - transactionData['amount'];

        // Mise à jour des balances
        transaction.update(senderRef, {'balance': updatedSenderBalance});
        transaction.update(receiverRef, {'balance': updatedReceiverBalance});

        // Mise à jour du statut de la transaction
        transaction.update(transactionDoc.reference, {'status': 'cancelled'});
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation : ${e.toString()}');
    }
  }

  Future<void> processWithdrawal({
    required String distributorId,
    required String clientId,
    required String clientName,
    required double amount,
    required String distributorName,
  }) async {
    return await _firestore.runTransaction((transaction) async {
      try {
        // Récupérer les documents du client et du distributeur
        final clientDoc = await transaction.get(
          _firestore.collection('users').doc(clientId),
        );
        final distributorDoc = await transaction.get(
          _firestore.collection('users').doc(distributorId),
        );

        if (!clientDoc.exists || !distributorDoc.exists) {
          throw Exception('Utilisateur ou distributeur non trouvé');
        }

        final client = UserModel.fromJson(clientDoc.data()!);
        final distributor = DistributorModel.fromJson(distributorDoc.data()!);

        // Vérifier les soldes
        if (client.balance < amount) {
          throw Exception('Solde client insuffisant');
        }

        if (distributor.balance < amount) {
          throw Exception('Solde distributeur insuffisant');
        }

        // Mettre à jour les soldes
        final newClientBalance = client.balance - amount;
        final newDistributorBalance = distributor.balance + amount;

        transaction.update(clientDoc.reference, {'balance': newClientBalance});
        transaction.update(distributorDoc.reference, {'balance': newDistributorBalance});

        // Créer la transaction
        final withdrawalData = TransactionModel(
          id: const Uuid().v4(),
          type: 'withdrawal',
          amount: amount,
          senderId: clientId,
          senderName: client.name,
          receiverId: distributorId,
          receiverName: distributorName,
          timestamp: DateTime.now(),
          isDebit: true,
          status: 'completed',
          distributorId: distributorId,
          distributorName: distributorName,
        ).toJson();

        transaction.set(
          _firestore.collection('transactions').doc(),
          withdrawalData,
        );
      } catch (e) {
        print('Erreur pendant le retrait: $e');
        rethrow;
      }
    });
  }

  Future<void> scheduleTransfer(ScheduledTransfer transfer) async {
    final response = await http.post(
      Uri.parse('https://your-laravel-app.com/api/scheduled-transfers'),
      body: jsonEncode(transfer.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la programmation du transfert');
    }
  }

}