import 'package:app_flutter/ui/pages/payment_card_form_page.dart';
import 'package:flutter/material.dart';

class PremiumOfferScreen extends StatelessWidget {
  const PremiumOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Place for your product image",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Join Millions of\nHappy Users",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const FeatureList(),
              const SizedBox(height: 30),
              const SubscriptionPlans(),
              const SizedBox(height: 16),
              const Text(
                "After 7 days be charged\nCancel anytime",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentCardFormPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Start for free for 7 days",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "After your 7-day free trial, the subscription fee will be charged to your account.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureList extends StatelessWidget {
  const FeatureList({super.key});

  @override
  Widget build(BuildContext context) {
    const features = [
      "Remove all ads",
      "New program every day",
      "For less than the price of a coffee",
      "Multi-programs",
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class SubscriptionPlans extends StatelessWidget {
  const SubscriptionPlans({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PlanCard(duration: "1 month", price: "\$6.99/month", highlight: false),
        const SizedBox(width: 16),
        _PlanCard(
          duration: "12 months",
          price: "\$29.99\n\$2.48/month",
          highlight: true,
          badgeText: "Save 63%",
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String duration;
  final String price;
  final bool highlight;
  final String? badgeText;

  const _PlanCard({
    required this.duration,
    required this.price,
    this.highlight = false,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = highlight ? Colors.white : Colors.grey.shade200;
    final borderColor = highlight ? Colors.purple : Colors.transparent;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badgeText!, style: const TextStyle(fontSize: 10)),
              ),
            const SizedBox(height: 8),
            Text(duration, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              price,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
