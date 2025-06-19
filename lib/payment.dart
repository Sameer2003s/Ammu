import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // For payment gateway
import 'subscription.dart'; // To access the Plan class

class PaymentScreen extends StatefulWidget {
  // This now correctly accepts the plan from the previous screen.
  final Plan plan;

  const PaymentScreen({super.key, required this.plan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  String? _selectedPaymentMethod = 'Apple Pay';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    // Set up event listeners for payment outcomes.
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear the Razorpay instance on dispose.
    super.dispose();
  }

  // --- Payment Gateway Logic ---

  /// Starts the payment process when the "Proceed" button is pressed.
  void _startPayment() {
    // Extract the numeric price from the plan's price string (e.g., "₹199 / per month" -> 199)
    final priceString = widget.plan.price.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(priceString) ?? 0;

    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // <-- IMPORTANT: Replace with your Razorpay test key
      'amount': amount * 100, // Amount in the smallest currency unit (e.g., paise for INR)
      'name': 'Ammu App',
      'description': 'Purchase of ${widget.plan.name}',
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
        'email': FirebaseAuth.instance.currentUser?.email ?? 'user@example.com'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  /// Handles a successful payment.
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _updateUserSubscription();
  }

  /// Handles a failed payment.
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Handles redirection to an external wallet (like Google Pay).
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet Selected: ${response.walletName}');
  }

  /// Updates the user's subscription in Firestore after a successful payment.
  Future<void> _updateUserSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'activePlan': widget.plan.name,
        'studentLimit': widget.plan.studentLimit,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.plan.name} purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back two screens to return to the home page.
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update subscription: $e')),
        );
      }
    }
  }

  // --- UI Builder ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment', style: TextStyle(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the payment method you want to use.',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            const SizedBox(height: 16),
            // The UI for selecting payment methods remains visually the same.
            _buildPaymentMethodCard(
              context,
              logoPath: 'assets/paytm.png',
              methodName: 'Paytm',
              value: 'Paytm',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodCard(
              context,
              logoPath: 'assets/stripe.png',
              methodName: 'Stripe',
              value: 'Stripe',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodCard(
              context,
              logoPath: 'assets/upi.png',
              methodName: 'UPI',
              value: 'UPI',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodCard(
              context,
              logoPath: 'assets/applepay.png',
              methodName: 'Apple Pay',
              value: 'Apple Pay',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodCard(
              context,
              iconData: Icons.add,
              methodName: 'Add New Card',
              value: 'Add New Card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // The "Proceed" button now starts the payment flow.
                onPressed: _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Proceed',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context, {
    String? logoPath,
    IconData? iconData,
    required String methodName,
    required String value,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: logoPath != null
                    ? Image.asset(logoPath, height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24, color: Colors.grey))
                    : (iconData != null ? Icon(iconData, size: 24, color: Colors.black54) : const SizedBox.shrink()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(methodName, style: const TextStyle(fontSize: 16, color: Colors.black)),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF0D47A1),
              fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF0D47A1);
                }
                return Colors.grey.shade400;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
