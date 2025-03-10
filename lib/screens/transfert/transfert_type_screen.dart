import 'package:flutter/material.dart';

import 'multiple_transfert_screen.dart';
import 'scheduled_transfert_screen.dart';
import 'simple_transfert_screen.dart';

class TransferTypeScreen extends StatelessWidget {
  const TransferTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Transfert'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisissez votre option ',
                style: TextStyle(
                  fontSize: 20,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildTransferTypeCard(
                      'Transfert simple',
                      Icons.send,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SimpleTransferScreen()),
                      ),
                    ),
                    _buildTransferTypeCard(
                      'Transfert multiple',
                      Icons.groups,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MultipleTransferScreen()),
                      ),
                    ),
                    _buildTransferTypeCard(
                      'Transfert programmé',
                      Icons.calendar_today,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ScheduledTransferScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransferTypeCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue.shade800, size: 48),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}