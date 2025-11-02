import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:digital_life_care_app/widgets/hw_top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:digital_life_care_app/widgets/search_bar.dart';
import 'package:digital_life_care_app/providers/hw_navigation_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:digital_life_care_app/providers/reminder_provider.dart';

class HWHomeScreen extends StatelessWidget {
  const HWHomeScreen({super.key});

  Future<void> _acceptBooking(BuildContext context, String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final bookedRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId);

      // read booking first (to get requested/scheduled date and student info)
      final bookedSnap = await bookedRef.get();
      final bookedData =
          (bookedSnap.data() ?? <String, dynamic>{});
      final reqTs = bookedData['requestedDate'] as Timestamp?;
      final scheduledDate =
          reqTs?.toDate() ?? DateTime.now().add(const Duration(days: 1));
      final studentId = (bookedData['studentId'] ?? '').toString();
      final studentName = (bookedData['studentName'] ?? '').toString();

      // Get health worker name from Firestore
      String healthWorkerName = 'Health Worker';
      try {
        final hwDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final hwData = hwDoc.data();
        if (hwData != null) {
          if (hwData.containsKey('username')) {
            healthWorkerName = hwData['username'] as String? ?? healthWorkerName;
          } else if (hwData.containsKey('profile') && hwData['profile'] is Map) {
            final profile = hwData['profile'] as Map<String, dynamic>;
            healthWorkerName = profile['username'] as String? ?? 
                              profile['name'] as String? ?? healthWorkerName;
          }
        }
      } catch (_) {
        // Use default name if fetch fails
      }

      await bookedRef.update({
        'status': 'accepted',
        'assignedTo': uid,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'respondedAt': FieldValue.serverTimestamp(),
      });

      final now = DateTime.now();
      
      // Create reminder for health worker (persists until booking date/time)
      final hwReminderRef = await FirebaseFirestore.instance
          .collection('reminders')
          .add({
            'bookingId': docId,
            'hwId': uid,
            'studentId': studentId,
            'studentName': studentName,
            'scheduledDate': Timestamp.fromDate(scheduledDate),
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'booking',
            'read': false,
            'title': 'Upcoming booking with $studentName',
          });

      // Create reminder for student (persists until booking date/time)
      final studentReminderRef = await FirebaseFirestore.instance
          .collection('reminders')
          .add({
            'bookingId': docId,
            'studentId': studentId,
            'hwId': uid,
            'hwName': healthWorkerName,
            'scheduledDate': Timestamp.fromDate(scheduledDate),
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'booking',
            'read': false,
            'title': 'Upcoming appointment with $healthWorkerName',
          });

      // Schedule multiple notifications leading up to the booking
      // Notifications will appear daily and 1 hour before, until booking date/time
      if (context.mounted) {
        final reminderProvider = context.read<ReminderProvider?>();
        if (reminderProvider != null && scheduledDate.isAfter(now)) {
          final daysUntil = scheduledDate.difference(now).inDays;
          
          // Schedule notification 1 hour before
          final oneHourBefore = scheduledDate.subtract(const Duration(hours: 1));
          if (oneHourBefore.isAfter(now)) {
            await reminderProvider.scheduleBookingNotification(
              reminderId: '${hwReminderRef.id}_1h',
              title: 'Upcoming booking with $studentName',
              body: 'Scheduled for ${DateFormat.yMMMd().add_jm().format(scheduledDate)}',
              scheduledDate: oneHourBefore,
            );
            
            await reminderProvider.scheduleBookingNotification(
              reminderId: '${studentReminderRef.id}_1h',
              title: 'Upcoming appointment with $healthWorkerName',
              body: 'Scheduled for ${DateFormat.yMMMd().add_jm().format(scheduledDate)}',
              scheduledDate: oneHourBefore,
            );
          }
          
          // Schedule daily notifications starting from 3 days before (if applicable)
          // Schedule at 9 AM each day leading up to the booking
          if (daysUntil >= 3) {
            for (int days = 3; days <= daysUntil && days <= 7; days++) { // Limit to 7 days max
              final reminderDate = scheduledDate.subtract(Duration(days: days));
              // Set reminder time to 9 AM on that date
              final reminderTime = DateTime(
                reminderDate.year,
                reminderDate.month,
                reminderDate.day,
                9, // 9 AM
                0,
              );
              
              if (reminderTime.isAfter(now)) {
                // Schedule daily reminder
                final dayStr = days == 1 ? 'day' : 'days';
                await reminderProvider.scheduleBookingNotification(
                  reminderId: '${hwReminderRef.id}_d$days',
                  title: 'Reminder: Booking with $studentName',
                  body: '$days $dayStr until your appointment on ${DateFormat.yMMMd().add_jm().format(scheduledDate)}',
                  scheduledDate: reminderTime,
                );
                
                await reminderProvider.scheduleBookingNotification(
                  reminderId: '${studentReminderRef.id}_d$days',
                  title: 'Reminder: Appointment with $healthWorkerName',
                  body: '$days $dayStr until your appointment on ${DateFormat.yMMMd().add_jm().format(scheduledDate)}',
                  scheduledDate: reminderTime,
                );
              }
            }
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking accepted - Reminders set for both parties')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _declineBooking(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update(
        {'status': 'declined', 'respondedAt': FieldValue.serverTimestamp()},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking declined')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rescheduleBooking(
    BuildContext context,
    String docId,
    DateTime current,
  ) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (newDate == null) return;
    // Optionally pick time, here we keep only date
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({
            'status': 'rescheduled',
            'scheduledDate': Timestamp.fromDate(newDate),
            'respondedAt': FieldValue.serverTimestamp(),
          });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking rescheduled')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatTimestamp(Timestamp? t) {
    if (t == null) return '-';
    final dt = t.toDate();
    return DateFormat.yMMMd().add_jm().format(dt);
  }

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
        title: const Text('Health Worker Home'),
        actions: [const HWTopActions()],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search bar at top
            const AppSearchBar(),
            const SizedBox(height: 8),
            // Event cards - white rectangles with curved edges, 3/4 width
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Awareness card
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // Navigate to Awareness screen (index 6)
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          HWNavigationProvider.instance.navigateToIndex(6);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Awareness',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Upcoming Booking card - shows latest pending booking request
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('status', isEqualTo: 'requested')
                          .orderBy('createdAt', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snap) {
                        final hasPendingBooking = snap.data?.docs.isNotEmpty ?? false;
                        final pendingBooking = hasPendingBooking ? snap.data?.docs.first : null;
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              // Scroll to booking requests below
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Upcoming Booking',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (hasPendingBooking && pendingBooking != null)
                                                Text(
                                                  '${(pendingBooking.data() as Map<String, dynamic>?)?['studentName'] ?? 'Student'} - ${_formatTimestamp((pendingBooking.data() as Map<String, dynamic>?)?['requestedDate'] as Timestamp?)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                )
                                              else
                                                Text(
                                                  'No pending bookings',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasPendingBooking && pendingBooking != null) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Confirm booking by accepting it - wrap in post-frame callback
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _acceptBooking(context, pendingBooking.id);
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      child: const Text('Confirm Booking'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Notifications card
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reminders')
                          .where('hwId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                          .where('read', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snap) {
                        final unreadCount = snap.data?.docs.length ?? 0;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              // Navigate to reminders/chat screen where notifications are shown
                              // Navigate to Chat screen (index 1) where reminders are displayed
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                HWNavigationProvider.instance.navigateToIndex(1);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            Icon(
                                              Icons.notifications,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 24,
                                            ),
                                            if (unreadCount > 0)
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Notifications',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                unreadCount > 0 
                                                    ? '$unreadCount unread alerts'
                                                    : 'No new notifications',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Booking requests list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('status', isEqualTo: 'requested')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error loading bookings: ${snap.error}'),
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No booking requests at the moment.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (c, i) {
                    final d = docs[i];
                    final data =
                        (d.data() ?? <String, dynamic>{})
                            as Map<String, dynamic>;
                    final studentName = (data['studentName'] ?? 'Student')
                        .toString();
                    final requested = data['requestedDate'] as Timestamp?;
                    final requestedStr = _formatTimestamp(requested);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Requested: $requestedStr',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _acceptBooking(context, d.id),
                                    child: const Text('Accept'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rescheduleBooking(
                                      context,
                                      d.id,
                                      requested?.toDate() ?? DateTime.now(),
                                    ),
                                    child: const Text('Reschedule'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Decline',
                                  onPressed: () =>
                                      _declineBooking(context, d.id),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
