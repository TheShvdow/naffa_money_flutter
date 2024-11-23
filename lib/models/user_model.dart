class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String profilePicture; // Corrige cette propriété
  final double balance;
  final List<String> contacts;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.profilePicture, // Corrige cette propriété
    required this.balance,
    required this.contacts,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'profilePicture': profilePicture, // Corrige cette propriété
      'balance': balance,
      'contacts': contacts,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '', // Fournit une valeur par défaut vide
      name: json['name'] ?? '', // Fournit une valeur par défaut vide
      phone: json['phone'] ?? '', // Fournit une valeur par défaut vide
      email: json['email'] ?? '', // Fournit une valeur par défaut vide
      profilePicture: json['profilePicture'] ?? '', // Fournit une valeur par défaut vide
      balance: (json['balance'] ?? 0).toDouble(), // Assure que `balance` est un double
      contacts: List<String>.from(json['contacts'] ?? []), // Fournit une liste vide par défaut
    );
  }

}
