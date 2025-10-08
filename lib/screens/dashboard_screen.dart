
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: const [Padding(padding: EdgeInsets.only(right: 12.0), child: AppBrand.compact(logoSize: 28))]),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _tile(context, Icons.person, 'Profile', () => Navigator.pushNamed(context, '/profile')),
          _tile(context, Icons.menu_book, 'Awareness', () => Navigator.pushNamed(context, '/awareness')),
          _tile(context, Icons.calendar_month, 'Booking', () {}),
          _tile(context, Icons.alarm, 'Reminders', () {}),
          _tile(context, Icons.chat, 'Chat', () {}),
          _tile(context, Icons.local_hospital, 'Locator', () {}),
          _tile(context, Icons.local_shipping, 'Delivery', () {}),
          _tile(context, Icons.analytics, 'Analytics', () {}),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}


