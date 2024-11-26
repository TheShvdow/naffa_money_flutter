class ScheduledTransfer {
  final String id;
  final String transactionId;
  final String senderUid;
  final String recipientPhone;
  final double amount;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final DateTime scheduledTime;

  ScheduledTransfer({
    required this.id,
    required this.transactionId,
    required this.senderUid,
    required this.recipientPhone,
    required this.amount,
    required this.frequency,
    required this.scheduledTime,
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
    };
  }
}