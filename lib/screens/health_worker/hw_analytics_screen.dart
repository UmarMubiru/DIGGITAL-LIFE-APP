import 'package:flutter/material.dart';
import 'package:digital_life_care_app/widgets/hw_top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';

class HWAnalyticsScreen extends StatelessWidget {
  const HWAnalyticsScreen({super.key});

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
        actions: const [HWTopActions()],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Analytics Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Coming soon...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

