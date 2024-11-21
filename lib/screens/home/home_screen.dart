import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naffa_money/screens/profile/profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:naffa_money/screens/withdrawal/withdrawal_screen.dart';
import '../../models/user_model.dart';
import '../transfert/transfert_screen.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String _generateQRData(Map<String, dynamic> userData) {
    final qrData = {
      'userId': _auth.currentUser?.uid,
      'name': userData['name'],
      'phone': userData['phone'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return json.encode(qrData);
  }

  Widget _buildBalanceAndQRSection(Map<String, dynamic> userData) {
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          // Section solde (côté gauche)
          Expanded(
            flex: 3, // Prend 60% de l'espace
            child: Container(
              height: 180, // Hauteur fixe pour correspondre au QR
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
                  Text(
                    'Solde disponible',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${(userData['balance'] ?? 0.0).toStringAsFixed(0)} FCFA',
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
          SizedBox(width: 16), // Espacement entre les deux éléments
          // Section QR (côté droit)
          Expanded(
            flex: 2, // Prend 40% de l'espace
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
                height: 180, // Même hauteur que la section solde
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

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final user = UserModel.fromJson(userData);

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
                    _buildBalanceAndQRSection(userData),
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
            MaterialPageRoute(builder: (context) => TransferScreen()),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: _firestore
              .collection('transactions')
              .where('clientId', isEqualTo: _auth.currentUser?.uid)
              .snapshots()
              .map((snapshot) => snapshot.docs),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final clientTransactions = snapshot.data ?? [];

            return StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _firestore
                  .collection('transactions')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .snapshots()
                  .map((snapshot) => snapshot.docs),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final distributorTransactions = snapshot.data ?? [];
                final allTransactions = [...clientTransactions, ...distributorTransactions];

                allTransactions.sort((a, b) {
                  final timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
                  final timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
                  return timestampB.compareTo(timestampA);
                });

                if (allTransactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Aucune transaction',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = allTransactions[index].data() as Map<String, dynamic>;
                    return _buildTransactionItem(transaction);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isDebit = transaction['isDebit'] ?? false;
    final amount = transaction['amount']?.toString() ?? '0';
    final otherPartyName = isDebit
        ? transaction['receiverName']
        : transaction['senderName'];
    final timestamp = transaction['timestamp'] as Timestamp?;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          color: isDebit ? Colors.red : Colors.green,
        ),
      ),
      title: Text(isDebit
          ? 'Envoyé à $otherPartyName'
          : 'Reçu de $otherPartyName'
      ),
      subtitle: Text(
          timestamp != null
              ? _formatDate(timestamp.toDate())
              : 'Date inconnue'
      ),
      trailing: Text(
        '${isDebit ? '-' : '+'} $amount FCFA',
        style: TextStyle(
          color: isDebit ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
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