import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home.dart'; // The main app page after permissions are handled

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  @override
  void initState() {
    super.initState();
    // Use a short delay before requesting, allowing the screen to build first.
    Future.delayed(const Duration(milliseconds: 500), _requestPermissions);
  }

  /// Requests all necessary permissions for the app to function correctly.
  Future<void> _requestPermissions() async {
    // A map of permissions the app needs.
    // This will request all permissions at once.
    await [
      Permission.location,
      Permission.contacts,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // After the user has responded to the permission dialogs,
    // navigate them to the main part of the app.
    // The app's features should individually handle cases where a
    // specific permission might have been denied.
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D91),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Setting up your app...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'To provide features like GPS tracking and SOS alerts, we need to request a few permissions. Please grant them when prompted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
