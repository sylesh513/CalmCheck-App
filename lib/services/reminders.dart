/// The practice reminder: an occasional nudge to practise while you're calm.
///
/// Scheduled by the operating system on this device. There is no push service
/// and no server — the app has no network permission at all, so a reminder is
/// the one thing here that reaches out, and it reaches no further than the
/// notification shade.
///
/// The schedule is deliberately inexact. A reminder to breathe does not need to
/// arrive on the second, and asking for exact alarms would mean asking for a
/// permission this app has no business holding.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

enum ReminderPermission { unknown, granted, denied }

class CcReminders {
  CcReminders._();

  static final CcReminders instance = CcReminders._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _tzReady = false;
  ReminderPermission permission = ReminderPermission.unknown;

  static const int _weeklyId = 1001;
  static const String _channelId = 'calmcheck_practice';

  Future<void> warmUp() async {
    if (_ready || kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        // Asked for explicitly when the toggle is turned on, not at launch.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> _initTimeZone() async {
    if (_tzReady) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
      _tzReady = true;
    } catch (_) {
      // Fall back to UTC rather than failing to schedule at all.
      try {
        tzdata.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
        _tzReady = true;
      } catch (_) {
        _tzReady = false;
      }
    }
  }

  /// Asks only when the person turns the toggle on. Returns false if they say
  /// no, so the toggle can go back to off rather than lying about its state.
  Future<bool> requestPermission() async {
    await warmUp();
    if (!_ready) return false;
    try {
      if (Platform.isIOS) {
        final granted =
            await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: false, sound: true) ??
            false;
        permission = granted
            ? ReminderPermission.granted
            : ReminderPermission.denied;
        return granted;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? false;
      permission = granted
          ? ReminderPermission.granted
          : ReminderPermission.denied;
      return granted;
    } catch (_) {
      permission = ReminderPermission.denied;
      return false;
    }
  }

  /// One reminder a week, on a Sunday morning. Practising while calm is the
  /// point; a daily nag would be the opposite of this app.
  Future<void> schedule({int weekday = DateTime.sunday, int hour = 10}) async {
    await warmUp();
    await _initTimeZone();
    if (!_ready || !_tzReady) return;

    await cancel();
    try {
      await _plugin.zonedSchedule(
        _weeklyId,
        'A quiet minute',
        'Practise the breathing now, while things are calm. '
            'It is easier to follow later if your hands already know it.',
        _nextInstance(weekday, hour),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Practice reminders',
            channelDescription:
                'An occasional nudge to practise breathing while you are calm.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(presentBadge: false),
        ),
        // Inexact on purpose: no SCHEDULE_EXACT_ALARM permission is requested.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {
      // A device that refuses to schedule is not an error worth a screen; the
      // toggle simply has no effect and the app is unchanged.
    }
  }

  Future<void> cancel() async {
    await warmUp();
    if (!_ready) return;
    try {
      await _plugin.cancel(_weeklyId);
    } catch (_) {
      // Nothing scheduled.
    }
  }

  tz.TZDateTime _nextInstance(int weekday, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    while (next.weekday != weekday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
