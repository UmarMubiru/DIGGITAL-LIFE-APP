import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedSlot;

  // Example time slots (could be generated or fetched)
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booked $dateStr at $_selectedSlot')),
      );
      // Reset selection (mock behavior)
      setState(() {
        _selectedSlot = null;
      });
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
    // Capture messenger before awaiting if we might show snackbars later
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
      appBar: AppBar(title: const Text('Book an Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visible selected date indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Text(
                        'Selected: ${_selectedDate != null ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}' : 'None'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Fixed-height calendar so it's visible on all layouts
                    SizedBox(
                      height: 300,
                      child: TableCalendar(
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
                            _selectedSlot =
                                null; // clear slot when changing date
                          });
                        },
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                'Available time slots',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
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
                    child: Card(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : null,
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
            ),
            const SizedBox(height: 8),
            // Show selected slot (either preset or custom)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  if (_selectedSlot != null)
                    Chip(label: Text('Preferred: $_selectedSlot'))
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
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_selectedDate != null && _selectedSlot != null)
                        ? _confirmBooking
                        : null,
                    child: const Text('Confirm Booking'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
