import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naffa_money/services/transaction_service.dart';
import 'package:naffa_money/services/auth_service.dart';

class MultipleTransferScreen extends StatefulWidget {
  @override
  _MultipleTransferScreenState createState() => _MultipleTransferScreenState();
}

class _MultipleTransferScreenState extends State<MultipleTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _multiplePhoneControllers = [];
  final List<TextEditingController> _multipleAmountControllers = [];
  final TransferService _transferService = TransferService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ajoutez un premier contrôleur par défaut
    _multiplePhoneControllers.add(TextEditingController());
    _multipleAmountControllers.add(TextEditingController());
  }

  Future<void> _handleMultipleTransfers() async {
    if (!_formKey.currentState!.validate()) return;

    final receivers = _getReceiverList();
    final amounts = _getAmountList();

    if (receivers.length != amounts.length ) {
      // Les listes n'ont pas la même longueur, afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Les informations des bénéficiaires sont incomplètes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }


      final String transactionId = FirebaseFirestore.instance.collection('transactions').doc().id;

      await _transferService.transferMultiple(
        transactionId: transactionId,
        senderUid: currentUser.id,
        receivers: receivers,
        amounts: amounts,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transferts multiples effectués avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors des transferts multiples : $e'),
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

  List<String> _getReceiverList() {
    final receivers = <String>[];
    for (final controller in _multiplePhoneControllers) {
      receivers.add(controller.text.trim());
    }
    return receivers;
  }

  List<double> _getAmountList() {
    final amounts = <double>[];
    for (final controller in _multipleAmountControllers) {
      final amount = double.tryParse(controller.text.trim());
      if (amount != null) {
        amounts.add(amount);
      }
    }
    return amounts;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfert multiple'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...List.generate(
                _multiplePhoneControllers.length,
                    (index) => Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _multiplePhoneControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Numéro du destinataire ${index + 1}',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintText: '+221 XX XXX XX XX',
                          ),
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un numéro';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 25),
                      Expanded(
                        child: TextFormField(
                          controller: _multipleAmountControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Montant',
                            suffixText: 'FCFA',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
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
                      ),
                      SizedBox(width: 25),
                      GestureDetector(
                        onTap: () {
                          _removeRecipient(index);
                        },
                        child: Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _addRecipient();
                },
                icon: Icon(Icons.add),
                label: Text('Ajouter un bénéficiaire'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleMultipleTransfers,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    SizedBox(width: 8),
                    Text('En cours...', style: TextStyle(fontSize: 18)),
                  ],
                )
                    : Text(
                  'Effectuer les transferts multiples',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addRecipient() {
    _multiplePhoneControllers.add(TextEditingController());
    _multipleAmountControllers.add(TextEditingController());
    setState(() {});
  }

  void _removeRecipient(int index) {
    _multiplePhoneControllers.removeAt(index);
    _multipleAmountControllers.removeAt(index);
    setState(() {});
  }
}