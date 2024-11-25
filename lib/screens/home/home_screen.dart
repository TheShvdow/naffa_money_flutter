import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naffa_money/screens/profile/profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:naffa_money/screens/withdrawal/withdrawal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_service.dart';
import '../transfert/transaction_details_screen.dart.dart';
import '../transfert/transfert_type_screen.dart';
import '../../models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  bool _isBalanceHidden = false;
  Map<String, dynamic>? _userData;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }


  Future<void> _loadBalanceVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isBalanceHidden = prefs.getBool('isBalanceHidden') ?? false;
      });
    } catch (e) {
      print('Erreur lors du chargement de la visibilité du solde: $e');
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isBalanceHidden = !_isBalanceHidden;
      });
      await prefs.setBool('isBalanceHidden', _isBalanceHidden);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la visibilité du solde: $e');
    }
  }

  String _generateQRData(Map<String, dynamic> userData) {
    final qrData = {
      'userId': _auth.currentUser?.uid,
      'name': userData['name'],
      'phone': userData['phone'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    String jsonData = json.encode(qrData);
    return jsonData;
  }

  Widget _buildBalanceAndQRSection(Map<String, dynamic> userData) {
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: 180,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade800],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Solde disponible',
                        style: TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBalanceHidden = !_isBalanceHidden;
                          });
                          SharedPreferences.getInstance().then((prefs) {
                            prefs.setBool('isBalanceHidden', _isBalanceHidden);
                          });
                        },
                        child: Icon(
                          _isBalanceHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _isBalanceHidden
                        ? '• • • • • • FCFA'
                        : '${(userData['balance'] ?? 0.0).toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mon QR Code',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          QrImageView(
                            data: _generateQRData(userData),
                            version: QrVersions.auto,
                            size: 300.0,
                            backgroundColor: Colors.white,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Présentez ce code à un distributeur\npour effectuer une opération',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Fermer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QrImageView(
                      data: _generateQRData(userData),
                      version: QrVersions.auto,
                      size: 120.0,
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Appuyez pour\nagrandir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(child: Text('Erreur: ${userSnapshot.error}'));
          }

          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text('Aucune donnée utilisateur'));
          }

          final newUserData = userSnapshot.data!.data() as Map<String, dynamic>;
          if (_userData == null || newUserData['balance'] != _userData!['balance']) {
            _userData = newUserData;
          }

          final user = UserModel.fromJson(_userData!);

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade100, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue,
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bienvenue',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.person, color: Colors.blue),
                  tooltip: 'Profil',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(user: user),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(Icons.logout, color: Colors.red),
                    tooltip: 'Déconnexion',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Déconnexion'),
                          content: Text('Voulez-vous vraiment vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                'Déconnexion',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _authService.signOut();
                      }
                    },
                  ),
                ),
              ],
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceAndQRSection(_userData!),
                    const SizedBox(height: 10),
                    _buildQuickActions(context),
                    const SizedBox(height: 20),
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Dans la méthode _buildQuickActions de votre HomeScreen

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      children: [
        _buildActionButton(
          Icons.send,
          'Envoyer',
              () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TransferTypeScreen()),
          ),
        ),
        _buildActionButton(
          Icons.qr_code,
          'Retirer',
              () => Navigator.push(
            context,
              MaterialPageRoute(builder: (context) => WithdrawalScreen()),
          ),
        ),
        _buildActionButton(Icons.phone_android, 'Crédit',
              () {}
          /* => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AirtimeScreen()),
          ), */
        ),
        _buildActionButton(Icons.receipt_long, 'Factures', () {}
          /* => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BillPaymentScreen()),
          ), */
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final userId = _auth.currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.filter_list),
                onSelected: (String filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Text('Toutes'),
                  ),
                  PopupMenuItem(
                    value: 'sent',
                    child: Text('Envoyées'),
                  ),
                  PopupMenuItem(
                    value: 'received',
                    child: Text('Reçues'),
                  ),
                  PopupMenuItem(
                    value: 'deposit',
                    child: Text('Dépôts'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une transaction...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Container(
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .where(Filter.or(
              Filter('senderId', isEqualTo: userId),
              Filter('receiverId', isEqualTo: userId),
              Filter('clientId', isEqualTo: userId),
            ))
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var transactions = snapshot.data?.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['type'] == 'deposit') {
                  data['isDebit'] = false;
                } else {
                  data['isDebit'] = data['senderId'] == userId;
                }
                return TransactionModel.fromJson(data);
              }).toList() ?? [];

              // Application des filtres
              if (_searchQuery.isNotEmpty) {
                transactions = transactions.where((transaction) {
                  return transaction.receiverName?.toLowerCase().contains(_searchQuery) == true ||
                      transaction.senderName?.toLowerCase().contains(_searchQuery) == true ||
                      transaction.amount.toString().contains(_searchQuery) ||
                      transaction.type.toLowerCase().contains(_searchQuery);
                }).toList();
              }

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
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aucune transaction trouvée',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _buildTransactionItem(transaction);
                },
              );
            },
          ),
        ),
      ],
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isDebit ? Colors.red.shade50 : Colors.green.shade50,
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
                : 'Reçu de ${transaction.senderName ?? 'Inconnu'}')
        ),
        subtitle: Text(_formatDate(transaction.timestamp)),
        trailing: Text(
          '${transaction.isDebit ? '-' : '+'} ${transaction.amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            color: transaction.isDebit ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
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