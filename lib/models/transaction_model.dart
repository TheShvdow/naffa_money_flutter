// lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String? id;
  final String? transactionId;
  final String type;  // 'transfer', 'multiple_transfer', 'failed_multiple_transfer', 'deposit', 'withdrawal'
  final double amount;
  final String? senderId;
  final String? senderName;
  final String? senderPhone;
  final String? receiverId;
  final String? receiverName;
  final String? receiverPhone;
  final DateTime timestamp;
  final bool isDebit;
  final String? distributorName;
  final String? distributorId;
  final String status;  // 'completed', 'failed', 'pending', 'cancelled'
  final String? failureReason;
  final List<dynamic>? failedTransfers;  // Pour stocker les transferts échoués dans un transfert multiple
  final List<dynamic>? successfulTransfers;  // Pour stocker les transferts réussis dans un transfert multiple
  final int? totalReceivers;  // Nombre total de destinataires dans un transfert multiple

  TransactionModel({
    this.id,
    this.transactionId,
    required this.type,
    required this.amount,
    this.senderId,
    this.senderName,
    this.senderPhone,
    this.receiverId,
    this.receiverName,
    this.receiverPhone,
    required this.timestamp,
    required this.isDebit,
    this.distributorName,
    this.distributorId,
    this.status = 'pending',
    this.failureReason,
    this.failedTransfers,
    this.successfulTransfers,
    this.totalReceivers,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString(),
      transactionId: json['transactionId']?.toString(),
      type: json['type'] ?? 'transfert',
      amount: (json['amount'] ?? 0.0).toDouble(),
      senderId: json['senderId']?.toString(),
      senderName: json['senderName']?.toString(),
      senderPhone: json['senderPhone']?.toString(),
      receiverId: json['receiverId']?.toString(),
      receiverName: json['receiverName']?.toString(),
      receiverPhone: json['receiverPhone']?.toString(),
      distributorName: json['distributorName'],
      distributorId: json['distributorId'],
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isDebit: json['isDebit'] ?? false,
      status: json['status']?.toString() ?? 'pending',
      failureReason: json['failureReason']?.toString(),
      failedTransfers: json['failedTransfers'] as List<dynamic>?,
      successfulTransfers: json['successfulTransfers'] as List<dynamic>?,
      totalReceivers: json['totalReceivers'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'type': type,
      'amount': amount,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDebit': isDebit,
      'distributorName': distributorName,
      'distributorId': distributorId,
      'status': status,
      'failureReason': failureReason,
      'failedTransfers': failedTransfers,
      'successfulTransfers': successfulTransfers,
      'totalReceivers': totalReceivers,
    };
  }

  // Méthode pour créer une copie de la transaction avec des modifications
  TransactionModel copyWith({
    String? id,
    String? transactionId,
    String? type,
    double? amount,
    String? senderId,
    String? senderName,
    String? senderPhone,
    String? receiverId,
    String? receiverName,
    String? receiverPhone,
    DateTime? timestamp,
    bool? isDebit,
    String? distributorName,
    String? distributorId,
    String? status,
    String? failureReason,
    List<dynamic>? failedTransfers,
    List<dynamic>? successfulTransfers,
    int? totalReceivers,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      timestamp: timestamp ?? this.timestamp,
      isDebit: isDebit ?? this.isDebit,
      distributorName: distributorName ?? this.distributorName,
      distributorId: distributorId ?? this.distributorId,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      failedTransfers: failedTransfers ?? this.failedTransfers,
      successfulTransfers: successfulTransfers ?? this.successfulTransfers,
      totalReceivers: totalReceivers ?? this.totalReceivers,
    );
  }

  // Méthode pour comparer deux transactions
  bool equals(TransactionModel other) {
    return id == other.id &&
        transactionId == other.transactionId &&
        type == other.type &&
        amount == other.amount &&
        senderId == other.senderId &&
        receiverId == other.receiverId &&
        isDebit == other.isDebit;
  }
}