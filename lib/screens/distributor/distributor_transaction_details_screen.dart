import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class DistributorTransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const DistributorTransactionDetailsScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  Future<void> _generateAndSharePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final isDeposit = transaction['type'] == 'deposit';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Center(
                child: pw.Text(
                  'Reçu de ${isDeposit ? "Dépôt" : "Retrait"}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Informations de la transaction
              pw.Text('Date: ${_formatDate(transaction['timestamp'].toDate())}'),
              pw.SizedBox(height: 10),
              pw.Text('Type: ${isDeposit ? "Dépôt" : "Retrait"}'),
              pw.SizedBox(height: 10),
              pw.Text('Montant: ${transaction['amount']} FCFA'),
              pw.SizedBox(height: 10),
              pw.Text('Client: ${transaction['userName']}'),
              if (transaction['description'] != null) ...[
                pw.SizedBox(height: 10),
                pw.Text('Description: ${transaction['description']}'),
              ],

              // Pied de page
              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Naffa Money - Service de transfert d\'argent',
                  style: pw.TextStyle(
                    fontSize: 10,
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
    final file = File('${dir.path}/transaction_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareFiles(
      [file.path],
      text: 'Reçu de transaction Naffa Money',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction['type'] == 'deposit';
    final timestamp = transaction['timestamp'] as Timestamp;

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
                  backgroundColor: isDeposit ? Colors.green.shade50 : Colors.blue.shade50,
                  child: Icon(
                    isDeposit ? Icons.add : Icons.remove,
                    color: isDeposit ? Colors.green : Colors.blue,
                  ),
                ),
                title: Text(
                  isDeposit ? 'Dépôt' : 'Retrait',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${isDeposit ? '+' : '-'} ${transaction['amount']} FCFA',
                  style: TextStyle(
                    color: isDeposit ? Colors.green : Colors.blue,
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
                    _buildInfoRow('Date', _formatDate(timestamp.toDate())),
                    Divider(),
                    _buildInfoRow('Client', transaction['userName'] ?? 'Inconnu'),
                    if (transaction['description'] != null) ...[
                      Divider(),
                      _buildInfoRow('Description', transaction['description']),
                    ],
                    Divider(),
                    _buildInfoRow('Statut', 'Complété'),
                    Divider(),
                    _buildInfoRow('ID Transaction', transaction['id'] ?? 'N/A'),
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
}