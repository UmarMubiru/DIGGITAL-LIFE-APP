// ignore_for_file: deprecated_member_use

import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/providers/hw_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Health Worker specific TopActions - Independent navigation for health workers only
class HWTopActions extends StatelessWidget {
  const HWTopActions({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final blue = Theme.of(context).colorScheme.primary;
    
    void safeNavigate(int index) {
      try {
        // Use a post-frame callback to ensure navigation happens after widget tree is stable
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navProvider = HWNavigationProvider.instance;
          navProvider.navigateToIndex(index);
                });
      } catch (e) {
        debugPrint('Navigation error: $e');
      }
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile icon for health workers - navigates to profile (index 3) within shell
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => safeNavigate(3), // Profile is index 3
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: user.hashColor(),
                backgroundImage: (user.hasPhotoUrl && user.photoUrl.isNotEmpty) 
                    ? NetworkImage(user.photoUrl) as ImageProvider 
                    : null,
                child: (user.hasPhotoUrl && user.photoUrl.isNotEmpty)
                    ? null
                    : Text(
                        user.initials(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ),
        // Delivery button - navigates to delivery (index 2) within shell
        IconButton(
          tooltip: 'Delivery',
          onPressed: () => safeNavigate(2), // Delivery is index 2
          icon: Icon(Icons.add_shopping_cart, color: blue),
          splashRadius: 20,
        ),
        // Locator button - navigates to locator (index 4) within shell
        IconButton(
          tooltip: 'Locator',
          onPressed: () => safeNavigate(4), // Locator is index 4
          icon: Icon(Icons.location_on, color: blue),
          splashRadius: 20,
        ),
        // Analytics button - navigates to analytics (index 5) within shell
        IconButton(
          tooltip: 'Analytics',
          onPressed: () => safeNavigate(5), // Analytics is index 5
          icon: Icon(Icons.analytics, color: blue),
          splashRadius: 20,
        ),
      ],
    );
  }
}
