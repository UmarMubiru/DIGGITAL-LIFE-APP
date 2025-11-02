import 'package:flutter/material.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Route guard that redirects health workers away from student routes
class StudentRouteGuard extends StatelessWidget {
  final Widget child;
  final String routeName;

  const StudentRouteGuard({
    super.key,
    required this.child,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, AuthProvider>(
      builder: (context, userProvider, authProvider, _) {
        final userRole = userProvider.role;
        final isHealthWorker = userRole == 'health_worker' || userRole == 'worker';

        // If health worker tries to access student route, redirect immediately
        if (isHealthWorker) {
          // Use immediate redirect - don't show student screen at all
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/hw',
                (route) => false, // Remove all previous routes
              );
            }
          });
          // Return empty scaffold to prevent any flash
          return const Scaffold(
            body: SizedBox.shrink(),
          );
        }

        return child;
      },
    );
  }
}

