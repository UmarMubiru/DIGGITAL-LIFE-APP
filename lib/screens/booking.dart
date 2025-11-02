import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:provider/provider.dart';
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

  // Example time slots
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
        // Combine date and time slot to create a DateTime
        final timeParts = _selectedSlot!.split(' ');
        final timeValue = timeParts[0].split(':');
        final hour = int.parse(timeValue[0]);
        final minute = int.parse(timeValue[1]);
        final isPM = timeParts[1] == 'PM';
        final hour24 = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);
        
        final requestedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          hour24,
          minute,
        );
        
        // Save booking to Firestore
        await FirebaseFirestore.instance.collection('bookings').add({
          'studentId': uid,
          'studentName': user.username,
          'requestedDate': Timestamp.fromDate(requestedDateTime),
          'selectedTimeSlot': _selectedSlot,
          'status': 'requested',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking requested for $dateStr at $_selectedSlot')),
        );
        setState(() {
          _selectedSlot = null;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  String _formatTimestamp(Timestamp? t) {
    if (t == null) return '-';
    final dt = t.toDate();
    return DateFormat.yMMMd().add_jm().format(dt);
  }
  
  String _getStatusColor(String? status) {
    switch (status) {
      case 'accepted':
        return 'Green';
      case 'declined':
        return 'Red';
      case 'rescheduled':
        return 'Orange';
      default:
        return 'Gray';
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickCustomTime() async {
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _selectedSlot = _formatTimeOfDay(picked);
    });
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        'Selected: ${_selectedDate != null ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}' : 'None'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return TableCalendar(
                          firstDay: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDay: DateTime.now().add(
                            const Duration(days: 365),
                          ),
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
                          shouldFillViewport: false, // auto-size calendar
                          daysOfWeekHeight: 36,
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(fontSize: 14, height: 1.2),
                            weekendStyle: TextStyle(fontSize: 14, height: 1.2),
                          ),
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
                        );
                      },
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
                  borderRadius: BorderRadius.circular(10),
                  child: Card(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: selected ? 4 : 1,
                    child: Center(
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
            ),
            const SizedBox(height: 24),
            // Booking Status Section
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Your Bookings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('studentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No bookings yet. Book an appointment above.'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = (doc.data() ?? {}) as Map<String, dynamic>;
                    final status = (data['status'] ?? 'requested') as String;
                    final requested = data['requestedDate'] as Timestamp?;
                    final timeSlot = (data['selectedTimeSlot'] ?? '-') as String;
                    final scheduled = data['scheduledDate'] as Timestamp?;
                    
                    Color statusColor;
                    IconData statusIcon;
                    switch (status) {
                      case 'accepted':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        break;
                      case 'declined':
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        break;
                      case 'rescheduled':
                        statusColor = Colors.orange;
                        statusIcon = Icons.schedule;
                        break;
                      default:
                        statusColor = Colors.grey;
                        statusIcon = Icons.pending;
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${status.toUpperCase()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Requested: ${_formatTimestamp(requested)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (scheduled != null)
                                    Text(
                                      'Scheduled: ${_formatTimestamp(scheduled)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  if (timeSlot != '-')
                                    Text(
                                      'Time Slot: $timeSlot',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
