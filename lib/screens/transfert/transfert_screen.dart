// lib/screens/transfer/transfer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';

class TransferScreen extends StatefulWidget {
  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TransferService _transferService = TransferService();
  final AuthService _authService = AuthService();

  bool _fraisTransfertActif = true; // valeur par défaut
  bool _isLoading = false;
  String? _receiverName;

  Future<void> _verifyReceiver(String phone) async {
    if (phone.length < 9) return;

    try {
      final receiver = await _transferService.getReceiverInfo(phone);
      if (mounted) {
        setState(() {
          _receiverName = receiver?.name;
        });
      }
    } catch (e) {
      print('Erreur de vérification: $e');
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

      await _transferService.transferMoney(
        senderUid: currentUser.id,
        receiverPhone: _phoneController.text.trim(),
        amount: double.parse(_amountController.text.replaceAll(' ', '')),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfert effectué avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
        title: Text('Transfert d\'argent'),
        centerTitle: true, // Centre le titre de l'AppBar
      ),
      body: Center( // Centre tout le contenu
        child: Container(
          constraints: BoxConstraints(maxWidth: 600), // Limite la largeur maximale
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24), // Augmenté le padding
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Numéro de téléphone
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

                  if (_receiverName != null) ...[
                    SizedBox(height: 12), // Légèrement augmenté
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: EdgeInsets.all(12), // Légèrement augmenté
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
                  ],

                  SizedBox(height: 24), // Augmenté

                  // Montant
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

                  SizedBox(height: 24), // Augmenté

                  // Frais de transfert
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Ajouté vertical padding
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Frais de transfert',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _fraisTransfertActif ? 'Avec frais' : 'Sans frais',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _fraisTransfertActif,
                              onChanged: (bool value) {
                                setState(() {
                                  _fraisTransfertActif = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32), // Augmenté

                  // Bouton de transfert
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleTransfer,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56), // Augmenté la hauteur
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Effectuer le transfert',
                      style: TextStyle(fontSize: 18), // Augmenté la taille
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}