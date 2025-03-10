import 'package:cloud_firestore/cloud_firestore.dart';

class DistributorModel {
  final String id;
  final String name;
  final String phone;
  final String profilePicture;
  final String email;
  double balance;
  final String address;
  final bool isActive;
  final DateTime createdAt;

  DistributorModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profilePicture = '',
    required this.email,
    this.balance = 0.0,
    required this.address,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'profilePicture': profilePicture,
    'balance': balance,
    'address': address,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'type': 'distributor',
  };

  factory DistributorModel.fromJson(Map<String, dynamic> json) {
    final createdAt = (json['createdAt'] is Timestamp)
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.parse(json['createdAt']);

    return DistributorModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      email: json['email'],
      balance: json['balance']?.toDouble() ?? 0.0,
      address: json['address'],
      isActive: json['isActive'] ?? true,
      createdAt: createdAt,
    );
  }
}