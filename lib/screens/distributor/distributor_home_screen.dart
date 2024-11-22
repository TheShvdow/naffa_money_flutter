// lib/screens/distributor/distributor_home_screen.dart

import 'package:flutter/material.dart';
import 'package:naffa_money/qr_code/qr_code_screen.dart';
import 'package:naffa_money/screens/distributor/deposit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/distributor_model.dart';
import 'distributor_transaction_details_screen.dart';

class DistributorHomeScreen extends StatefulWidget {
  @override
  _DistributorHomeScreenState createState() => _DistributorHomeScreenState();
}

class _DistributorHomeScreenState extends State<DistributorHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Distributeur'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final distributorData = snapshot.data!.data() as Map<String, dynamic>;
          final distributor = DistributorModel.fromJson(distributorData);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(distributor),
                SizedBox(height: 20),
                _buildActionButtons(context),
                SizedBox(height: 20),
                _buildTransactionsList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(DistributorModel distributor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde disponible',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            '${distributor.balance.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            distributor.name,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.camera_alt),
            label: Text('Scanner QR'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QRScannerScreen(),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Dépôt'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DistributorDepositScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions récentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('transactions')
              .where('distributorId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final transactions = snapshot.data!.docs;

            if (transactions.isEmpty) {
              return Center(
                child: Text(
                  'Aucune transaction',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index].data() as Map<String, dynamic>;
                return _buildTransactionItem(transaction);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isDeposit = transaction['type'] == 'deposit';
    final amount = transaction['amount']?.toString() ?? '0';
    final timestamp = transaction['timestamp'] as Timestamp?;
    final userName = transaction['userName'] ?? 'Utilisateur';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DistributorTransactionDetailsScreen(
              transaction: transaction,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isDeposit ? Colors.green.shade100 : Colors.blue.shade100,
            child: Icon(
              isDeposit ? Icons.add : Icons.remove,
              color: isDeposit ? Colors.green : Colors.blue,
            ),
          ),
          title: Text(
            isDeposit ? 'Dépôt de $userName' : 'Retrait pour $userName',
          ),
          subtitle: Text(
              timestamp != null
                  ? _formatDate(timestamp.toDate())
                  : 'Date inconnue'
          ),
          trailing: Text(
            '${isDeposit ? '+' : '-'} $amount FCFA',
            style: TextStyle(
              color: isDeposit ? Colors.green : Colors.blue,
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