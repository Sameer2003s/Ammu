import 'package:flutter/material.dart';
import 'dart:math';
import 'marks_details_page.dart'; 
import 'assignments.dart';
// MODIFICATION: Import the new marks page

// --- Main Academic Follow Up Page ---
class AcademicFollowUpPage extends StatefulWidget {
  const AcademicFollowUpPage({super.key});

  @override
  State<AcademicFollowUpPage> createState() => _AcademicFollowUpPageState();
}

class _AcademicFollowUpPageState extends State<AcademicFollowUpPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 60).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addListener(() {
      setState(() {});
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // --- Helper to build the alert cards ---
  Widget _buildAlertCard(BuildContext context, {
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple stays within the rounded corners
      child: InkWell(
        onTap: onTap,
        child: GridTile(
          footer: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image, size: 50)),
          ),
        ),
      ),
    );
  }

  // --- Helper to show detail dialogs (still used for other cards) ---
  void _showDetailsDialog(BuildContext context, String title, List<Widget> children) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Details'),
        content: SingleChildScrollView(
          child: ListBody(children: children),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Academic Follow Up', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alerts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                // MODIFICATION: Navigate to MarksDetailsPage on tap
                _buildAlertCard(context, title: 'Marks', imagePath: 'assets/marks.png', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarksDetailsPage()),
                    );
                }),
                _buildAlertCard(context, title: 'Assignments', imagePath: 'assets/assignments.png', onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AssignmentsPage()),
                    );
                }),
                _buildAlertCard(context, title: 'Events', imagePath: 'assets/events.png', onTap: () {
                     _showDetailsDialog(context, 'Events', const [
                        Text('Parent-Teacher Meeting: June 25th'),
                        Text('Annual Sports Day: July 10th'),
                    ]);
                }),
                _buildAlertCard(context, title: 'Others', imagePath: 'assets/others.png', onTap: () {
                     _showDetailsDialog(context, 'Others', const [
                        Text('Library fine of \$5.00 pending.'),
                        Text('Permission slip for field trip required.'),
                    ]);
                }),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: PerformanceChartPainter(progress: _animation.value),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Image.asset('assets/computer.png', height: 60),
                         const SizedBox(height: 8),
                         Text(
                          '${_animation.value.toInt()}/100',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0B3D91)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to a detailed performance screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigating to detailed performance page...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B3D91),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('View Overall Student Performance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painter for the Performance Chart ---
class PerformanceChartPainter extends CustomPainter {
  final double progress;

  PerformanceChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;
    canvas.drawCircle(center, size.width / 2, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Colors.blue, Color(0xFF0B3D91)],
        startAngle: -pi / 2,
        endAngle: pi * 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
      
    double sweepAngle = 2 * pi * (progress / 100);
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
