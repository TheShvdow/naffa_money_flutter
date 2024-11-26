  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:naffa_money/services/transaction_service.dart';
  import 'package:naffa_money/services/auth_service.dart';
  import '../../models/user_model.dart';


  class MultipleTransferScreen extends StatefulWidget {
    @override
    _MultipleTransferScreenState createState() => _MultipleTransferScreenState();
  }

  class _MultipleTransferScreenState extends State<MultipleTransferScreen> {
    final _formKey = GlobalKey<FormState>();
    final List<TextEditingController> _multiplePhoneControllers = [];
    final List<TextEditingController> _multipleAmountControllers = [];
    final _phoneController = TextEditingController();
    final TransactionService _transferService = TransactionService();
    final AuthService _authService = AuthService();

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    bool _isLoading = false;

    String? _receiverName;

    Future<void> _verifyReceiver(String phone) async {
      final receiverInfo = await _transferService.getReceiverInfo(phone);
      if (receiverInfo != null) {
        setState(() {
          _receiverName = receiverInfo.name;
        });
      }
    }

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
        await _transferService.processTransactions();

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


    Future<void> _showAddFavoriteDialog() async {
      if (_phoneController.text.isEmpty || _receiverName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez d\'abord sélectionner un contact valide'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ajouter aux favoris'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ajouter $_receiverName aux favoris ?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final currentUser = await _authService.getCurrentUserData();
                  if (currentUser == null) {
                    throw Exception('Utilisateur non connecté');
                  }

                  await _firestore.collection('favorites').add({
                    'userId': currentUser.id,
                    'name': _receiverName,
                    'phone': _phoneController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Contact ajouté aux favoris'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'ajout aux favoris'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      );
    }
    Future<void> _showDeleteFavoriteDialog(String favoriteId) async {
      try {
        final currentUser = await _authService.getCurrentUserData();
        if (currentUser == null) {
          throw Exception('Utilisateur non connecté');
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Supprimer des favoris'),
            content: Text('Voulez-vous supprimer ce contact des favoris ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _firestore
                        .collection('favorites')
                        .doc(favoriteId)
                        .delete();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contact supprimé des favoris'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la suppression'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text('Supprimer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section du formulaire
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...List.generate(
                        _multiplePhoneControllers.length,
                            (index) => Container(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: Offset(0, 2),
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
                                      borderRadius: BorderRadius.circular(12),
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
                              SizedBox(width: 15),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _multipleAmountControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Montant',
                                    suffixText: 'FCFA',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: TextStyle(
                                    fontSize: 14,
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
                              SizedBox(width: 15),
                              GestureDetector(
                                onTap: () => _removeRecipient(index),
                                child: Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addRecipient,
                        icon: Icon(Icons.add),
                        label: Text('Ajouter un bénéficiaire'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleMultipleTransfers,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
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

                // Section des favoris
                SizedBox(height: 32),
                FutureBuilder<UserModel?>(
                  future: _authService.getCurrentUserData(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!userSnapshot.hasData || userSnapshot.data == null) {
                      return Center(child: Text('Erreur de chargement utilisateur'));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Numéros favoris',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('favorites')
                              .where('userId', isEqualTo: userSnapshot.data!.id)
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(child: Text('Erreur de chargement'));
                            }

                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final favorites = snapshot.data!.docs;

                            if (favorites.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star_border, color: Colors.grey, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      'Aucun numéro favori',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: favorites.length,
                                itemBuilder: (context, index) {
                                  final favorite = favorites[index].data() as Map<String, dynamic>;
                                  return Container(
                                    width: 100,
                                    margin: EdgeInsets.only(right: 12),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _phoneController.text = favorite['phone'];
                                          _receiverName = favorite['name'];
                                        });
                                      },
                                      onLongPress: () => _showDeleteFavoriteDialog(favorites[index].id),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.blue.shade100,
                                            radius: 30,
                                            child: Text(
                                              favorite['name'][0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            favorite['name'],
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
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