import 'package:flutter/material.dart';

class BottomNavRouter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<NavigationDestination>? destinations;

  const BottomNavRouter({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.destinations,
  });

  List<NavigationDestination> _getDestinations() {
    if (destinations != null) return destinations!;
    
    // Student destinations only
    return const [
      NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.info), label: 'Awareness'),
      NavigationDestination(
        icon: Icon(Icons.local_shipping),
        label: 'Delivery',
      ),
      NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2FF59), Color(0xFF81D4FA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          // If an external shell provided onTap, call it and don't navigate.
          if (onTap != null) {
            onTap!(idx);
            return;
          }

          // Navigate using app routes (student routes only)
          switch (idx) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/awareness');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/delivery');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        destinations: _getDestinations(),
      ),
    );
  }
}
