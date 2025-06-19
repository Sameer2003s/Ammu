import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription.dart'; // MODIFICATION: Import the subscription page

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _studentClassController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentMobileController = TextEditingController();

  int? _selectedAge;
  bool _isLoading = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentClassController.dispose();
    _parentNameController.dispose();
    _parentMobileController.dispose();
    super.dispose();
  }

  /// Saves the student data to Firestore after checking the subscription limit.
  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // This should ideally not happen if the page is protected.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Error: Not logged in.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      // Default to 0 if no plan is set. A real app might enforce a subscription first.
      final studentLimit = userData?['studentLimit'] ?? 0;

      // Get the current number of students.
      final studentCollection = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('students');
      final currentStudentCount = (await studentCollection.count().get()).count ?? 0;

      // --- CHECK THE LIMIT ---
      if (currentStudentCount >= studentLimit) {
        if (mounted) {
          // MODIFICATION: Show a SnackBar with an "UPGRADE" action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange,
              content: Text('Student limit of $studentLimit reached.'),
              action: SnackBarAction(
                label: 'UPGRADE',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() => _isLoading = false);
        return; // Stop the function here
      }

      // If the limit is not reached, add the new student.
      await studentCollection.add({
        'studentName': _studentNameController.text.trim(),
        'age': _selectedAge,
        'class': _studentClassController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'parentMobile': _parentMobileController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _studentNameController.clear();
        _studentClassController.clear();
        _parentNameController.clear();
        _parentMobileController.clear();
        setState(() => _selectedAge = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Failed to add student: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Student Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(labelText: 'Student Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedAge,
                decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                items: List.generate(15, (index) => index + 4)
                    .map((age) => DropdownMenuItem(value: age, child: Text('$age years old')))
                    .toList(),
                onChanged: (value) => setState(() => _selectedAge = value),
                validator: (value) => value == null ? 'Please select an age' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentClassController,
                decoration: const InputDecoration(labelText: 'Class (e.g., 5th, 10th)', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a class' : null,
              ),
              const SizedBox(height: 24),
              const Text('Parent Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(labelText: 'Parent Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a parent\'s name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentMobileController,
                decoration: const InputDecoration(labelText: 'Parent Mobile Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a mobile number';
                  if (value.length < 10) return 'Please enter a valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3D91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Save Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
