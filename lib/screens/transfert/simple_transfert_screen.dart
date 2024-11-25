import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naffa_money/services/transaction_service.dart';
import 'package:naffa_money/services/auth_service.dart';
import '../../models/user_model.dart';

class SimpleTransferScreen extends StatefulWidget {
  @override
  _SimpleTransferScreenState createState() => _SimpleTransferScreenState();
}

class _SimpleTransferScreenState extends State<SimpleTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
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

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final String transactionId = FirebaseFirestore.instance.collection('transactions').doc().id;

      await _transferService.transferMoney(
        transactionId: transactionId,
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
                  final favoriteDoc = await _firestore
                      .collection('favorites')
                      .doc(favoriteId)
                      .get();

                  if (!favoriteDoc.exists) {
                    throw Exception('Contact favori non trouvé');
                  }

                  final favoriteData = favoriteDoc.data() as Map<String, dynamic>;
                  if (favoriteData['userId'] != currentUser.id) {
                    throw Exception('Vous n\'êtes pas autorisé à supprimer ce favori');
                  }

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
                      content: Text('Erreur lors de la suppression: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfert simple'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
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
                              IconButton(
                                icon: Icon(Icons.favorite_border),
                                onPressed: _showAddFavoriteDialog,
                                color: Colors.blue,
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

              // Section Favoris
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
                      SizedBox(height: 32),
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

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}