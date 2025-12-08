import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:provider/provider.dart';
import 'package:digital_life_care_app/providers/reminder_provider.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedSlot;

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _confirmBooking() async {
    if (_selectedDate == null || _selectedSlot == null) return;

    final user = Provider.of<UserProvider>(context, listen: false);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text('Book appointment on $dateStr at $_selectedSlot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Convert slot string → DateTime
        final timeParts = _selectedSlot!.split(' ');
        final timeValue = timeParts[0].split(':');
        final hour = int.parse(timeValue[0]);
        final minute = int.parse(timeValue[1]);
        final isPM = timeParts[1] == 'PM';
        final hour24 = isPM && hour != 12
            ? hour + 12
            : (hour == 12 && !isPM ? 0 : hour);

        final requestedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          hour24,
          minute,
        );

        // Save booking
        await FirebaseFirestore.instance.collection('bookings').add({
          'studentId': uid,
          'studentName': user.username,
          'requestedDate': Timestamp.fromDate(requestedDateTime),
          'selectedTimeSlot': _selectedSlot,
          'status': 'requested',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // AUTO-REMINDER
        final reminderProvider = Provider.of<ReminderProvider>(
          context,
          listen: false,
        );

        await reminderProvider.createReminder(
          uid: uid,
          role: 'student',
          title: "Appointment Reminder",
          scheduledDate: requestedDateTime,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking confirmed and reminder set!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  String _formatTimestamp(Timestamp? t) {
    if (t == null) return '-';
    final dt = t.toDate();
    return DateFormat.yMMMd().add_jm().format(dt);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _selectedSlot = _formatTimeOfDay(picked));
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
        title: const Text('Book an Appointment'),
        actions: const [TopActions()],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CALENDAR CARD ---
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${_selectedDate != null ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}' : 'None'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TableCalendar(
                      firstDay: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focused,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDate, day),

                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDate = selectedDay;
                          _focused = focusedDay;
                          _selectedSlot = null;
                        });
                      },

                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),

                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },

                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Available time slots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 48,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final selected = slot == _selectedSlot;
                return InkWell(
                  onTap: () => setState(() => _selectedSlot = slot),
                  child: Card(
                    color: selected ? Colors.deepPurple : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: selected ? 4 : 1,
                    child: Center(
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (_selectedSlot != null)
                  Chip(
                    label: Text('Preferred: $_selectedSlot'),
                    backgroundColor: Colors.deepPurple.shade100,
                  )
                else
                  const Text('No preferred time selected'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickCustomTime,
                  icon: const Icon(Icons.access_time),
                  label: const Text('Pick custom time'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: (_selectedDate != null && _selectedSlot != null)
                  ? _confirmBooking
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Your Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // FIXED STREAMBUILDER - No index required
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where(
                    'studentId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '',
                  )
                  .snapshots(),

              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Text('No bookings found.');
                }

                // Sort in-memory instead of in the query
                final docs = snap.data!.docs.toList();
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>?;
                  final bData = b.data() as Map<String, dynamic>?;
                  final aTime = (aData?['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  final bTime = (bData?['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  return bTime.compareTo(aTime); // descending order
                });

                // Limit to 5 after sorting
                final limitedDocs = docs.take(5).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limitedDocs.length,
                  itemBuilder: (context, index) {
                    final doc = limitedDocs[index];
                    final data = doc.data() as Map<String, dynamic>?;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
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
                              title: const Text('Delete Booking'),
                              content: const Text(
                                'Are you sure you want to delete this booking?',
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
                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(doc.id)
                                .delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking deleted'),
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
                            Icons.calendar_month,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Appointment: ${_formatTimestamp(data?['requestedDate'])}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Status: ${data?['status'] ?? 'Unknown'}"),
                              if (data?['selectedTimeSlot'] != null)
                                Text(
                                  "Time: ${data!['selectedTimeSlot']}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
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
                          trailing: _getStatusIcon(data?['status']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(String? status) {
    switch (status) {
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'requested':
        return const Icon(Icons.pending, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }
}