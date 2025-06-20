import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Import Existing and New Pages ---
import 'sms.dart'; 
import 'manage_students_page.dart';
import 'user_management_page.dart'; // New
import 'system_analytics_page.dart'; // New
import 'broadcast_message_page.dart'; // New
import 'admin_settings_page.dart'; // New
import 'login.dart'; // For logout navigation

// --- Data Models for the Dashboard (Unchanged) ---

class StudentLocation {
  final String name;
  final LatLng position;
  final BitmapDescriptor marker;

  StudentLocation(
      {required this.name, required this.position, required this.marker});
}

class IncidentRecord {
  final String studentName;
  final DateTime date;
  final String details;
  final String photoPath;

  IncidentRecord(
      {required this.studentName,
      required this.date,
      required this.details,
      required this.photoPath});
}

// --- Main Admin Dashboard Page ---

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  int _bottomNavIndex = 0;
  bool _isMonthly = true;

  // --- Mock Data (Unchanged) ---
  final List<StudentLocation> _studentLocations = [
    StudentLocation(
        name: 'Sara',
        position: const LatLng(11.6693, 78.1404),
        marker: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
    StudentLocation(
        name: 'Jyoti',
        position: const LatLng(11.6665, 78.1350),
        marker:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
    StudentLocation(
        name: 'Rose',
        position: const LatLng(11.6643, 78.1460),
        marker:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
  ];

  final List<IncidentRecord> _incidentRecords = [
    IncidentRecord(
        studentName: 'Khatija Begum',
        date: DateTime(2025, 1, 7, 21, 0),
        details: 'SOS alert triggered near the main park entrance. Dispatched security. Situation resolved, false alarm.',
        photoPath: 'assets/incident1.png'),
    IncidentRecord(
        studentName: 'Rose Saran',
        date: DateTime(2025, 2, 17, 20, 0),
        details: 'Student reported feeling unwell at the library. Parent has been notified and is on their way to pick them up.',
        photoPath: 'assets/incident2.png'),
  ];
  
  void _onItemTapped(int index) {
    setState(() => _bottomNavIndex = index);
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SmsScreen()));
    }
  }

  /// MODIFICATION: Handles logging out the user.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Pushes the login page and removes all routes behind it.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // --- UI Builder Methods ---
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250,
              margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(11.6643, 78.1460),
                    zoom: 14.5,
                  ),
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  markers: _studentLocations
                      .map((loc) => Marker(
                            markerId: MarkerId(loc.name),
                            position: loc.position,
                            infoWindow: InfoWindow(title: loc.name),
                            icon: loc.marker,
                          ))
                      .toSet(),
                ),
              ),
            ),
            Padding(
               padding: const EdgeInsets.all(16.0),
              child: _buildRevenueCard(),
            ),
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildIncidentList(),
            ),
          ],
        ),
      ),
       bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'SMS'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _bottomNavIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  AppBar _buildAppBar() {
     return AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/admin_profile_pic.png'),
            ),
          )
        ],
      );
  }

  /// MODIFICATION: Updated Drawer with navigation logic.
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Admin User', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('admin@ammu.app'),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/admin_profile_pic.png'),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('User Management'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: const Text('Manage Students'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('System Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemAnalyticsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: const Text('Broadcast Message'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BroadcastMessagePage()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout, // Call the logout method
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Membership Revenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      _buildTimeframeButton('Yearly', !_isMonthly),
                      _buildTimeframeButton('Monthly', _isMonthly),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            _buildRevenueRow('Total Earning', _isMonthly ? '₹90,987' : '₹10,50,432'),
            const Divider(height: 24),
            _buildRevenueRow('Total Spent', _isMonthly ? '₹40,706' : '₹5,12,890'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isMonthly = text == 'Monthly'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildRevenueRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
      ],
    );
  }

  Widget _buildIncidentList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Incident Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [Text('View all'), SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 14)],
                ),
              )
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0),
          itemCount: _incidentRecords.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 16),
          itemBuilder: (context, index) {
            final record = _incidentRecords[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(record.photoPath, width: 50, height: 50, fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported)),
              ),
              title: Text(record.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(DateFormat('dd MMM').format(record.date)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(DateFormat('h:mm a').format(record.date), style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 28,
                    child: OutlinedButton(
                      onPressed: () => _showIncidentDetails(record),
                       style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      child: const Text('View'),
                    ),
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }
  
  void _showIncidentDetails(IncidentRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Incident: ${record.studentName}'),
        content: Text(record.details),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      )
    );
  }
}
