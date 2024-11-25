class ScheduledTransfer {
  final String id;
  final double amount;
  final String recipientId;
  final String frequence;
  final DateTime scheduledTime;

  ScheduledTransfer({
    required this.id,
    required this.amount,
    required this.recipientId,
    required this.frequence,
    required this.scheduledTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'recipientId': recipientId,
      'frequece' : frequence,
      'scheduledTime': scheduledTime.toIso8601String(),
    };
  }
}