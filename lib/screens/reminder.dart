import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/providers/reminder_provider.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final role = up.role;
    final provider = context.read<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Reminders'),
        actions: const [TopActions()],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: provider.streamRemindersForUser(uid: uid, role: role),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          final now = DateTime.now();

          // Sort documents in-memory
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>?;
            final bData = b.data() as Map<String, dynamic>?;
            final aTime = (aData?['scheduledDate'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bTime = (bData?['scheduledDate'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return aTime.compareTo(bTime); // ascending order
          });

          // Filter for upcoming reminders
          final upcomingReminders = sortedDocs.where((doc) {
            final data = (doc.data() ?? {}) as Map<String, dynamic>;
            final scheduled = data['scheduledDate'] as Timestamp?;
            if (scheduled == null) return false;
            return scheduled.toDate().isAfter(now) ||
                scheduled.toDate().isAtSameMomentAs(now);
          }).toList();

          if (upcomingReminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No upcoming reminders.\nTap + to add one',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: upcomingReminders.length,
            itemBuilder: (c, i) {
              final d = upcomingReminders[i];
              final data =
                  (d.data() ?? <String, dynamic>{}) as Map<String, dynamic>;
              final scheduled = data['scheduledDate'] as Timestamp?;
              final title =
                  data['title'] ??
                  (data['type'] == 'booking' ? 'Booking' : 'Reminder');
              final read = (data['read'] ?? false) as bool;
              final studentName = (data['studentName'] ?? '') as String?;
              final hwName = (data['hwName'] ?? '') as String?;
              final isBooking = data['type'] == 'booking';

              String dateStr = '';
              String timeStr = '';
              if (scheduled != null) {
                final dt = scheduled.toDate();
                dateStr = DateFormat('MMM dd, yyyy').format(dt);
                timeStr = DateFormat('hh:mm a').format(dt);
              }

              String otherParty = role == 'health_worker'
                  ? (studentName ?? '')
                  : (hwName ?? '');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Dismissible(
                  key: Key(d.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Reminder'),
                        content: const Text(
                          'Are you sure you want to delete this reminder?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    try {
                      await provider.deleteReminder(d.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reminder deleted'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: ListTile(
                    leading: Icon(
                      isBooking ? Icons.calendar_month : Icons.notifications,
                      size: 32,
                      color: isBooking
                          ? Theme.of(context).colorScheme.primary
                          : Colors.orange,
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (otherParty.isNotEmpty) ...[
                          Text(
                            otherParty,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swipe left to delete',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 80,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!read)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: const Size(60, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () async {
                              await provider.markRead(d.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Marked read')),
                                );
                              }
                            },
                            child: const Text(
                              'Read',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    onTap: () {
                      if (isBooking) {
                        Navigator.pushNamed(context, '/booking', arguments: d.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_reminder_add',
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final provider = context.read<ReminderProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat('y-MM-dd').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => selectedDate = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(ctx)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (t != null) setState(() => selectedTime = t);
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final up = Provider.of<UserProvider>(ctx, listen: false);
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final role = up.role;

                await provider.createReminder(
                  uid: uid,
                  role: role,
                  title: title,
                  scheduledDate: combinedDateTime,
                );
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reminder saved')));
    }
  }
}