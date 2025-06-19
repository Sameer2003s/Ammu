import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // For saving contacts
import 'package:url_launcher/url_launcher.dart';

// Import other pages
import 'academic.dart';
import 'manage_students_page.dart';
import 'contacts_page.dart';
import 'gps_tracking_screen.dart';
import 'heatwave.dart';
import 'health_follow_ups.dart';
import 'reports.dart';
import 'subscription.dart';
import 'settings_page.dart';
import 'admin_dashboard.dart';
import 'login.dart';

// --- Constants for Styling ---
const Color kPrimaryColor = Color(0xFF0B3D91);
const Color kPrimaryLightColor = Color(0xFF0F2F5A);
const TextStyle kNoteTitleStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: kPrimaryColor,
);
const TextStyle kNoteBodyStyle = TextStyle(fontSize: 14, color: Colors.black54);

// --- Main Home Page Widget ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late final AnimationController _sosRippleController;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _sosRippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duration of one ripple expanding
    )..repeat();

    _pages = <Widget>[
      HomePageContent(state: this),
      const GPSTrackingScreen(),
      const ReportsApp(),
    ];
  }

  @override
  void dispose() {
    _sosRippleController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _triggerSosCalls() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactsJson =
        prefs.getStringList('emergency_contacts') ?? [];

    if (contactsJson.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No emergency contacts found. Please add contacts first.')),
        );
      }
      return;
    }

    final contactMap = jsonDecode(contactsJson.first) as Map<String, dynamic>;
    final String phoneNumber = contactMap['number'] ?? '';

    if (phoneNumber.isNotEmpty) {
      await _makePhoneCall(phoneNumber);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Primary emergency contact has no phone number.')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open phone app.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not launch call. Are you on a real device? Error: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'GPS Tracking';
      case 2:
        return 'Reports';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _selectedIndex == 0 ? _buildDrawer() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(_getTitleForIndex(_selectedIndex), style: const TextStyle(color: Colors.white)),
      backgroundColor: kPrimaryColor,
      actions: _selectedIndex == 0
          ? [
              TextButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen())),
                icon: const Icon(Icons.workspace_premium,
                    color: Colors.amber, size: 20),
                label: const Text('Plus',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ]
          : null,
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryColor),
            accountName: Text(_currentUser?.displayName ?? 'User Name',
                style: const TextStyle(fontSize: 18)),
            accountEmail: Text(_currentUser?.email ?? 'user@example.com',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _currentUser?.photoURL != null
                  ? NetworkImage(_currentUser!.photoURL!)
                  : null,
              child: _currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 40, color: kPrimaryColor)
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Manage Students'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageStudentsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Academic Follow Up'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AcademicFollowUpPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Health Follow Up'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HealthFollowUpPage()),
              );
            },
          ),
          ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const SettingsPage()),
                 );
              }),
          ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () => Navigator.pop(context)),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.grey,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.gps_fixed), label: 'GPS'),
        BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Reports'),
      ],
    );
  }
}

// --- Content for the Home Tab ---
class HomePageContent extends StatelessWidget {
  final _HomePageState state;

  const HomePageContent({super.key, required this.state});

  Widget _buildHelplineIcon(String imagePath, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(imagePath, height: 40, width: 40, fit: BoxFit.contain),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Note', style: kNoteTitleStyle),
            const Text(
              'Tapping the SOS button immediately calls your primary emergency contact.',
              style: kNoteBodyStyle,
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: state._triggerSosCalls,
                child: CustomPaint(
                  painter: SosRipplePainter(state._sosRippleController),
                  child: const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.red,
                        child: Text('SOS',
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('Tap the SOS button for Help',
                  style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const ContactsPage())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryLightColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Manage Emergency Contacts'),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const Text('Nearby Helpline', style: kNoteTitleStyle),
                const Spacer(),
                Text('Tap to call',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                GestureDetector(
                    onTap: () => state._makePhoneCall('100'),
                    child: _buildHelplineIcon('assets/police.png', 'Police')),
                GestureDetector(
                    onTap: state._triggerSosCalls,
                    child: _buildHelplineIcon('assets/family.png', 'Family')),
                GestureDetector(
                    onTap: () => state._makePhoneCall('108'),
                    child: _buildHelplineIcon('assets/108.png', '108')),
                GestureDetector(
                    onTap: () {},
                    child: _buildHelplineIcon('assets/staff.png', 'Staff')),
                GestureDetector(
                    onTap: () {},
                    child: _buildHelplineIcon('assets/NGO.png', 'NGO')),
              ],
            ),
            const SizedBox(height: 25),
            const Text('Indicators', style: kNoteTitleStyle),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Heatwave())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.wb_sunny, color: Colors.orange[800]),
                    const SizedBox(width: 12),
                    const Text('Heatwave',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MODIFICATION: New, smoother ripple painter ---
class SosRipplePainter extends CustomPainter {
  final Animation<double> animation;
  final int rippleCount;
  final Color color;

  SosRipplePainter(this.animation, {this.rippleCount = 4, this.color = Colors.red})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    for (int i = 0; i < rippleCount; i++) {
      final double progress = (animation.value + i / rippleCount) % 1.0;
      final double radius = rect.width / 2 * progress;
      final double opacity = (1.0 - progress).clamp(0.0, 1.0);
      final Paint paint = Paint()..color = color.withOpacity(opacity * 0.4);
      canvas.drawCircle(rect.center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SosRipplePainter oldDelegate) {
    return true;
  }
}
