// lib/models/scheduled_transfer.dart

class ScheduledTransfer {
  final String id;
  final String transactionId;
  final String senderUid;
  final String recipientPhone;
  final double amount;
  final String frequency;
  final DateTime scheduledTime;
  final String? status;
  final DateTime? lastExecuted;
  final DateTime? nextExecution;

  ScheduledTransfer({
    required this.id,
    required this.transactionId,
    required this.senderUid,
    required this.recipientPhone,
    required this.amount,
    required this.frequency,
    required this.scheduledTime,
    this.status,
    this.lastExecuted,
    this.nextExecution,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'senderUid': senderUid,
      'recipientPhone': recipientPhone,
      'amount': amount,
      'frequency': frequency,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status ?? 'scheduled',
      'lastExecuted': lastExecuted?.toIso8601String(),
      'nextExecution': nextExecution?.toIso8601String(),
    };
  }

  factory ScheduledTransfer.fromJson(Map<String, dynamic> json) {
    return ScheduledTransfer(
      id: json['id'],
      transactionId: json['transactionId'],
      senderUid: json['senderUid'],
      recipientPhone: json['recipientPhone'],
      amount: json['amount'].toDouble(),
      frequency: json['frequency'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      status: json['status'],
      lastExecuted: json['lastExecuted'] != null
          ? DateTime.parse(json['lastExecuted'])
          : null,
      nextExecution: json['nextExecution'] != null
          ? DateTime.parse(json['nextExecution'])
          : null,
    );
  }
}