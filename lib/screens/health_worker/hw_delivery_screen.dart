import 'package:flutter/material.dart';
import 'package:digital_life_care_app/screens/delivery_screen.dart';

class HWDeliveryScreen extends StatelessWidget {
  const HWDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the main DeliveryScreen which already contains the
    // health-worker stock management UI. This ensures HWs see the
    // integrated stock/order interface rather than an outdated placeholder.
    return const DeliveryScreen();
  }
}
