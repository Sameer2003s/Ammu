import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:file_picker/file_picker.dart'; // Import the file picker package

// --- Data Models (Unchanged) ---
enum AssignmentStatus { upcoming, submitted, overdue }

class Assignment {
  final String title;
  final String subject;
  final DateTime dueDate;
  final AssignmentStatus status;
  final String? grade;

  Assignment({
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    this.grade,
  });
}

class Student {
  final String id;
  final String name;
  Student({required this.id, required this.name});
}

// --- Main Assignments Page ---
class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Student> _students = [];
  Student? _selectedStudent;
  List<Assignment> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchStudentsAndGenerateAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- MODIFICATION: New function to handle file picking ---
  Future<void> _pickAndUploadFile(Assignment assignment) async {
    // 1. Pick a file using the file_picker package
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      // Get the file name and path
      String fileName = result.files.single.name;
      
      // 2. Show immediate feedback to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading "$fileName"...')),
        );
      }

      // 3. SIMULATE UPLOAD (In a real app, this is where you would upload to Firebase Storage)
      // Example Real Code:
      //
      // File file = File(result.files.single.path!);
      // try {
      //   final storageRef = FirebaseStorage.instance.ref();
      //   final assignmentRef = storageRef.child('assignments/${_selectedStudent!.id}/${assignment.title}/$fileName');
      //   await assignmentRef.putFile(file);
      //   final downloadURL = await assignmentRef.getDownloadURL();
      //   // Now update Firestore with the downloadURL and change status to 'Submitted'
      // } catch (e) {
      //   // Handle upload error
      // }
      await Future.delayed(const Duration(seconds: 3)); // Simulating network upload time

      // 4. Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully submitted "$fileName"!'),
            backgroundColor: Colors.green,
          ),
        );
        // Optional: Refresh the assignment list to move this item to the 'Submitted' tab
      }
    } else {
      // User canceled the picker
      if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File selection cancelled.')),
          );
      }
    }
  }

  Future<void> _fetchStudentsAndGenerateAssignments() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final studentDocs = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).collection('students').get();
      if (mounted) {
        final studentList = studentDocs.docs.map((doc) => Student(id: doc.id, name: doc['studentName'])).toList();
        setState(() {
          _students = studentList;
          if (_students.isNotEmpty) {
            _selectedStudent = _students.first;
            _assignments = _generateMockAssignmentsForStudent(_selectedStudent!);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
       if(mounted){
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load students: $e')),
            );
       }
    }
  }

  List<Assignment> _generateMockAssignmentsForStudent(Student student) {
    final now = DateTime.now();
    return [
      Assignment(title: 'Algebra Worksheet', subject: 'Maths', dueDate: now.add(const Duration(days: 3)), status: AssignmentStatus.upcoming),
      Assignment(title: 'Photosynthesis Essay', subject: 'Science', dueDate: now.add(const Duration(days: 7)), status: AssignmentStatus.upcoming),
      Assignment(title: 'World War II Report', subject: 'History', dueDate: now.subtract(const Duration(days: 2)), status: AssignmentStatus.submitted, grade: 'B+'),
      Assignment(title: 'Poetry Analysis', subject: 'English', dueDate: now.subtract(const Duration(days: 5)), status: AssignmentStatus.submitted, grade: 'A-'),
      Assignment(title: 'Still Life Drawing', subject: 'Art', dueDate: now.subtract(const Duration(days: 4)), status: AssignmentStatus.overdue),
    ];
  }

  void _onStudentChanged(Student? student) {
    if (student != null) {
      setState(() {
        _selectedStudent = student;
        _assignments = _generateMockAssignmentsForStudent(student);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Assignments', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0B3D91),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'UPCOMING'),
              Tab(text: 'SUBMITTED'),
              Tab(text: 'OVERDUE'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
                ? const Center(child: Text('No students found.'))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<Student>(
                          value: _selectedStudent,
                          decoration: const InputDecoration(
                            labelText: 'Select Student',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _students.map((student) => DropdownMenuItem(value: student, child: Text(student.name))).toList(),
                          onChanged: _onStudentChanged,
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAssignmentList(AssignmentStatus.upcoming),
                            _buildAssignmentList(AssignmentStatus.submitted),
                            _buildAssignmentList(AssignmentStatus.overdue),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildAssignmentList(AssignmentStatus status) {
    final filteredAssignments = _assignments.where((a) => a.status == status).toList();
    if (filteredAssignments.isEmpty) {
      return Center(child: Text('No ${status.name} assignments.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredAssignments.length,
      itemBuilder: (context, index) {
        return _buildAssignmentCard(filteredAssignments[index]);
      },
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final color = assignment.status == AssignmentStatus.overdue ? Colors.red.shade700 : const Color(0xFF0B3D91);
    final formattedDate = DateFormat('MMM dd, yyyy').format(assignment.dueDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.subject,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              assignment.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text('Due: $formattedDate', style: TextStyle(color: Colors.grey[800])),
                const Spacer(),
                if (assignment.status == AssignmentStatus.submitted)
                  Chip(
                    label: Text('Grade: ${assignment.grade ?? "N/A"}'),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
            if (assignment.status != AssignmentStatus.submitted) ...[
              const Divider(height: 24),
              ElevatedButton.icon(
                // MODIFICATION: Call the file picker function
                onPressed: () => _pickAndUploadFile(assignment),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
