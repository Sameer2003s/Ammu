import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_student_page.dart'; // Import the add student page
import 'app_theme.dart'; // MODIFICATION: Added missing theme import

// --- Data Model for Student Location ---
class Student {
  final String id;
  final String name;
  final LatLng location; // Mock location for demonstration

  Student({required this.id, required this.name, required this.location});

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Generate a predictable, unique mock location for each student
    final mockLocation = LatLng(
        13.0827 + (doc.id.hashCode % 100) * 0.0001, // Base latitude for Chennai
        80.2707 - (doc.id.hashCode % 100) * 0.0001); // Base longitude for Chennai
        
    return Student(
      id: doc.id,
      name: data['studentName'] ?? 'No Name',
      location: mockLocation,
    );
  }
}

class GPSTrackingScreen extends StatefulWidget {
  const GPSTrackingScreen({super.key});

  @override
  State<GPSTrackingScreen> createState() => _GPSTrackingScreenState();
}

class _GPSTrackingScreenState extends State<GPSTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  StreamSubscription? _studentStream;
  List<Student> _students = [];
  Student? _selectedStudent;
  bool _isLoading = true;

  // Static POIs remain the same
  static const LatLng _policeStationLocation = LatLng(13.0850, 80.2750);
  static const LatLng _hmSchoolLocation = LatLng(13.0800, 80.2650);
  static const LatLng _ngoLocation = LatLng(13.0900, 80.2800);
  static const LatLng _vmSchoolLocation = LatLng(13.0785, 80.2780);

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(13.0827, 80.2707), // Center of Chennai
    zoom: 14.0,
  );
  
  @override
  void initState() {
    super.initState();
    _listenToStudents();
  }

  @override
  void dispose() {
    _studentStream?.cancel();
    super.dispose();
  }

  /// Listens to the student data from Firestore in real-time.
  void _listenToStudents() {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _studentStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final studentList = snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
        setState(() {
          _students = studentList;
          if (_students.isNotEmpty && (_selectedStudent == null || !_students.any((s) => s.id == _selectedStudent!.id))) {
            _selectedStudent = _students.first;
          } else if (_students.isEmpty) {
            _selectedStudent = null;
          }
          _isLoading = false;
        });
      }
    }, onError: (error) {
       if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching students: $error")));
       }
    });
  }

  Widget _buildUserAvatar(Student student) {
    final bool isSelected = _selectedStudent?.id == student.id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStudent = student);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              student.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String imagePath,
    required String location,
    required String time,
    required String userName,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(imagePath, width: 50, height: 50, fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(location, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Text(userName, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {
      const Marker(markerId: MarkerId('police'), position: _policeStationLocation, infoWindow: InfoWindow(title: 'Police Station')),
      const Marker(markerId: MarkerId('hm_school'), position: _hmSchoolLocation, infoWindow: InfoWindow(title: 'HM School')),
      const Marker(markerId: MarkerId('vm_school'), position: _vmSchoolLocation, infoWindow: InfoWindow(title: 'VM School')),
      const Marker(markerId: MarkerId('ngo'), position: _ngoLocation, infoWindow: InfoWindow(title: 'NGO')),
      if (_selectedStudent != null)
        Marker(
          markerId: MarkerId(_selectedStudent!.id),
          position: _selectedStudent!.location,
          infoWindow: InfoWindow(title: _selectedStudent!.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No students are being tracked.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentPage())),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First Student'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _students.map((student) => _buildUserAvatar(student)).toList(),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentPage())).then((_) => _listenToStudents()),
                            icon: const Icon(Icons.add),
                            tooltip: 'Add Student',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: _initialCameraPosition,
                            onMapCreated: (GoogleMapController controller) {
                              if (!_controller.isCompleted) {
                                _controller.complete(controller);
                              }
                            },
                            markers: markers,
                            zoomControlsEnabled: false,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  TextButton(onPressed: () {}, child: const Text('See all')),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildActivityItem(imagePath: 'assets/teacher.png', location: 'Tuition Center', time: '20 minutes ago', userName: _students.isNotEmpty ? _students[0].name : 'Student'),
                                  _buildActivityItem(imagePath: 'assets/library.png', location: 'Library', time: '3 Hours ago', userName: _students.length > 1 ? _students[1].name : 'Student'),
                                  _buildActivityItem(imagePath: 'assets/home2.png', location: 'Home', time: '6 Hours ago', userName: _students.length > 1 ? _students[1].name : 'Student'),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
    );
  }
}
