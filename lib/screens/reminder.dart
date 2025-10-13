import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:digital_life_care_app/providers/reminder_provider.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders!!'),
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          final items = provider.items;
          if (items.isEmpty) {
            return const Center(
              child: Text('No reminders yet. Tap + to add one'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];
              return Card(
                child: ListTile(
                  title: Text(r.title),
                  subtitle: Text('${r.dateTime.toLocal()}'.split('.').first),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => provider.remove(r.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
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
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${selectedDate.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    setState(() => selectedDate = d);
                  }
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
                  if (t != null) {
                    setState(() => selectedTime = t);
                  }
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final id = const Uuid().v4();
                provider.add(
                  Reminder(id: id, title: title, dateTime: combinedDateTime),
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
