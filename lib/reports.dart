import 'package:flutter/material.dart';

class ReportsApp extends StatelessWidget {
  const ReportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(child: Text('Reports Screen')),
    );
  }
}