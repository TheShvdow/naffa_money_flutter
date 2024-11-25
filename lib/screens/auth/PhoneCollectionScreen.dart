import 'package:flutter/material.dart' show AppBar, BorderRadius, BuildContext, CircularProgressIndicator, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, Form, FormState, GlobalKey, Icon, Icons, InputDecoration, Key, MainAxisAlignment, MaterialPageRoute, Navigator, OutlineInputBorder, Padding, RoundedRectangleBorder, Row, Scaffold, ScaffoldMessenger, Size, SizedBox, SnackBar, State, StatefulWidget, Text, TextAlign, TextEditingController, TextFormField, TextInputType, Theme, Widget;
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class PhoneCollectionScreen extends StatefulWidget {
  final String userId;

  const PhoneCollectionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _PhoneCollectionScreenState createState() => _PhoneCollectionScreenState();
}

class _PhoneCollectionScreenState extends State<PhoneCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _submitPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateUserPhoneNumber(
        widget.userId,
        _phoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Numéro de téléphone enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
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
        title: Text('Compléter votre profil'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pour finaliser votre inscription,\nveuillez ajouter votre numéro de téléphone',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '+221 XX XXX XX XX',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  String phone = value.replaceAll(' ', '');
                  if (!phone.startsWith('+221') &&
                      !phone.startsWith('221') &&
                      !phone.startsWith('7')) {
                    return 'Format de numéro invalide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPhoneNumber,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('En cours...'),
                  ],
                )
                    : Text('Continuer'),
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
    super.dispose();
  }
}