import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/distributor_model.dart';
import '../../models/user_model.dart';
import 'dart:convert';

class DistributorDepositScreen extends StatefulWidget {
  @override
  _DistributorDepositScreenState createState() => _DistributorDepositScreenState();
}

class _DistributorDepositScreenState extends State<DistributorDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isDeposit = true; // Initialisez-le à true pour un dépôt par défaut
  UserModel? _client;

  Future<void> _verifyClient(String phone) async {
    if (phone.length < 9) return;

    try {
      final clientSnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (clientSnapshot.docs.isNotEmpty) {
        final clientData = clientSnapshot.docs.first.data();
        final client = UserModel.fromJson(clientData);
        if (mounted) {
          setState(() {
            _client = client;
          });
        }
      }
    } catch (e) {
      print('Erreur de vérification: $e');
    }
  }

  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Récupérer les informations du distributeur connecté
      final distributorSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      final distributorData = distributorSnapshot.data()!;
      final distributor = DistributorModel.fromJson(distributorData);

      // Récupérer les informations du client
      final clientPhone = _phoneController.text.trim();
      final clientSnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: clientPhone)
          .limit(1)
          .get();
      if (clientSnapshot.docs.isEmpty) {
        throw Exception('Aucun client trouvé avec ce numéro de téléphone');
      }
      final clientData = clientSnapshot.docs.first.data();
      final client = UserModel.fromJson(clientData);

      // Vérifier que le distributeur a un solde suffisant
      final depositAmount = double.parse(_amountController.text.replaceAll(' ', ''));
      if (distributor.balance < depositAmount) {
        throw Exception('Solde insuffisant pour effectuer le dépôt');
      }

      // Générer un ID de transaction unique
      final String transactionId = _firestore.collection('transactions').doc().id;

      // Début de la transaction Firestore
      await _firestore.runTransaction((transaction) async {
        // Mettre à jour le solde du distributeur
        transaction.update(
            _firestore.collection('users').doc(_auth.currentUser!.uid),
            {'balance': distributor.balance - depositAmount}
        );

        // Mettre à jour le solde du client
        transaction.update(
            _firestore.collection('users').doc(client.id),
            {'balance': client.balance + depositAmount}
        );

        // Créer la transaction unique
        final transactionData = {
          'id': transactionId,
          'type': 'deposit',
          'amount': depositAmount,
          'distributorId': distributor.id,
          'distributorName': distributor.name,
          'clientId': client.id,
          'userName': client.name,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
          'forDistributor': true,
          'description': 'Dépôt effectué par ${distributor.name}'
        };

        // Utiliser l'ID généré pour créer le document
        transaction.set(
            _firestore.collection('transactions').doc(transactionId),
            transactionData
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dépôt effectué avec succès (ID: $transactionId)'),
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
        title: Text('Effectuer un dépôt'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Numéro de téléphone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro du client',
                  prefixIcon: Icon(Icons.phone),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(title: Text('Scanner le QR code')),
                            body: MobileScanner(
                              onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                for (final barcode in barcodes) {
                                  try {
                                    final data = jsonDecode(barcode.rawValue ?? '');
                                    if (data['phone'] != null) {
                                      Navigator.pop(context, data['phone']);
                                    }
                                  } catch (e) {
                                    print('Erreur de décodage QR: $e');
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _phoneController.text = result;
                        });
                        _verifyClient(result);
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '+221 XX XXX XX XX',
                ),
                keyboardType: TextInputType.phone,
                onChanged: _verifyClient,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  return null;
                },
              ),

              if (_client != null) ...[
                SizedBox(height: 8),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Client: ${_client!.name}',
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

              SizedBox(height: 16),

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

              SizedBox(height: 24),

              // Bouton de dépôt
              ElevatedButton(
                onPressed: _isLoading ? null : _handleDeposit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Effectuer le dépôt',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}