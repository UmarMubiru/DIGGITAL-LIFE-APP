import 'package:digital_life_care_app/screens/awareness/awareness_home_screen.dart';
import 'package:digital_life_care_app/screens/dashboard_screen.dart';
import 'package:digital_life_care_app/screens/chat/chat_home_screen.dart';
import 'package:digital_life_care_app/screens/booking.dart';
import 'package:digital_life_care_app/screens/reminder.dart';
import 'package:digital_life_care_app/screens/delivery_screen.dart';
import 'package:digital_life_care_app/screens/analytics_screen.dart';
import 'package:digital_life_care_app/screens/locator/locator_list_screen.dart';
import 'package:digital_life_care_app/screens/profile_screen.dart';
import 'package:digital_life_care_app/providers/student_navigation_provider.dart';
import 'package:flutter/material.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  // All student screens accessible within shell (indices 0-8)
  // Using IndexedStack to keep all screens in memory and prevent state loss
  static final List<Widget> _allScreens = <Widget>[
    const DashboardScreen(),        // 0: Home
    const AwarenessHomeScreen(),    // 1: Awareness
    const BookingScreen(),          // 2: Booking
    const ReminderScreen(),         // 3: Reminders
    const ChatHomeScreen(),         // 4: Chat
    const DeliveryScreen(),         // 5: Delivery
    const AnalyticsScreen(),        // 6: Analytics
    const LocatorListScreen(),      // 7: Locator
    const ProfileScreen(),          // 8: Profile
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Register navigation callbacks so TopActions can navigate within shell
    StudentNavigationProvider.instance.setNavigationCallback((index) {
      _navigateToIndex(index);
    });
  }

  @override
  void dispose() {
    // Clear callback when shell is disposed
    StudentNavigationProvider.instance.clear();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    int idx = widget.initialIndex;
    if (args is int) idx = args;
    if (idx != _currentIndex && idx >= 0 && idx < _allScreens.length) {
      _navigateToIndex(idx);
    }
  }

  void _navigateToIndex(int index) {
    // Prevent rapid navigation that might cause stuck buttons
    if (!mounted) return;
    
    if (index >= 0 && index < _allScreens.length && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map selected index to bottom nav index (0-4) for bottom nav display
    // Bottom nav shows: Home(0), Awareness(1), Booking(2), Reminders(3), Chat(4)
    // But we can navigate to: Home(0), Awareness(1), Booking(2), Reminders(3), Chat(4),
    //                          Delivery(5), Analytics(6), Locator(7), Profile(8)
    final bottomNavIndex = _currentIndex < 5 ? _currentIndex : 0; // Show Home icon when on additional screens
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _allScreens,
      ),
      bottomNavigationBar: Container(
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
          selectedIndex: bottomNavIndex,
          onDestinationSelected: (i) {
            // Bottom nav only has 5 items (0-4), map them directly
            _navigateToIndex(i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Awareness',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Booking',
            ),
            NavigationDestination(
              icon: Icon(Icons.alarm_outlined),
              selectedIcon: Icon(Icons.alarm),
              label: 'Reminders',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}
