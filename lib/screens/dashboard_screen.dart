import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/providers/student_navigation_provider.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppBrand.compact(logoSize: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.username}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () {
              // Block navigation for health workers
              if (user.role == 'health_worker' || user.role == 'worker') {
                return;
              }
              // Navigate within HomeShell (Profile is index 8)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StudentNavigationProvider.instance.navigateToIndex(8);
              });
            },
            customBorder: const CircleBorder(),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          IconButton(
            tooltip: 'Delivery',
            onPressed: () {
              if (user.role == 'health_worker' || user.role == 'worker') return;
              // Navigate within HomeShell (Delivery is index 5)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StudentNavigationProvider.instance.navigateToIndex(5);
              });
            },
            icon: Icon(
              Icons.add_shopping_cart,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            tooltip: 'Locator',
            onPressed: () {
              if (user.role == 'health_worker' || user.role == 'worker') return;
              // Navigate within HomeShell (Locator is index 7)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StudentNavigationProvider.instance.navigateToIndex(7);
              });
            },
            icon: Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            tooltip: 'Analytics',
            onPressed: () {
              if (user.role == 'health_worker' || user.role == 'worker') return;
              // Navigate within HomeShell (Analytics is index 6)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                StudentNavigationProvider.instance.navigateToIndex(6);
              });
            },
            icon: Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          const SizedBox(height: 8),
          const _SearchBar(),
          const SizedBox(height: 32),
          _Narrow(
            child: _SectionCard(
              title: 'Upcoming booking',
              subtitle: 'No upcoming bookings',
              icon: Icons.calendar_month,
              ctaLabel: 'Book now',
              onCta: () {
                if (user.role == 'health_worker' || user.role == 'worker') return;
                Navigator.pushNamed(context, '/booking');
              },
            ),
          ),
          const SizedBox(height: 12),
          _Narrow(
            child: _SectionCard(
              title: 'Health tips for you',
              subtitle: 'Personalized awareness content',
              icon: Icons.menu_book,
              ctaLabel: 'Explore',
              onCta: () {
                if (user.role == 'health_worker' || user.role == 'worker') return;
                Navigator.pushNamed(context, '/awareness');
              },
            ),
          ),
          const SizedBox(height: 12),
          _Narrow(
            child: _SectionCard(
              title: 'Notifications',
              subtitle: 'You have 0 unread alerts',
              icon: Icons.notifications,
              ctaLabel: 'View',
              onCta: () {},
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = days[(dt.weekday - 1) % 7];
    final m = months[dt.month - 1];
    return '$d, $m ${dt.day}';
  }
}

// (Header removed: greeting is now rendered in AppBar title)

class _SearchBar extends StatefulWidget {
  const _SearchBar();
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    Navigator.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: TextField(
        controller: _ctrl,
        onSubmitted: _handleSearch,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade200, // grey background for the search bar
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search',
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String ctaLabel;
  final VoidCallback onCta;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onCta, child: Text(ctaLabel)),
        ],
      ),
    );
  }
}

class _Narrow extends StatelessWidget {
  final Widget child;
  const _Narrow({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = constraints.maxWidth * 0.75;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: targetWidth),
            child: child,
          ),
        );
      },
    );
  }
}
