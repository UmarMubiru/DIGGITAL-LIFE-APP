import 'package:flutter/material.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Analytics'),
        actions: const [TopActions()],
      ),
      body: const Center(
        child: Text('Analytics dashboard coming soon.'),
      ),
    );
  }
}


