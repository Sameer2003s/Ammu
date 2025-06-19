import 'package:flutter/material.dart';

class SmsScreen extends StatelessWidget {
  const SmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Analytics'),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'SMS Analytics & Reports Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
