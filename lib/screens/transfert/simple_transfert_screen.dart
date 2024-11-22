import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naffa_money/services/transaction_service.dart';
import 'package:naffa_money/services/auth_service.dart';

class SimpleTransferScreen extends StatefulWidget {
  @override
  _SimpleTransferScreenState createState() => _SimpleTransferScreenState();
}

class _SimpleTransferScreenState extends State<SimpleTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final TransferService _transferService = TransferService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _receiverName;

  Future<void> _verifyReceiver(String phone) async {
    final receiverInfo = await _transferService.getReceiverInfo(phone);
    if (receiverInfo != null) {
      _receiverName = receiverInfo.name;
      setState(() {});
    }
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Générer un ID de transaction unique
      final String transactionId = FirebaseFirestore.instance.collection('transactions').doc().id;

      await _transferService.transferMoney(
        transactionId: transactionId, // Ajouter l'ID à la méthode
        senderUid: currentUser.id,
        receiverPhone: _phoneController.text.trim(),
        amount: double.parse(_amountController.text.replaceAll(' ', '')),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfert effectué avec succès (ID: $transactionId)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copier ID',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: transactionId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ID copié dans le presse-papiers'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du transfert : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfert simple'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Champs de saisie et bouton pour le transfert simple
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro du destinataire',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '+221 XX XXX XX XX',
                ),
                keyboardType: TextInputType.phone,
                onChanged: _verifyReceiver,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_receiverName != null)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Destinataire: $_receiverName',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleTransfer,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Effectuer le transfert',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}