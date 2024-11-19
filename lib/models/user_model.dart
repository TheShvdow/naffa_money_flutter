class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  double balance;
  List<String> contacts;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.balance = 0.0,
    this.contacts = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'balance': balance,
    'contacts': contacts,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    phone: json['phone'],
    email: json['email'] ?? '',
    balance: json['balance']?.toDouble() ?? 0.0,
    contacts: List<String>.from(json['contacts'] ?? []),
  );
}