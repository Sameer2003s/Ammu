import 'package:flutter/material.dart';

/// A placeholder screen for administrators to view system analytics.
class SystemAnalyticsPage extends StatelessWidget {
  const SystemAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'System Analytics Screen\n(Coming Soon)\n\nThis page will contain charts and data about app usage, revenue, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
