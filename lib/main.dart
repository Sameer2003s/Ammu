import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import flutter_dotenv
import 'login.dart';
import 'home.dart'; // Import the HomePage

// Make the main function async and add the dotenv loading
void main() async {
  // Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Load the environment variables from the .env file
  await dotenv.load(fileName: ".env");

  runApp(const AmmuApp());
}

class AmmuApp extends StatelessWidget {
  const AmmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AMMU',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showLoading = true;
        });
      }
    });

    // --- UPDATED NAVIGATION LOGIC ---
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        // Check if a user is currently signed in
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // If the user is logged in, go directly to the HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // If no user is logged in, go to the LoginPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D91), // Dark blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/girl.png'),
                ),
              ),
            ),
            const SizedBox(height: 20),

            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'AMMU',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),

            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Move with Mother Care',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),

            const SizedBox(height: 60),

            _showLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const SizedBox(height: 40, width: 40),
          ],
        ),
      ),
    );
  }
}
