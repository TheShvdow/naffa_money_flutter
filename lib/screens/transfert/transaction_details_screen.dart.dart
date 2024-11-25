import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailsScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  _TransactionDetailsScreenState createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final TransactionService _transferService = TransactionService();
  bool _isCancelling = false;

  String _getTransactionTypeLabel() {
    switch (widget.transaction.type) {
      case 'transfert':
        if (widget.transaction.senderId != null && widget.transaction.receiverId != null) {
          return 'Transfert d\'argent';
        }
        return 'Transfert d\'argent';
      case 'transfert multiple':
        return 'Transfert multiple';
      case 'failed_multiple_transfer':
        return 'Transfert multiple échoué';
      case 'transfert programmé':
        return 'Transfert programmé';
      case 'failed_schedule_transfer':
        return 'Transfert programmé échoué';
      case 'deposit':
        return 'Dépôt d\'argent';
      case 'withdrawal':
        return 'Retrait d\'argent';
      default:
        return 'Transaction';
    }
  }

  IconData _getTransactionIcon() {
    switch (widget.transaction.type) {
      case 'deposit':
        return Icons.account_balance_wallet;
      case 'withdrawal':
        return Icons.money_off;
      case 'transfert multiple':
        return Icons.people;
      case 'failed_multiple_transfer':
        return Icons.error_outline;
      case 'transfert':
        return widget.transaction.isDebit ? Icons.arrow_upward : Icons.arrow_downward;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getTransactionTitle() {
    switch (widget.transaction.type) {
      case 'deposit':
        return 'Dépôt';
      case 'withdrawal':
        return 'Retrait';
      case 'transfert ':
        return 'Transfert multiple';
      case 'failed_multiple_transfer':
        return 'Transfert échoué';
      case 'transfert':
        return widget.transaction.isDebit ? 'Envoyé' : 'Reçu';
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
                            widget.transaction.transactionId ?? 'N/A',
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
                            _formatDate(widget.transaction.timestamp),
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
                            '${widget.transaction.amount.toStringAsFixed(0)} FCFA',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Informations selon le type de transaction
                    if (widget.transaction.type == 'transfert' ||
                        widget.transaction.type == 'multiple_transfer' ||
                        widget.transaction.type == 'failed_multiple_transfer') ...[
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
                              widget.transaction.senderName ?? 'Non spécifié',
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
                              widget.transaction.receiverName ?? 'Non spécifié',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.transaction.type == 'deposit' && widget.transaction.distributorName != null)
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
                            child: pw.Text(widget.transaction.distributorName!),
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
    final file = File('${dir.path}/transaction_${widget.transaction.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareFiles(
      [file.path],
      text: 'Reçu de transaction Naffa Money',
    );
  }
  void _showCancellationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,  // Empêcher la fermeture en tapant à l'extérieur
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Annuler le transfert'),
          content: Text('Êtes-vous sûr de vouloir annuler ce transfert ?\n\nCette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Non, garder'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelTransfer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Oui, annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelTransfer() async {
    if (widget.transaction.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'annuler : ID de transaction manquant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isCancelling = true);

      await _transferService.cancelTransaction(widget.transaction.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transfert annulé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();  // Retour à l'écran précédent
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si la transaction peut être annulée
    final canCancel = widget.transaction.type == 'transfert' &&
        widget.transaction.isDebit &&
        DateTime.now().difference(widget.transaction.timestamp).inMinutes <= 30 &&
        widget.transaction.status != 'completed' &&  // Vérifier que le destinataire n'a pas déjà retiré l'argent
        widget.transaction.status != 'withdrawn'; // Exemple de statut indiquant que le destinataire a retiré l'argent

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
                  backgroundColor: widget.transaction.isDebit ? Colors.red.shade50 : Colors.green.shade50,
                  child: Icon(
                    _getTransactionIcon(),
                    color: widget.transaction.isDebit ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(
                  _getTransactionTitle(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${widget.transaction.isDebit ? '-' : '+'} ${widget.transaction.amount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    color: widget.transaction.isDebit ? Colors.red : Colors.green,
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
                    _buildInfoRow('ID Transaction', widget.transaction.id ?? 'N/A'),
                    Divider(),
                    _buildInfoRow('Type', _getTransactionTypeLabel()),
                    Divider(),
                    _buildInfoRow('Date', _formatDate(widget.transaction.timestamp)),
                    Divider(),
                    _buildInfoRow('Status', widget.transaction.status),
                    if (widget.transaction.type == 'transfert' ||
                        widget.transaction.type == 'transfert multiple' ||
                        widget.transaction.type == 'failed_multiple_transfer') ...[
                      Divider(),
                      _buildInfoRow('Expéditeur', widget.transaction.senderName ?? 'Non spécifié'),
                      Divider(),
                      _buildInfoRow('Destinataire', widget.transaction.receiverName ?? 'Non spécifié'),
                    ],
                    if (widget.transaction.type == 'deposit' && widget.transaction.distributorName != null) ...[
                      Divider(),
                      _buildInfoRow('Distributeur', widget.transaction.distributorName!),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.download),
                    label: Text('Télécharger le reçu'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _generateAndSharePDF,
                  ),
                ),
                if (canCancel) ...[
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(_isCancelling ? Icons.hourglass_empty : Icons.cancel),
                      label: Text(_isCancelling ? 'Annulation...' : 'Annuler'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isCancelling ? null : _showCancellationDialog,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

}