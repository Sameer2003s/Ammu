import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // For the bar chart

// A simple data model for a student's marks.
class StudentMarks {
  final String studentId;
  final String studentName;
  final Map<String, int> subjectMarks; // e.g., {'Maths': 85, 'Science': 76}

  StudentMarks({
    required this.studentId,
    required this.studentName,
    required this.subjectMarks,
  });

  double get overallPercentage {
    if (subjectMarks.isEmpty) return 0.0;
    final totalMarks = subjectMarks.values.reduce((sum, mark) => sum + mark);
    return (totalMarks / (subjectMarks.length * 100)) * 100;
  }
}

class MarksDetailsPage extends StatefulWidget {
  const MarksDetailsPage({super.key});

  @override
  State<MarksDetailsPage> createState() => _MarksDetailsPageState();
}

class _MarksDetailsPageState extends State<MarksDetailsPage> {
  List<StudentMarks> _studentsMarks = [];
  StudentMarks? _selectedStudent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentMarks();
  }

  /// Fetches student data and generates mock marks for them.
  Future<void> _fetchStudentMarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final studentDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('students')
          .get();

      // NOTE: In a real app, marks would be stored in Firestore.
      // Here, we generate mock marks for demonstration.
      final studentsWithMarks = studentDocs.docs.map((doc) {
        return StudentMarks(
          studentId: doc.id,
          studentName: doc['studentName'] ?? 'No Name',
          subjectMarks: {
            'Maths': 70 + (doc.id.hashCode % 30),
            'Science': 65 + (doc.id.hashCode % 35),
            'History': 75 + (doc.id.hashCode % 25),
            'English': 80 + (doc.id.hashCode % 20),
            'Art': 85 + (doc.id.hashCode % 15),
          },
        );
      }).toList();

      setState(() {
        _studentsMarks = studentsWithMarks;
        if (_studentsMarks.isNotEmpty) {
          _selectedStudent = _studentsMarks.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to load marks: $e')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Marks', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentsMarks.isEmpty
              ? const Center(
                  child: Text(
                    'No students found to display marks.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Column(
                  children: [
                    // --- Student Selector Dropdown ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DropdownButtonFormField<StudentMarks>(
                        value: _selectedStudent,
                        decoration: const InputDecoration(
                          labelText: 'Select Student',
                          border: OutlineInputBorder(),
                        ),
                        items: _studentsMarks.map((student) {
                          return DropdownMenuItem(
                            value: student,
                            child: Text(student.studentName),
                          );
                        }).toList(),
                        onChanged: (student) {
                          if (student != null) {
                            setState(() {
                              _selectedStudent = student;
                            });
                          }
                        },
                      ),
                    ),
                    // --- Marks Display ---
                    if (_selectedStudent != null)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Marks for ${_selectedStudent!.studentName}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 250,
                                child: BarChart(
                                  _createBarChartData(_selectedStudent!),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ..._selectedStudent!.subjectMarks.entries
                                  .map((entry) => ListTile(
                                        title: Text(entry.key),
                                        trailing: Text('${entry.value} / 100',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ))
                                  ,
                              const Divider(height: 30),
                              ListTile(
                                title: const Text('Overall Percentage',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Text(
                                  '${_selectedStudent!.overallPercentage.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF0B3D91),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  /// Creates BarChartData for the marks of a given student.
  BarChartData _createBarChartData(StudentMarks student) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final subjects = student.subjectMarks.keys.toList();
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4.0,
                child: Text(subjects[value.toInt()].substring(0, 3)),
              );
            },
            reservedSize: 30,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: student.subjectMarks.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final mark = entry.value.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: mark.toDouble(),
              color: Colors.blueAccent,
              width: 16,
            ),
          ],
        );
      }).toList(),
    );
  }
}
