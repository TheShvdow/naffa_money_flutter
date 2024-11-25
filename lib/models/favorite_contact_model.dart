// models/favorite_contact_model.dart
class FavoriteContact {
  final String? id;
  final String name;
  final String phone;
  final String userId;

  FavoriteContact({
    this.id,
    required this.name,
    required this.phone,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'userId': userId,
  };

  factory FavoriteContact.fromJson(Map<String, dynamic> json) => FavoriteContact(
    id: json['id'],
    name: json['name'],
    phone: json['phone'],
    userId: json['userId'],
  );
}