import 'package:flutter/material.dart';
import 'dart:async';
import 'home.dart'; // Import the new home page

class FindDevicesPage extends StatefulWidget {
  const FindDevicesPage({super.key});

  @override
  State<FindDevicesPage> createState() => _FindDevicesPageState();
}

class _FindDevicesPageState extends State<FindDevicesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPairing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- FIX: Removed SnackBar and delay for direct navigation ---
  void _pairAndNavigate() async {
    if (_isPairing) return; // Prevent multiple taps

    setState(() {
      _isPairing = true;
    });

    // Simulate a brief pairing process before navigating
    await Future.delayed(const Duration(seconds: 1));

    // The 'mounted' check is crucial before navigating to prevent errors
    // if the user has already left the screen.
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        // This predicate removes all routes beneath the new route,
        // so the user can't go back to the pairing screen.
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pair Your Device'),
        backgroundColor: const Color(0xFF00224C),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Tap on the pulsing button to pair\n your GPS Smart Watch / Chip',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 80),
            // Made the whole ripple area tappable
            GestureDetector(
              onTap: _pairAndNavigate,
              child: CustomPaint(
                painter: RipplePainter(controller: _controller),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 120,
                        height: 120,
                        color: const Color(0xFF00224C),
                        child: const Center(
                          child: Text(
                            'Pair',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final AnimationController controller;
  final Animation<double> _animation;

  RipplePainter({required this.controller})
      : _animation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
        super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    for (int wave = 3; wave >= 0; wave--) {
      _drawCircle(canvas, rect, wave);
    }
  }

  void _drawCircle(Canvas canvas, Rect rect, int wave) {
    final double opacity =
        (1.0 - ((wave + _animation.value) / 4)).clamp(0.0, 1.0);
    final Color color = const Color(0xFF00224C).withOpacity(opacity);
    final double radius = rect.width / 2 * ((wave + _animation.value) / 4);
    final Paint paint = Paint()..color = color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.controller != controller;
  }
}
