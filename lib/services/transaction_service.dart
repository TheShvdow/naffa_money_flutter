import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> transferMoney({
    required String senderId,
    required String receiverId,
    required double amount,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Obtenir les documents des deux utilisateurs
        final senderDoc = await transaction.get(
            _firestore.collection('users').doc(senderId)
        );
        final receiverDoc = await transaction.get(
            _firestore.collection('users').doc(receiverId)
        );

        double senderBalance = senderDoc.data()?['balance'] ?? 0;
        double receiverBalance = receiverDoc.data()?['balance'] ?? 0;

        // Vérifier si le solde est suffisant
        if (senderBalance < amount) {
          throw Exception('Solde insuffisant');
        }

        // Mettre à jour les soldes
        transaction.update(
            senderDoc.reference,
            {'balance': senderBalance - amount}
        );
        transaction.update(
            receiverDoc.reference,
            {'balance': receiverBalance + amount}
        );

        // Enregistrer la transaction
        transaction.set(
            _firestore.collection('transactions').doc(),
            {
              'senderId': senderId,
              'receiverId': receiverId,
              'amount': amount,
              'timestamp': FieldValue.serverTimestamp(),
            }
        );
      });
    } catch (e) {
      throw e;
    }
  }
}
