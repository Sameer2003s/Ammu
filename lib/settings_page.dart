import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'contacts_page.dart';
import 'subscription.dart';

// A key for saving the theme preference.
const String kThemePreferenceKey = 'theme_preference';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State variables for the notification toggles
  bool _sosAlertsEnabled = true;
  bool _locationUpdatesEnabled = true;
  bool _academicAlertsEnabled = false;
  bool _isDarkMode = false;

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  /// Loads the saved theme preference from shared preferences.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = (prefs.getBool(kThemePreferenceKey) ?? false);
    });
    // NOTE: In a full implementation, you would use a state management solution
    // (like Provider or Riverpod) to notify the entire app of the theme change.
  }

  /// Saves the new theme preference.
  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kThemePreferenceKey, value);
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
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // --- Account Section ---
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: _currentUser?.displayName ?? 'Your Profile',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to an "Edit Profile" page.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Edit Profile page.')),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: _currentUser?.email ?? 'No email provided',
          ),

          // --- App Settings Section ---
          _buildSectionHeader('App Settings'),
          _buildSettingsTile(
            icon: Icons.contacts_outlined,
            title: 'Emergency Contacts',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactsPage()),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'SOS Alerts',
            trailing: Switch(
              value: _sosAlertsEnabled,
              onChanged: (value) => setState(() => _sosAlertsEnabled = value),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Location Updates',
            trailing: Switch(
              value: _locationUpdatesEnabled,
              onChanged: (value) =>
                  setState(() => _locationUpdatesEnabled = value),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.school_outlined,
            title: 'Academic Alerts',
            trailing: Switch(
              value: _academicAlertsEnabled,
              onChanged: (value) =>
                  setState(() => _academicAlertsEnabled = value),
            ),
          ),
           _buildSettingsTile(
            icon: Icons.brightness_6_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() => _isDarkMode = value);
                _saveThemePreference(value);
                 // This would trigger a rebuild of the whole app with the new theme.
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Theme changed. App restart might be needed to see full effect.')),
                  );
              },
            ),
          ),


          // --- Subscription Section ---
           _buildSectionHeader('Subscription'),
           _buildSettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Manage Subscription',
             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
