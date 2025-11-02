import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class ReminderProvider with ChangeNotifier {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  ReminderProvider();

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await initialize();
  }

  /// Show an immediate local notification (in-app + system)
  Future<void> showImmediateNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    await _ensureInit();
    final androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    final nid = id.hashCode & 0x7fffffff;
    await _local.show(nid, title, body, details);
  }

  /// Schedule a zoned notification for a future date (uses timezone package)
  Future<void> scheduleZonedNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _ensureInit();
    final androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    final tzDest = tz.TZDateTime.from(scheduledDate, tz.local);
    final nid = id.hashCode & 0x7fffffff;
    await _local.zonedSchedule(
      nid,
      title,
      body,
      tzDest,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedule a booking notification (wrapper for scheduleZonedNotification)
  Future<void> scheduleBookingNotification({
    required String reminderId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await scheduleZonedNotification(
      id: reminderId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  /// Stream reminders for either a student or a health worker
  Stream<QuerySnapshot> streamRemindersForUser({
    required String uid,
    required String role,
  }) {
    final col = _fs.collection('reminders');
    if (role == 'health_worker') {
      return col
          .where('hwId', isEqualTo: uid)
          .orderBy('scheduledDate', descending: false)
          .snapshots();
    } else {
      return col
          .where('studentId', isEqualTo: uid)
          .orderBy('scheduledDate', descending: false)
          .snapshots();
    }
  }

  Future<void> markRead(String reminderId) async {
    await _fs.collection('reminders').doc(reminderId).update({'read': true});
  }

  /// Create a new reminder in Firestore and schedule a notification
  Future<void> createReminder({
    required String uid,
    required String role,
    required String title,
    required DateTime scheduledDate,
  }) async {
    final reminderData = <String, dynamic>{
      'title': title,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'reminder',
    };

    if (role == 'health_worker') {
      reminderData['hwId'] = uid;
    } else {
      reminderData['studentId'] = uid;
    }

    final reminderRef = await _fs.collection('reminders').add(reminderData);

    // Schedule local notification
    await scheduleZonedNotification(
      id: reminderRef.id,
      title: title,
      body: 'Reminder: $title',
      scheduledDate: scheduledDate,
    );
  }
}
