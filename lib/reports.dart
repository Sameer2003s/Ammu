import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// --- Data Model for a Report Entry ---
enum ReportType { school, library, park, home }

class ReportEntry {
  final String studentName;
  final String title;
  final String location;
  final String date;
  final String time;
  final String imagePath;
  final ReportType type;
  final Map<String, dynamic> details;

  ReportEntry({
    required this.studentName,
    required this.title,
    required this.location,
    required this.date,
    required this.time,
    required this.imagePath,
    required this.type,
    required this.details,
  });
}

// --- Main Reports Page Widget ---
class ReportsApp extends StatefulWidget {
  const ReportsApp({super.key});

  @override
  State<ReportsApp> createState() => _ReportsAppState();
}

class _ReportsAppState extends State<ReportsApp> {
  final TextEditingController _searchController = TextEditingController();
  List<ReportEntry> _allReports = [];
  List<ReportEntry> _filteredReports = [];
  StreamSubscription? _reportsStream;

  @override
  void initState() {
    super.initState();
    _listenToReports();
    _searchController.addListener(_filterReports);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterReports);
    _searchController.dispose();
    _reportsStream?.cancel();
    super.dispose();
  }

  /// Generates mock reports for a list of students.
  List<ReportEntry> _generateMockReportsForStudents(List<QueryDocumentSnapshot> studentDocs) {
      List<ReportEntry> reports = [];
      for (var doc in studentDocs) {
        final studentName = doc['studentName'] as String;
        // For each student, generate a few mock reports.
         reports.addAll([
            ReportEntry(studentName: studentName, title: 'VM School', location: 'South Street, Chennai', date: 'Today', time: '11:00 AM', imagePath: 'assets/VMschool.png', type: ReportType.school, details: {'subject': 'Mathematics', 'grade': 'A+', 'attendance': '95%'}),
            ReportEntry(studentName: studentName, title: 'Library', location: 'West Street, Chennai', date: 'Today', time: '9:00 AM', imagePath: 'assets/library2.png', type: ReportType.library, details: {'bookTitle': 'Intro to Algorithms', 'dueDate': 'July 5, 2025'}),
            ReportEntry(studentName: studentName, title: 'Home', location: 'North Street, Chennai', date: 'Yesterday', time: '9:00 AM', imagePath: 'assets/home2.png', type: ReportType.home, details: {'parentName': doc['parentName'], 'contact': doc['parentMobile']}),
            ReportEntry(studentName: studentName, title: 'Park', location: 'South Street, Chennai', date: 'Dec 30, 2024', time: '5:00 PM', imagePath: 'assets/park.png', type: ReportType.park, details: {'activity': 'Jogging', 'duration': '45 minutes', 'distance': '3 km'}),
         ]);
      }
      // Sort reports to show most recent first.
      reports.sort((a,b) {
        if (a.date == 'Today' && b.date != 'Today') return -1;
        if (b.date == 'Today' && a.date != 'Today') return 1;
        return 0;
      });
      return reports;
  }

  /// Listens to the student data to generate reports.
  void _listenToReports() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .snapshots();

    _reportsStream = stream.listen((snapshot) {
      // NOTE: In a real app, reports would be their own collection.
      // Here, we generate mock reports based on the student list.
       if (mounted) {
          final newReports = _generateMockReportsForStudents(snapshot.docs);
          setState(() {
            _allReports = newReports;
            _filterReports(); // Apply current search query to the new list.
          });
       }
    });
  }

  void _filterReports() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredReports = _allReports;
      } else {
        _filteredReports = _allReports
            .where((report) => report.studentName.toLowerCase().contains(query))
            .toList();
      }
    });
  }
  
  void _showReportDetails(BuildContext context, ReportEntry report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(report.title),
          content: _buildDetailContent(report),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailContent(ReportEntry report) {
    // This function remains the same, showing details based on report type.
     switch (report.type) {
      case ReportType.school:
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Student: ${report.studentName}'), const Divider(), Text('Subject: ${report.details['subject']}'), Text('Grade: ${report.details['grade']}'), Text('Attendance: ${report.details['attendance']}')]);
      case ReportType.library:
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Student: ${report.studentName}'), const Divider(), Text('Book Title: ${report.details['bookTitle']}'), Text('Due Date: ${report.details['dueDate']}')]);
      case ReportType.park:
         return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Student: ${report.studentName}'), const Divider(), Text('Activity: ${report.details['activity']}'), Text('Duration: ${report.details['duration']}'), Text('Distance: ${report.details['distance']}')]);
      case ReportType.home:
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Student: ${report.studentName}'), const Divider(), Text('Parent/Guardian: ${report.details['parentName']}'), Text('Contact: ${report.details['contact']}')]);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _filteredReports.isEmpty && _searchController.text.isNotEmpty
              ? Center(child: Text('No reports found for "${_searchController.text}".'))
              : _allReports.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No student reports to display.\nPlease add a student first from the drawer menu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return GestureDetector(
                  onTap: () => _showReportDetails(context, report),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    elevation: 1,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.asset(report.imagePath, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 60)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(report.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(report.studentName, style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)), // Show student name
                              const SizedBox(height: 4),
                              Text(report.date, style: TextStyle(color: Colors.grey[800], fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(report.time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
