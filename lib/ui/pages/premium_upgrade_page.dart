import 'package:animate_do/animate_do.dart';
import 'package:app_flutter/ui/pages/payment_card_form_page.dart';
import 'package:flutter/material.dart';

class PremiumOfferScreen extends StatelessWidget {
  const PremiumOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8456FF), Color(0xFFffd6ec)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "PREMIUM",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: Column(
                  children: const [
                    Text(
                      "Actualmente tienes el plan básico",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF391968),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Accede al plan premium para obtener beneficios exclusivos como:",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeInLeft(
                duration: const Duration(milliseconds: 700),
                child: const FeatureList(),
              ),
              const SizedBox(height: 24),
              FadeInRight(
                duration: const Duration(milliseconds: 700),
                child: const SubscriptionPlans(),
              ),
              const SizedBox(height: 30),
              ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_open, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentQRPage(),
                        ),
                      );
                    },
                    label: const Text(
                      "Acceder al plan premium",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
      "Asesoría con psicólogos",
      "Chat con profesionales",
      "Acceso a eventos únicos",
      "Soporte prioritario",
      "Funciones exclusivas",
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
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
        _PlanCard(
          duration: "Plan Básico",
          price: "Sin costo",
          highlight: false,
        ),
        const SizedBox(width: 16),
        _PlanCard(
          duration: "Mensual",
          price: "S/ 28.90\nS/ 25.90/mes",
          highlight: true,
          badgeText: "¡Plan Premium!",
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
    final bgColor = highlight
        ? Colors.deepPurple.shade50
        : Colors.grey.shade100;
    final borderColor = highlight ? Colors.deepPurple : Colors.transparent;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              duration,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.deepPurple : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.8,
                color: highlight ? Colors.deepPurple : Colors.black54,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
