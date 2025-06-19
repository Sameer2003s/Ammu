import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffHealthAlertsPage extends StatefulWidget {
  // Callback to notify the previous page to show the notification dot.
  final VoidCallback onAlertSubmitted;

  const StaffHealthAlertsPage({super.key, required this.onAlertSubmitted});

  @override
  State<StaffHealthAlertsPage> createState() => _StaffHealthAlertsPageState();
}

class _StaffHealthAlertsPageState extends State<StaffHealthAlertsPage> {
  final _formKey = GlobalKey<FormState>();
  final _staffNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _staffNameController.dispose();
    _departmentController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  /// Submits the staff health alert to Firestore.
  Future<void> _submitAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      // We will save staff alerts to a new collection to keep them separate.
      await FirebaseFirestore.instance.collection('staffHealthAlerts').add({
        'submittedBy': user?.uid,
        'submittedAt': Timestamp.now(),
        'staffName': _staffNameController.text.trim(),
        'department': _departmentController.text.trim(),
        'details': _detailsController.text.trim(),
        'type': 'staff', // To identify the alert type
      });

      if(mounted) {
         // Trigger the notification dot on the previous screen.
         widget.onAlertSubmitted();
         
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
           content: Text('Staff health alert submitted successfully!'),
           backgroundColor: Colors.green,
         ));
         
         // Go back to the previous screen.
         Navigator.pop(context);
      }

    } catch(e) {
       if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Failed to submit alert: $e'),
           backgroundColor: Colors.red,
         ));
       }
    } finally {
        if(mounted) {
           // No need to set state as the widget is being disposed
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Health Alerts', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the Staff Health & Medication Details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _staffNameController,
                decoration: const InputDecoration(labelText: 'Staff Name', border: OutlineInputBorder()),
                validator: (value) => (value?.isEmpty ?? true) ? 'Please enter staff name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                validator: (value) => (value?.isEmpty ?? true) ? 'Please enter department' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Health and Medication details',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.isEmpty ?? true) ? 'Please enter details' : null,
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
                      : const Text('Submit Alert'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
