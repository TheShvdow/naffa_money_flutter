import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:naffa_money/screens/profile/profile_screen.dart';
import 'package:naffa_money/screens/withdrawal/withdrawal_screen.dart';
import 'package:naffa_money/screens/transfert/transfert_type_screen.dart';
import 'dart:convert';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../transfert/transaction_details_screen.dart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isBalanceHidden = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Vérification supplémentaire pour les données nulles
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Aucune donnée utilisateur trouvée'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(userData),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildBalanceCard(userData),
                          _buildQuickActions(),
                          _buildTransactionHeader(),
                          _buildTransactionsStream(userData),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic> userData) {
    // Utilisation de ?? pour gérer les valeurs nulles
    final balance = (userData['balance'] as num?) ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[600]!, Colors.blue[800]!],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde disponible',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                child: Icon(
                  _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isBalanceHidden
                    ? '• • • • • • FCFA'
                    : '${balance.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _showQRCodeDialog(userData),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[400]!,
                        Colors.cyanAccent[400]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: _generateQRData(userData),
                    version: QrVersions.auto,
                    size: 60,
                    backgroundColor: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  String _generateQRData(Map<String, dynamic> userData) {
    final qrData = {
      'userId': _auth.currentUser?.uid,
      'name': userData['name'],
      'phone': userData['phone'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return json.encode(qrData);
  }

  void _showQRCodeDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mon QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: _generateQRData(userData),
                version: QrVersions.auto,
                size: 300,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Présentez ce code à un distributeur\npour effectuer une opération',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> userData) {
    final user = UserModel.fromJson(userData);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(user: user),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Déconnexion',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await _authService.signOut();
                      if (!context.mounted) return;

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                            (route) => false,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur lors de la déconnexion. Veuillez réessayer.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildQRSection(Map<String, dynamic> userData) {
    final qrData = {
      'userId': _auth.currentUser?.uid,
      'name': userData['name'],
      'phone': userData['phone'],
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        data: json.encode(qrData),
        version: QrVersions.auto,
        size: 80,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            Icons.send,
            'Envoyer',
            Colors.blue,
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TransferTypeScreen()),
            ),
          ),
          _buildActionButton(
            Icons.qr_code_scanner,
            'Retirer',
            Colors.purple,
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WithdrawalScreen()),
            ),
          ),
          _buildActionButton(
            Icons.phone_android,
            'Crédit',
            Colors.orange,
                () {},
          ),
          _buildActionButton(
            Icons.receipt_long,
            'Factures',
            Colors.green,
                () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(Map<String, dynamic> userData) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () {},
              ),
            ],
          ),
          _buildSearchBar(),

        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une transaction...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildTransactionsStream(Map<String, dynamic> userData) {
    final userId = _auth.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('transactions')
          .where(Filter.or(
        Filter('senderId', isEqualTo: userId),
        Filter('receiverId', isEqualTo: userId),
        Filter('clientId', isEqualTo: userId),
      ))
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var transactions = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['type'] == 'deposit') {
            data['isDebit'] = false;
          } else {
            data['isDebit'] = data['senderId'] == userId;
          }
          return TransactionModel.fromJson(data);
        }).toList();

        // Application du filtre de recherche
        if (_searchQuery.isNotEmpty) {
          transactions = transactions.where((transaction) {
            return transaction.receiverName?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                transaction.senderName?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
                transaction.amount.toString().contains(_searchQuery) ||
                transaction.type.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Application du filtre de catégorie
        if (_selectedFilter != 'all') {
          transactions = transactions.where((transaction) {
            switch (_selectedFilter) {
              case 'sent':
                return transaction.isDebit;
              case 'received':
                return !transaction.isDebit && transaction.type != 'deposit';
              case 'deposit':
                return transaction.type == 'deposit';
              default:
                return true;
            }
          }).toList();
        }

        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'Aucune transaction trouvée pour : $_searchQuery'
                    : 'Aucune transaction à afficher',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      },
    );
  }

  Widget _buildTransactionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transactions récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (String filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('Toutes'),
                  ),
                  const PopupMenuItem(
                    value: 'sent',
                    child: Text('Envoyées'),
                  ),
                  const PopupMenuItem(
                    value: 'received',
                    child: Text('Reçues'),
                  ),
                  const PopupMenuItem(
                    value: 'deposit',
                    child: Text('Dépôts'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une transaction...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              transaction: transaction,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: transaction.isDebit ? Colors.red[50] : Colors.green[50],
            child: Icon(
              transaction.isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: transaction.isDebit ? Colors.red : Colors.green,
            ),
          ),
          title: Text(
            transaction.type == 'deposit'
                ? 'Dépôt de ${transaction.distributorName ?? 'Distributeur'}'
                : (transaction.isDebit
                ? 'Envoyé à ${transaction.receiverName ?? 'Inconnu'}'
                : 'Reçu de ${transaction.senderName ?? 'Inconnu'}'),
          ),
          subtitle: Text(_formatDate(transaction.timestamp)),
          trailing: Text(
            '${transaction.isDebit ? "-" : "+"} ${transaction.amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              color: transaction.isDebit ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} minutes';
      }
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays == 1) {
      return 'Hier';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}