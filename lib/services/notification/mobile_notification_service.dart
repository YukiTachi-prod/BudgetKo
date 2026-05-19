import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'task_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDesc = 'Notifications for upcoming task deadlines';
  static const List<int> _reminderDaysBefore = [7, 5, 3, 1];

  // Linux uses libnotify (fire-and-forget only — no scheduled notifications).
  bool get _supportsScheduling => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    late final InitializationSettings initSettings;

    if (Platform.isLinux) {
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open',
      );
      initSettings = const InitializationSettings(linux: linuxSettings);
    } else if (Platform.isMacOS || Platform.isIOS) {
      const darwinSettings = DarwinInitializationSettings();
      initSettings = const InitializationSettings(
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
    } else {
      // Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      initSettings = const InitializationSettings(android: androidSettings);
    }

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
        ),
      );
    }
  }

  Future<void> scheduleTaskReminders(Task task) async {
    await cancelTaskNotifications(task.id);
    if (task.isFinished || !_supportsScheduling) return;

    final now = DateTime.now();
    final deadline = task.endDate;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    for (final days in _reminderDaysBefore) {
      final scheduled = deadline.subtract(Duration(days: days));
      if (scheduled.isAfter(now)) {
        await _plugin.zonedSchedule(
          task.id.hashCode + days,
          'Task Reminder: ${task.title}',
          'Your task is due in $days days!',
          tz.TZDateTime.from(scheduled, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    if (deadline.isAfter(now)) {
      await _plugin.zonedSchedule(
        task.id.hashCode,
        'Task Due Today: ${task.title}',
        'Your task is due today!',
        tz.TZDateTime.from(deadline, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    if (!_supportsScheduling) return;
    for (final offset in [..._reminderDaysBefore, 0]) {
      await _plugin.cancel(taskId.hashCode + offset);
    }
  }
}
