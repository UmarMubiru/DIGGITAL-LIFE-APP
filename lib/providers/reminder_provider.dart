import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart'
    as native_tz;
import 'package:shared_preferences/shared_preferences.dart';

class Reminder {
  final String id;
  final String title;
  final DateTime dateTime;

  Reminder({required this.id, required this.title, required this.dateTime});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dateTime': dateTime.toIso8601String(),
  };

  static Reminder fromJson(Map<String, dynamic> j) => Reminder(
    id: j['id'] as String,
    title: j['title'] as String,
    dateTime: DateTime.parse(j['dateTime'] as String),
  );
}

class ReminderProvider extends ChangeNotifier {
  static const _kKey = 'app.reminders';
  final List<Reminder> _items = [];
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  List<Reminder> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey) ?? [];
    _items.clear();
    for (final s in raw) {
      try {
        final m = json.decode(s) as Map<String, dynamic>;
        _items.add(Reminder.fromJson(m));
      } catch (_) {}
    }
    await _initNotifications();
    // (re)create scheduled notifications for existing reminders
    for (final r in _items) {
      await _scheduleForReminder(r);
    }
    notifyListeners();
  }

  Future<void> add(Reminder r) async {
    _items.add(r);
    await _scheduleForReminder(r);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    final toRemove = _items.where((e) => e.id == id).toList();
    for (final r in toRemove) {
      await _cancelNotificationsForReminder(r);
    }
    _items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_kKey, list);
  }

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    try {
      await _notifications.initialize(initSettings);
      // init timezone
      try {
        tzdata.initializeTimeZones();
        final name = await native_tz.FlutterNativeTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {}
      _notificationsInitialized = true;
    } catch (_) {
      // ignore initialization errors
      _notificationsInitialized = false;
    }
  }

  int _baseIdFor(String id) => id.hashCode & 0x7fffffff;

  Future<void> _scheduleForReminder(Reminder r) async {
    if (!_notificationsInitialized) return;
    final base = _baseIdFor(r.id);
    final dayBeforeId = base;
    final onDayId = base + 1;

    final scheduledOnDay = DateTime(
      r.dateTime.year,
      r.dateTime.month,
      r.dateTime.day,
      r.dateTime.hour,
      r.dateTime.minute,
    );
    final dayBefore = scheduledOnDay.subtract(const Duration(days: 1));

    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notifications for scheduled reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    try {
      if (dayBefore.isAfter(now)) {
        await _notifications.zonedSchedule(
          dayBeforeId,
          'Reminder (1 day left)',
          r.title,
          tz.TZDateTime.from(dayBefore, tz.local),
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      }
    } catch (_) {
      // If zoned scheduling fails we skip the notification (platform may not support).
    }

    try {
      if (scheduledOnDay.isAfter(now)) {
        await _notifications.zonedSchedule(
          onDayId,
          'Reminder (Today)',
          r.title,
          tz.TZDateTime.from(scheduledOnDay, tz.local),
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
        );
      }
    } catch (_) {
      // If zoned scheduling fails we skip the notification (platform may not support).
    }
  }

  Future<void> _cancelNotificationsForReminder(Reminder r) async {
    if (!_notificationsInitialized) return;
    final base = _baseIdFor(r.id);
    final dayBeforeId = base;
    final onDayId = base + 1;
    try {
      await _notifications.cancel(dayBeforeId);
      await _notifications.cancel(onDayId);
    } catch (_) {}
  }
}
