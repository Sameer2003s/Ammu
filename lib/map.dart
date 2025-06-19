import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GPSTrackingScreen extends StatefulWidget {
  const GPSTrackingScreen({super.key});

  @override
  State<GPSTrackingScreen> createState() => _GPSTrackingScreenState();
}

class _GPSTrackingScreenState extends State<GPSTrackingScreen> {
  // Controller for the Google Map
  final Completer<GoogleMapController> _controller = Completer();
  // State for the selected user filter
  String _selectedUser = 'Rose';

  // Mock data for user locations
  static const LatLng _roseLocation = LatLng(10.7905, 78.7047); // Tiruchirappalli
  static const LatLng _jyotiLocation = LatLng(10.8010, 78.6940); 

  // Mock data for points of interest
  static const LatLng _policeStationLocation = LatLng(10.7955, 78.7090);
  static const LatLng _hmSchoolLocation = LatLng(10.7850, 78.7000);
  static const LatLng _ngoLocation = LatLng(10.8050, 78.7150);
  static const LatLng _vmSchoolLocation = LatLng(10.7920, 78.6900);


  // Initial camera position centered on the general area
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(10.7925, 78.7042), // Center of Tiruchirappalli
    zoom: 13.5,
  );

  // --- Helper methods for building UI components ---

  // Builds the user avatar circle
  Widget _buildUserAvatar(String name) {
    final bool isSelected = _selectedUser == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUser = name;
        });
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
                color: isSelected ? Colors.blue.shade800 : Colors.grey.shade300,
                border: Border.all(
                  color: isSelected ? Colors.blue.shade900 : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
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

  // Builds a row in the "Recent Activity" list
  Widget _buildActivityItem({
    required String imagePath,
    required String location,
    required String time,
    required String userName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
               errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate markers based on the selected user
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('police'),
        position: _policeStationLocation,
        infoWindow: const InfoWindow(title: 'Police Station'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('hm_school'),
        position: _hmSchoolLocation,
        infoWindow: const InfoWindow(title: 'HM School'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
       Marker(
        markerId: const MarkerId('vm_school'),
        position: _vmSchoolLocation,
        infoWindow: const InfoWindow(title: 'VM School'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('ngo'),
        position: _ngoLocation,
        infoWindow: const InfoWindow(title: 'NGO'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      if (_selectedUser == 'Rose')
        const Marker(
          markerId: MarkerId('rose_location'),
          position: _roseLocation,
          infoWindow: InfoWindow(title: 'Rose'),
        ),
      if (_selectedUser == 'Jyoti')
        const Marker(
          markerId: MarkerId('jyoti_location'),
          position: _jyotiLocation,
          infoWindow: InfoWindow(title: 'Jyoti'),
        ),
    };

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // NOTE: The AppBar is part of the main Scaffold in `home.dart`.
      // This widget is displayed as the body of that Scaffold.
      body: Column(
        children: [
          // --- User Selection Header ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildUserAvatar('Rose'),
                _buildUserAvatar('Jyoti'),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement "Add" functionality
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Google Map ---
          Expanded(
            flex: 6, // Gives more space to the map
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

          // --- Recent Activity Section ---
          Expanded(
            flex: 4, // Gives less space to the activity list
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement "See all" navigation
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildActivityItem(
                          imagePath: 'assets/teacher.png', 
                          location: 'Tuition Center',
                          time: '20 minutes ago',
                          userName: 'Rose',
                        ),
                        _buildActivityItem(
                          imagePath: 'assets/library.png',
                          location: 'Library',
                          time: '3 Hours ago',
                          userName: 'Jyoti',
                        ),
                        _buildActivityItem(
                          imagePath: 'assets/home2.png',
                          location: 'Home',
                          time: '6 Hours ago',
                          userName: 'Jyoti',
                        ),
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
