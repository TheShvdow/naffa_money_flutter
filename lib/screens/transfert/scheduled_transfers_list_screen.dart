// lib/screens/scheduled_transfers_list_screen.dart

import 'package:flutter/material.dart';
import '../../models/scheduled_transfert.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import 'scheduled_transfert_screen.dart';

class ScheduledTransfersListScreen extends StatelessWidget {
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();

  ScheduledTransfersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transferts programmés'),
      ),
      body: FutureBuilder<String?>(
        future: _authService.getCurrentUserId(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<ScheduledTransfer>>(
            stream: _transactionService.getScheduledTransfers(userSnapshot.data!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('Aucun transfert programmé'),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final transfer = snapshot.data![index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('${transfer.amount} FCFA'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Destinataire: ${transfer.recipientPhone}'),
                          Text('Fréquence: ${transfer.frequency}'),
                          Text('Prochaine exécution: ${_formatDate(transfer.nextExecution)}'),
                          Text('Statut: ${transfer.status}'),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Modifier'),
                          ),
                          PopupMenuItem(
                            value: 'cancel',
                            child: Text('Annuler'),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'cancel') {
                            await _handleCancelTransfer(context, transfer);
                          } else if (value == 'edit') {
                            await _handleEditTransfer(context, transfer);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduledTransferScreen(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non programmé';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _handleCancelTransfer(
      BuildContext context,
      ScheduledTransfer transfer,
      ) async {
    try {
      await _transactionService.cancelScheduledTransfer(transfer.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transfert programmé annulé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'annulation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleEditTransfer(
      BuildContext context,
      ScheduledTransfer transfer,
      ) async {
    // Navigate to edit screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduledTransferScreen(
          transfer: transfer,
        ),
      ),
    );
  }
}