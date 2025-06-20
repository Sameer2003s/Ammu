import 'package:flutter/material.dart';

/// A placeholder screen for administrators to send broadcast messages.
class BroadcastMessagePage extends StatelessWidget {
  const BroadcastMessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Message', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Broadcast Message Screen\n(Coming Soon)\n\nFrom here, you will be able to send notifications or messages to all users or specific groups.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
