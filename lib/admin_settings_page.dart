import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Key for saving the theme preference.
const String kAdminThemePreferenceKey = 'admin_theme_preference';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  // State variables for the settings toggles
  bool _isDarkMode = false;
  bool _newUserAlertsEnabled = true;
  bool _subscriptionAlertsEnabled = true;

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  /// Loads the saved theme preference from shared preferences.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = (prefs.getBool(kAdminThemePreferenceKey) ?? false);
      });
    }
  }

  /// Saves the new theme preference.
  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAdminThemePreferenceKey, value);
    if (mounted) {
      // In a real app with state management, this would trigger a theme change across the app.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Theme changed to ${_isDarkMode ? "Dark" : "Light"}. Restart may be needed for full effect.')),
      );
    }
  }

  // --- UI Builder Methods ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // --- Account Section ---
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: _currentUser?.displayName ?? 'Admin User',
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: _currentUser?.email ?? 'No email associated',
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement password change flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Password change feature coming soon.')),
              );
            },
          ),

          // --- Appearance Section ---
          _buildSectionHeader('Appearance'),
          _buildSettingsTile(
            icon: Icons.brightness_6_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                _saveThemePreference(value);
              },
            ),
          ),

          // --- Notifications Section ---
          _buildSectionHeader('Notifications'),
          _buildSettingsTile(
            icon: Icons.notifications_active_outlined,
            title: 'New User Registrations',
            subtitle: 'Get notified when a new user signs up.',
            trailing: Switch(
              value: _newUserAlertsEnabled,
              onChanged: (value) =>
                  setState(() => _newUserAlertsEnabled = value),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.monetization_on_outlined,
            title: 'Subscription Changes',
            subtitle: 'Get notified for new subscriptions or cancellations.',
            trailing: Switch(
              value: _subscriptionAlertsEnabled,
              onChanged: (value) =>
                  setState(() => _subscriptionAlertsEnabled = value),
            ),
          ),

          // --- Data Management Section ---
          _buildSectionHeader('Data & Security'),
          _buildSettingsTile(
            icon: Icons.key_outlined,
            title: 'Manage API Keys',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to an API key management page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API key management coming soon.')),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.download_for_offline_outlined,
            title: 'Export All User Data',
            subtitle: 'Generate a CSV export of the users table.',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement data export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Data export feature coming soon.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
