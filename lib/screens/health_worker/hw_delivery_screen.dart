import 'package:flutter/material.dart';
import 'package:digital_life_care_app/widgets/hw_top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';

class HWDeliveryScreen extends StatelessWidget {
  const HWDeliveryScreen({super.key});

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
        title: const Text('Deliveries & Orders'),
        actions: [const HWTopActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Health worker view of deliveries and supply requests.'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (c, i) => Card(
                  child: ListTile(
                    title: Text('Order #${i + 1}'),
                    subtitle: const Text('Student requested supplies / meds'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {
                            /* accept */
                          },
                          child: const Text('Accept'),
                        ),
                        TextButton(
                          onPressed: () {
                            /* decline */
                          },
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
