import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/providers/auth_provider.dart';
import 'package:digital_life_care_app/providers/student_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TopActions extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onDeliveryTap;
  final VoidCallback? onLocatorTap;
  final VoidCallback? onAnalyticsTap;

  const TopActions({
    super.key,
    this.onProfileTap,
    this.onDeliveryTap,
    this.onLocatorTap,
    this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    context.watch<AuthProvider>();
    // Check role from both providers for reliability
    final userRole = user.role;
    final isHealthWorker = userRole == 'health_worker' || userRole == 'worker';
    final blue = Theme.of(context).colorScheme.primary;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // For health workers: completely disable profile button
        isHealthWorker
            ? AbsorbPointer(
                child: Opacity(
                  opacity: 0.5, // Visual indication it's disabled
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
              )
            : InkWell(
                onTap: () {
                  // For non-health workers only
                  if (onProfileTap != null) {
                    onProfileTap!();
                  } else {
                    // Navigate within HomeShell (Profile is index 8)
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      StudentNavigationProvider.instance.navigateToIndex(8);
                    });
                  }
                },
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
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
        IconButton(
          tooltip: 'Delivery',
          onPressed: () {
            // ALWAYS block health workers first
            if (isHealthWorker) {
              return;
            }
            if (onDeliveryTap != null) {
              onDeliveryTap!();
            } else {
              // Navigate within HomeShell (Delivery is index 5)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StudentNavigationProvider.instance.navigateToIndex(5);
              });
            }
          },
          icon: Icon(Icons.add_shopping_cart, color: blue),
        ),
        IconButton(
          tooltip: 'Locator',
          onPressed: () {
            // ALWAYS block health workers first
            if (isHealthWorker) {
              return;
            }
            if (onLocatorTap != null) {
              onLocatorTap!();
            } else {
              // Navigate within HomeShell (Locator is index 7)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StudentNavigationProvider.instance.navigateToIndex(7);
              });
            }
          },
          icon: Icon(Icons.location_on, color: blue),
        ),
        IconButton(
          tooltip: 'Analytics',
          onPressed: () {
            // ALWAYS block health workers first
            if (isHealthWorker) {
              return;
            }
            if (onAnalyticsTap != null) {
              onAnalyticsTap!();
            } else {
              // Navigate within HomeShell (Analytics is index 6)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StudentNavigationProvider.instance.navigateToIndex(6);
              });
            }
          },
          icon: Icon(Icons.analytics, color: blue),
        ),
      ],
    );
  }
}


