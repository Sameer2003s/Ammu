import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'parents_health_alerts.dart';
import 'staff_health_alerts.dart'; // MODIFICATION: Import the new staff alerts page

// --- Data Models ---
class Student {
  final String id;
  final String name;
  final String studentClass;
  final String rollNo;

  Student({
    required this.id,
    required this.name,
    required this.studentClass,
    required this.rollNo,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['studentName'] ?? 'N/A',
      studentClass: data['class'] ?? 'N/A',
      rollNo: (doc.id.hashCode % 1000).abs().toString(),
    );
  }
}

class HealthAlert {
  final String title;
  final String details;
  final Timestamp submittedAt;
  final String type; // 'parent' or 'staff'

  HealthAlert({
    required this.title,
    required this.details,
    required this.submittedAt,
    required this.type,
  });

  factory HealthAlert.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthAlert(
      title: data['type'] == 'staff' 
          ? 'Alert for Staff: ${data['staffName']}' 
          : 'Alert for Student: ${data['studentName']}',
      details: data['type'] == 'staff' 
          ? 'Details: ${data['details']}'
          : 'Medication: ${data['medicationDetails']}',
      submittedAt: data['submittedAt'] ?? Timestamp.now(),
      type: data['type'] ?? 'parent',
    );
  }
}


class HealthFollowUpPage extends StatefulWidget {
  const HealthFollowUpPage({super.key});

  @override
  State<HealthFollowUpPage> createState() => _HealthFollowUpPageState();
}

class _HealthFollowUpPageState extends State<HealthFollowUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostelRoomController = TextEditingController();

  File? _selectedImageFile;
  List<Student> _students = [];
  Student? _selectedStudent;
  bool _isLoadingStudents = true;
  bool _hasNewNotification = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _hostelRoomController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if(mounted) setState(() => _isLoadingStudents = false);
      return;
    }
    try {
      final studentDocs = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('students').get();
      if(mounted) {
        final studentList = studentDocs.docs.map((doc) => Student.fromFirestore(doc)).toList();
        setState(() {
          _students = studentList;
          if (_students.isNotEmpty) {
            _selectedStudent = _students.first;
          }
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoadingStudents = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load students: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedImageFile = File(result.files.single.path!));
    } else {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No image selected.')));
       }
    }
  }

  void _submitDietSheet() {
    if (_formKey.currentState!.validate()) {
       if (_selectedStudent == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student first.'), backgroundColor: Colors.orange));
        return;
      }
      if (_selectedImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image for the diet sheet.'), backgroundColor: Colors.orange));
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diet sheet submitted successfully!'), backgroundColor: Colors.green));
      
      _formKey.currentState!.reset();
      _hostelRoomController.clear();
      setState(() => _selectedImageFile = null);
    }
  }

  void _showNotifications() async {
    setState(() => _hasNewNotification = false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final parentAlertsFuture = FirebaseFirestore.instance
          .collection('healthAlerts')
          .where('submittedBy', isEqualTo: user.uid)
          .get();
          
      final staffAlertsFuture = FirebaseFirestore.instance
          .collection('staffHealthAlerts')
          .where('submittedBy', isEqualTo: user.uid)
          .get();

      final results = await Future.wait([parentAlertsFuture, staffAlertsFuture]);
      
      Navigator.of(context).pop(); // Close loading dialog

      final allAlertDocs = [...results[0].docs, ...results[1].docs];
      
      allAlertDocs.sort((a, b) {
          Timestamp tsA = a.data()['submittedAt'] ?? Timestamp.now();
          Timestamp tsB = b.data()['submittedAt'] ?? Timestamp.now();
          return tsB.compareTo(tsA);
      });
      
      final alerts = allAlertDocs.map((doc) => HealthAlert.fromFirestore(doc)).toList();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Recent Health Alerts'),
            content: SizedBox(
              width: double.maxFinite,
              child: alerts.isEmpty
                  ? const Text('No recent alerts found.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(alert.submittedAt.toDate());
                        return Card(
                          color: alert.type == 'staff' ? Colors.amber[50] : Colors.blue[50],
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              '${alert.details}\nSubmitted: $formattedDate',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch(e) {
      Navigator.of(context).pop();
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch alerts: $e')));
       }
    }
  }


  Widget _buildHealthAlertCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: GridTile(
          footer: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Follow Up', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: _showNotifications,
              ),
              if (_hasNewNotification)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                _buildHealthAlertCard(
                  title: 'Parents Health Alert',
                  imagePath: 'assets/parents.png',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParentsHealthAlertsPage(
                    onAlertSubmitted: () => setState(() => _hasNewNotification = true),
                  ))),
                ),
                _buildHealthAlertCard(
                  title: 'Staff Health Alert',
                  imagePath: 'assets/staff2.png',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StaffHealthAlertsPage(
                    onAlertSubmitted: () => setState(() => _hasNewNotification = true),
                  ))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diet Sheet for Hostellers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (_isLoadingStudents) const Center(child: CircularProgressIndicator())
                      else if (_students.isEmpty) const Center(child: Text("No students to select."))
                      else DropdownButtonFormField<Student>(
                        value: _selectedStudent,
                        decoration: const InputDecoration(labelText: 'Select Student', border: OutlineInputBorder()),
                        items: _students.map((student) => DropdownMenuItem(value: student, child: Text(student.name))).toList(),
                        onChanged: (student) => setState(() => _selectedStudent = student),
                        validator: (value) => value == null ? 'Please select a student' : null,
                      ),
                      const SizedBox(height: 16),
                       if (_selectedStudent != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                               _buildInfoChip(Icons.format_list_numbered, 'Roll No: ${_selectedStudent!.rollNo}'),
                               _buildInfoChip(Icons.school_outlined, 'Class: ${_selectedStudent!.studentClass}'),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hostelRoomController,
                        decoration: const InputDecoration(labelText: 'Hostel Room No', border: OutlineInputBorder()),
                         validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a room number' : null,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickImage,
                        child: DottedBorder(
                          color: Colors.grey.shade400,
                          strokeWidth: 1.5,
                          dashPattern: const [6, 4],
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(8),
                          padding: EdgeInsets.zero,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: _selectedImageFile == null ? Colors.grey[200] : Colors.transparent,
                                borderRadius: BorderRadius.circular(8)),
                            child: _selectedImageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 40, color: Colors.grey[600]),
                                      const SizedBox(height: 8),
                                      const Text('Select Your Image here', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitDietSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B3D91),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0B3D91)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
