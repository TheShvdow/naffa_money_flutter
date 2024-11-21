class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String profilePucture;
  double balance;
  List<String> contacts;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profilePucture='',
    this.email = '',
    this.balance = 0.0,
    this.contacts = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'photo':profilePucture,
    'balance': balance,
    'contacts': contacts,
    'type':'Client',
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    phone: json['phone'],
    email: json['email'] ?? '',
    profilePucture: json['profilePucture'] ?? '',
    balance: json['balance']?.toDouble() ?? 0.0,
    contacts: List<String>.from(json['contacts'] ?? []),
  );
}