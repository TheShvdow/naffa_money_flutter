import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_model.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({Key? key, required this.transaction}) : super(key: key);

  String _getTransactionTypeLabel() {
    switch(transaction.type) {
      case 'transfer':
        if (transaction.senderId != null && transaction.receiverId != null) {
          return 'Transfert';
        }
        return 'Transfert d\'argent';
      case 'multiple_transfert':
        return 'Transfert multiple';
      case 'failed_multiple_transfer':
        return 'Transfert multiple échoué';
      case 'deposit':
        return 'Dépôt d\'argent';
      case 'withdrawal':
        return 'Retrait d\'argent';
      default:
        return 'Transaction';
    }
  }

  IconData _getTransactionIcon() {
    switch(transaction.type) {
      case 'deposit':
        return Icons.account_balance_wallet;
      case 'withdrawal':
        return Icons.money_off;
      case 'multiple_transfert':
        return Icons.people;
      case 'failed_multiple_transfert':
        return Icons.error_outline;
      case 'transfer':
        return transaction.isDebit ? Icons.arrow_upward : Icons.arrow_downward;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getTransactionTitle() {
    switch(transaction.type) {
      case 'deposit':
        return 'Dépôt';
      case 'withdrawal':
        return 'Retrait';
      case 'multiple_transfert':
        return 'Transfert multiple';
      case 'failed_multiple_transfert':
        return 'Transfert échoué';
      case 'transfer':
        return transaction.isDebit ? 'Envoyé' : 'Reçu';
      default:
        return 'Transaction';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSharePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête
              pw.Center(
                child: pw.Text(
                  'Reçu de ${_getTransactionTypeLabel()}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 50),

              // Tableau des informations
              pw.Container(
                width: 400,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  children: [
                    // En-tête du tableau
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue200,
                      ),
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            'Détails',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            'Informations',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Ligne ID Transaction
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            'ID Transaction',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            transaction.transactionId ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    // Ligne Type de transaction
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            'Type',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            _getTransactionTypeLabel(),
                          ),
                        ),
                      ],
                    ),
                    // Ligne Date
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            _formatDate(transaction.timestamp),
                          ),
                        ),
                      ],
                    ),
                    // Ligne Montant
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                      ),
                      children: [
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            'Montant',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: pw.EdgeInsets.all(10),
                          child: pw.Text(
                            '${transaction.amount.toStringAsFixed(0)} FCFA',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Informations selon le type de transaction
                    if (transaction.type == 'transfert' ||
                        transaction.type == 'multiple_transfer' ||
                        transaction.type == 'failed_multiple_transfer') ...[
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            child: pw.Text(
                              'Expéditeur',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            child: pw.Text(
                              transaction.senderName ?? 'Non spécifié',
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            child: pw.Text(
                              'Destinataire',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            child: pw.Text(
                              transaction.receiverName ?? 'Non spécifié',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (transaction.type == 'deposit' && transaction.distributorName != null)
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            child: pw.Text(
                              'Distributeur',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(10),
                            child: pw.Text(transaction.distributorName!),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Pied de page
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey),
              pw.Center(
                child: pw.Text(
                  'Naffa Money - Votre service de transfert d\'argent de confiance',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/transaction_${transaction.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareFiles(
      [file.path],
      text: 'Reçu de transaction Naffa Money',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la transaction'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _generateAndSharePDF,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et statut
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.isDebit ? Colors.red.shade50 : Colors.green.shade50,
                  child: Icon(
                    _getTransactionIcon(),
                    color: transaction.isDebit ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(
                  _getTransactionTitle(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${transaction.isDebit ? '-' : '+'} ${transaction.amount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: transaction.isDebit ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Informations détaillées
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('ID Transaction', transaction.id ?? 'N/A'),
                    Divider(),
                    _buildInfoRow('Type', _getTransactionTypeLabel()),
                    Divider(),
                    _buildInfoRow('Date', _formatDate(transaction.timestamp)),
                    if (transaction.type == 'transfert' ||
                        transaction.type == 'multiple_transfer' ||
                        transaction.type == 'failed_multiple_transfer') ...[
                      Divider(),
                      _buildInfoRow('Expéditeur', transaction.senderName ?? 'Non spécifié'),
                      Divider(),
                      _buildInfoRow('Destinataire', transaction.receiverName ?? 'Non spécifié'),
                    ],
                    if (transaction.type == 'deposit' && transaction.distributorName != null) ...[
                      Divider(),
                      _buildInfoRow('Distributeur', transaction.distributorName!),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Bouton de téléchargement
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.download),
                label: Text('Télécharger le reçu'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: _generateAndSharePDF,
              ),
            ),
          ],
        ),
      ),
    );
  }
}