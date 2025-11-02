import 'package:flutter/material.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_home_screen.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_chat_screen.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_delivery_screen.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_profile_screen.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_locator_screen.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_analytics_screen.dart';
import 'package:digital_life_care_app/screens/health_worker/hw_awareness_screen.dart';
import 'package:digital_life_care_app/widgets/reminder_listener.dart';
import 'package:digital_life_care_app/widgets/hw_bottom_nav_router.dart';
import 'package:digital_life_care_app/providers/hw_navigation_provider.dart';

class HealthWorkerShell extends StatefulWidget {
  const HealthWorkerShell({super.key});

  @override
  State<HealthWorkerShell> createState() => _HealthWorkerShellState();
}

class _HealthWorkerShellState extends State<HealthWorkerShell> {
  int _selectedIndex = 0;

  // All screens accessible within shell (indices 0-6)
  // Using IndexedStack to keep all screens in memory and prevent rebuilds
  static final List<Widget> _allScreens = <Widget>[
    const HWHomeScreen(),
    const HWChatScreen(),
    const HWDeliveryScreen(),
    const HWProfileScreen(),
    const HWLocatorScreen(),
    const HWAnalyticsScreen(),
    const HWAwarenessScreen(),
  ];

  void _onItemTapped(int index) {
    // Allow navigation to all screens (0-6)
    // Prevent rapid navigation that might cause stuck buttons
    if (!mounted) return;
    
    if (index >= 0 && index < _allScreens.length && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Register navigation callbacks so TopActions can navigate within shell
    HWNavigationProvider.instance.setNavigationCallback((index) {
      _onItemTapped(index);
    });
  }

  @override
  void dispose() {
    // Clear callback when shell is disposed
    HWNavigationProvider.instance.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Map selected index to bottom nav index (0-3) for bottom nav display
    // Bottom nav shows: Home(0), Chat(1), Delivery(2), Profile(3)
    // But we can navigate to: Home(0), Chat(1), Delivery(2), Profile(3), Locator(4), Analytics(5), Awareness(6)
    final bottomNavIndex = _selectedIndex < 4 ? _selectedIndex : 0; // Show Home icon when on additional screens
    
    return Scaffold(
      body: Column(
        children: [
          const ReminderListener(),
          // Use IndexedStack to keep all screens in memory and prevent state loss
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _allScreens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: HWBottomNavRouter(
        currentIndex: bottomNavIndex,
        onTap: (index) {
          // Bottom nav only has 4 items (0-3), map them directly
          _onItemTapped(index);
        },
      ),
    );
  }
}
