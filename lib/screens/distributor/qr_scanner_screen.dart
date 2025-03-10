import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRCodeScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final double amount;

  QRCodeScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    // Créer les données du QR code
    final qrData = {
      'userId': userId,
      'amount': amount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': 'withdrawal'
    };

    final qrString = Uri(
      scheme: 'wavemoney',
      host: 'withdrawal',
      queryParameters: {
        'data': qrData.toString(),
      },
    ).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Code QR de retrait'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrString,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '${amount.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Montrez ce code à un distributeur\npour effectuer votre retrait',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}