import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'login.dart'; // Your existing login page
import 'bluetooth.dart'; // Import the bluetooth page
import 'package:cloud_firestore/cloud_firestore.dart'; // Import firestore
import 'dart:async'; // Import for Future.delayed

class SignUP extends StatefulWidget {
  const SignUP({super.key});

  @override
  _SignUPState createState() => _SignUPState();
}

class _SignUPState extends State<SignUP> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;

  // --- Helper to create user document in Firestore ---
  Future<void> _createUserDocument(User user, {String? mobile}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    // Create document only if it doesn't exist (for social sign-ins)
    if (!snapshot.exists) {
      await userDoc.set({
        'email': user.email,
        'displayName': user.displayName,
        'mobile': mobile ?? '', // Use provided mobile or empty string
        'photoURL': user.photoURL,
        'createdAt': Timestamp.now(),
      });
    }
  }
  
  // --- EMAIL/PASSWORD SIGN-UP ---
  Future<void> _signUpWithEmailAndPassword() async {
    FocusScope.of(context).unfocus();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String mobile = _mobileController.text.trim();

    if (mobile.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (!emailRegex.hasMatch(email)) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (password.length < 6) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        await _createUserDocument(userCredential.user!, mobile: mobile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registered successfully! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // --- Improved Error Handling ---
      String message = 'An error occurred. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered. Please log in.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- GOOGLE SIGN-IN ---
  Future<void> _signInWithSocial(Future<OAuthCredential> Function() provider) async {
    setState(() => _isLoading = true);
    try {
      final credential = await provider();
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!); // Create doc if new user
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const BluetoothPage()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<OAuthCredential> _googleProvider() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign in cancelled');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  Future<OAuthCredential> _facebookProvider() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) {
      throw Exception('Facebook sign in failed: ${result.message}');
    }
    return FacebookAuthProvider.credential(result.accessToken!.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: TopHalfCircleClipper(),
                    child: Container(
                      height: 250,
                      width: double.infinity,
                      color: const Color(0xFF0B3D91),
                    ),
                  ),
                  Positioned(
                    top: 70,
                    child: Image.asset('assets/illustrator.png', height: 190),
                  ),
                ],
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Welcome to AMMU!',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 25),
                        TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                labelText: 'Mobile Number',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 15),
                        TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'E-mail',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 15),
                        TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder())),
                        const SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUpWithEmailAndPassword,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B3D91),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14)),
                                child: const Text('Sign Up',
                                    style:
                                        TextStyle(color: Colors.white)))),
                        const SizedBox(height: 10),
                        TextButton(
                            onPressed: _isLoading ? null : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage())),
                            child: const Text(
                                'Already have an account? Log In')),
                        const Divider(height: 40),
                        const Text('Or Sign Up with'),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _signInWithSocial(_googleProvider),
                              icon: Image.asset(
                                'assets/googleicon.png',
                                height: 24.0,
                                width: 24.0,
                              ),
                              label: const Text("Google"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side:
                                      const BorderSide(color: Colors.grey)),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () => _signInWithSocial(_facebookProvider),
                              icon: const Icon(Icons.facebook,
                                  color: Colors.blue),
                              label: const Text("Facebook"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  side:
                                      const BorderSide(color: Colors.grey)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class TopHalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 100);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 100);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
