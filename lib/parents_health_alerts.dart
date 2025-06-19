import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Data Model for Student ---
class Student {
  final String id;
  final String name;
  final String parentName;
  final String studentClass;
  final String rollNo; // Mock roll number

  Student({
    required this.id,
    required this.name,
    required this.parentName,
    required this.studentClass,
    required this.rollNo,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['studentName'] ?? 'N/A',
      parentName: data['parentName'] ?? 'N/A',
      studentClass: data['class'] ?? 'N/A',
      rollNo: (doc.id.hashCode % 1000).abs().toString(),
    );
  }
}

// --- Main Page Widget ---
class ParentsHealthAlertsPage extends StatefulWidget {
  // MODIFICATION: Added a callback to notify the previous page.
  final VoidCallback onAlertSubmitted;

  const ParentsHealthAlertsPage({super.key, required this.onAlertSubmitted});

  @override
  State<ParentsHealthAlertsPage> createState() => _ParentsHealthAlertsPageState();
}

class _ParentsHealthAlertsPageState extends State<ParentsHealthAlertsPage> {
  final _formKey = GlobalKey<FormState>();
  final _staffNameController = TextEditingController();
  final _medicationController = TextEditingController();

  List<Student> _students = [];
  Student? _selectedStudent;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _staffNameController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  // --- Data Fetching and Submission ---

  Future<void> _fetchStudents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final studentDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('students')
          .get();

      if (mounted) {
        final studentList = studentDocs.docs.map((doc) => Student.fromFirestore(doc)).toList();
        setState(() {
          _students = studentList;
          if (_students.isNotEmpty) {
            _selectedStudent = _students.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  void _onStudentChanged(Student? student) {
    if (student != null) {
      setState(() {
        _selectedStudent = student;
      });
    }
  }

  Future<void> _submitAlert() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a student.')));
       return;
    }

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('healthAlerts').add({
        'submittedBy': user?.uid,
        'submittedAt': Timestamp.now(),
        'studentId': _selectedStudent!.id,
        'studentName': _selectedStudent!.name,
        'rollNo': _selectedStudent!.rollNo,
        'class': _selectedStudent!.studentClass,
        'parentName': _selectedStudent!.parentName,
        'staffName': _staffNameController.text.trim(),
        'medicationDetails': _medicationController.text.trim(),
      });

      if(mounted) {
         // MODIFICATION: Call the callback to trigger the notification dot
         widget.onAlertSubmitted();

         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health alert submitted successfully!'), backgroundColor: Colors.green));
         
         // Go back to the previous screen
         Navigator.pop(context);
      }

    } catch(e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit alert: $e'), backgroundColor: Colors.red));
       }
    } finally {
        if(mounted) {
            // No need to set state here as the widget is being disposed
        }
    }
  }

  // --- UI Builder ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Health Alerts', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students available.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter the Valid Medication Details:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<Student>(
                          value: _selectedStudent,
                          decoration: const InputDecoration(labelText: 'Student name', border: OutlineInputBorder()),
                          items: _students.map((student) => DropdownMenuItem(value: student, child: Text(student.name))).toList(),
                          onChanged: _onStudentChanged,
                          validator: (value) => value == null ? 'Please select a student' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        if (_selectedStudent != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2))
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(Icons.person, 'Parent Name', _selectedStudent!.parentName),
                                const Divider(height: 16),
                                _buildInfoRow(Icons.class_, 'Class', _selectedStudent!.studentClass),
                                const Divider(height: 16),
                                _buildInfoRow(Icons.format_list_numbered, 'Roll No', _selectedStudent!.rollNo),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _staffNameController,
                          decoration: const InputDecoration(labelText: 'Staff Name', border: OutlineInputBorder()),
                           validator: (value) => (value?.isEmpty ?? true) ? 'Please enter staff name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _medicationController,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Medication details', border: OutlineInputBorder(), alignLabelWithHint: true),
                           validator: (value) => (value?.isEmpty ?? true) ? 'Please enter medication details' : null,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitAlert,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B3D91),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        const SizedBox(width: 12),
        Text('$label:', style: TextStyle(color: Colors.grey[700])),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
