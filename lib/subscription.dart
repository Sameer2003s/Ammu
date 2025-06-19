import 'package:flutter/material.dart';
import 'payment.dart'; // Import the payment.dart file

// --- Data Model for a Subscription Plan ---
class Plan {
  final String name;
  final String price;
  final String imagePath;
  final List<String> features;
  final int studentLimit;

  const Plan({
    required this.name,
    required this.price,
    required this.imagePath,
    required this.features,
    required this.studentLimit,
  });
}

// --- Main Subscription Screen ---
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // --- List of Available Plans ---
  final List<Plan> _plans = const [
    Plan(
      name: 'Parents Plan',
      price: '₹199 / per month',
      imagePath: 'assets/parents_plan.png', 
      features: [
        'Track up to 2 children',
        '7-day location history',
        'SOS alerts',
      ],
      studentLimit: 2,
    ),
    Plan(
      name: 'School Plan',
      price: '₹999 / per month',
      imagePath: 'assets/school_plan.png', 
      features: [
        'Limit up to 1000 students',
        'Past month location records are shown',
        'Admin dashboard access',
      ],
      studentLimit: 1000,
    ),
    Plan(
      name: 'University Plan',
      price: '₹3999 / per month',
      imagePath: 'assets/university_plan.png', 
      features: [
        'Unlimited student tracking',
        'Full year location records',
        'Advanced analytics and reports',
      ],
      studentLimit: 100000,
    ),
  ];

  late Plan _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = _plans.firstWhere((p) => p.name == 'School Plan', orElse: () => _plans[1]);
  }
  
  // --- UI Builder Methods ---

  /// Builds the top card which dynamically displays the selected plan's details.
  Widget _buildHeaderCard(Plan plan) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            plan.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            // MODIFICATION: Use 'assets/sub.png' as the fallback image
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/sub.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a selectable radio tile for a given plan.
  Widget _buildPlanSelectionTile(Plan plan) {
    bool isSelected = _selectedPlan.name == plan.name;
    return Card(
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected ? const Color(0xFF0D47A1).withOpacity(0.5) : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.transparent,
          width: 2,
        ),
      ),
      child: RadioListTile<Plan>(
        value: plan,
        groupValue: _selectedPlan,
        onChanged: (newPlan) {
          if (newPlan != null) {
            setState(() {
              _selectedPlan = newPlan;
            });
          }
        },
        title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(plan.price),
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Subscription Plan', style: TextStyle(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(_selectedPlan),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._plans.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildPlanSelectionTile(plan),
                  )).toList(),
                ],
              ),
            ),
          ),
          // --- Centralized 'Proceed to Pay' Button ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(plan: _selectedPlan),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Proceed to Pay (${_selectedPlan.price.split(' ')[0]})', // Shows price on button
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
