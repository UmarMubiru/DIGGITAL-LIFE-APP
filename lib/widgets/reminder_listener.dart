import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digital_life_care_app/providers/user_provider.dart';
import 'package:digital_life_care_app/providers/reminder_provider.dart';

class ReminderListener extends StatefulWidget {
  const ReminderListener({super.key});

  @override
  State<ReminderListener> createState() => _ReminderListenerState();
}

class _ReminderListenerState extends State<ReminderListener> {
  StreamSubscription<QuerySnapshot>? _sub;
  DateTime _lastSeen = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final up = context.read<UserProvider>();
    final rp = context.read<ReminderProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _sub?.cancel();
    _sub = rp
        .streamRemindersForUser(uid: uid, role: up.role)
        .listen(
          (snap) async {
            for (final doc in snap.docChanges) {
              if (doc.type == DocumentChangeType.added) {
                final data =
                    (doc.doc.data() ?? <String, dynamic>{})
                        as Map<String, dynamic>;
                final created =
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                if (created.isAfter(_lastSeen)) {
                  final title =
                      data['title'] ??
                      (data['type'] == 'booking'
                          ? 'Booking scheduled'
                          : 'Reminder');
                  final body = data['studentName'] != null
                      ? 'With ${data['studentName']}'
                      : '';
                  // show immediate system/local notification
                  await rp.showImmediateNotification(
                    id: doc.doc.id,
                    title: title.toString(),
                    body: body,
                  );
                  // show in-app banner/snackbar
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$title: $body')));
                  }
                }
              }
            }
            _lastSeen = DateTime.now();
          },
          onError: (e) {
            // ignore errors silently
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // invisible widget; side effect listener only
  }
}
