import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naffa_money/services/transaction_service.dart';
import 'package:naffa_money/services/auth_service.dart';
import 'package:uuid/uuid.dart';

import '../../models/scheduled_transfert.dart';

class ScheduledTransferScreen extends StatefulWidget {
  final ScheduledTransfer? transfer;

  const ScheduledTransferScreen({Key? key, this.transfer}) : super(key: key);

  @override
  _ScheduledTransferScreenState createState() => _ScheduledTransferScreenState();
}

class _ScheduledTransferScreenState extends State<ScheduledTransferScreen> {

  @override
  void initState() {
    super.initState();
    if (widget.transfer != null) {
      _phoneController.text = widget.transfer!.recipientPhone;
      _amountController.text = widget.transfer!.amount.toString();
      _selectedDateTime = widget.transfer!.scheduledTime;
      _scheduleController.text = _formatDate(_selectedDateTime!);
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _scheduleController = TextEditingController();
  final TransactionService _transferService = TransactionService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  DateTime? _selectedDateTime;

  // Fonction pour sélectionner une date et une heure
  Future<void> _selectDateTime() async {
    // Sélectionner la date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    // Si une date est sélectionnée
    if (pickedDate != null) {
      // Sélectionner l'heure
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(pickedDate),
      );

      // Si une heure est sélectionnée
      if (pickedTime != null) {
        // Combiner la date et l'heure sélectionnées
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDateTime = selectedDateTime;
          // Afficher la date et l'heure dans le champ de texte
          _scheduleController.text = "${selectedDateTime.toLocal()}".split(' ')[0] + ' ' + "${selectedDateTime.hour}:${selectedDateTime.minute}";
        });
      }
    }
  }
  Future<void> _handleScheduledTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final scheduleDate = _selectedDateTime;
      if (scheduleDate == null) {
        throw Exception('Date et heure de programmation invalides');
      }

      final String transactionId = widget.transfer?.id ?? const Uuid().v4();
      final scheduledTransfer = ScheduledTransfer(
        id: transactionId,
        transactionId: transactionId,
        senderUid: currentUser.id,
        recipientPhone: _phoneController.text.trim(),
        amount: double.parse(_amountController.text.replaceAll(' ', '')),
        frequency: 'monthly',
        scheduledTime: scheduleDate,
      );

      if (widget.transfer != null) {
        await _transferService.updateScheduledTransfer(scheduledTransfer);
      } else {
        await _transferService.scheduleTransfer(scheduledTransfer);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transfer != null
                ? 'Transfert programmé modifié'
                : 'Transfert programmé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
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
  String _formatDate(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/"
        "${dateTime.month.toString().padLeft(2, '0')}/"
        "${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfert programmé'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro';
                  }
                  return null;
                },
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
              SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                decoration: InputDecoration(
                  labelText: 'Date et Heure de programmation',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                readOnly: true, // Le champ devient en lecture seule
                onTap: _selectDateTime, // Ouvre le sélecteur de date et d'heure
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une date et une heure';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleScheduledTransfer,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Programmer le transfert',
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
