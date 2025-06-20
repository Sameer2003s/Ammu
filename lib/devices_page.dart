import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth.dart'; // Your existing bluetooth page

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  /// Handles the tap on the Bluetooth option, requesting permissions first.
  Future<void> _handleBluetoothTap(BuildContext context) async {
    // Request necessary Bluetooth permissions.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // Check if the permissions were granted by the user.
    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      // If permissions are granted, navigate to the Bluetooth pairing page.
      if (ScaffoldMessenger.of(context).mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BluetoothPage()),
        );
      }
    } else {
      // If permissions are denied, inform the user with a SnackBar.
      if (ScaffoldMessenger.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required to pair devices.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Placeholder function for future Wi-Fi device integration.
  void _handleWifiTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WiFi device management is coming soon!')),
    );
  }

  /// Placeholder function for other types of device connections.
  void _handleOtherDevicesTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Functionality for other devices is coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Devices',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildDeviceOptionTile(
            context: context,
            icon: Icons.bluetooth,
            title: 'Bluetooth',
            subtitle: 'Pair smart watches and chips',
            onTap: () => _handleBluetoothTap(context),
          ),
          _buildDeviceOptionTile(
            context: context,
            icon: Icons.wifi,
            title: 'Wi-Fi',
            subtitle: 'Connect to Wi-Fi enabled devices',
            onTap: () => _handleWifiTap(context),
          ),
          _buildDeviceOptionTile(
            context: context,
            icon: Icons.devices_other,
            title: 'Other Devices',
            subtitle: 'Manage other connections',
            onTap: () => _handleOtherDevicesTap(context),
          ),
        ],
      ),
    );
  }

  /// A helper widget to create consistently styled list tiles for each option.
  Widget _buildDeviceOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
