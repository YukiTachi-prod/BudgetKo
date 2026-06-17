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
      settings: initSettings,
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
          id: task.id.hashCode + days,
          title: 'Task Reminder: ${task.title}',
          body: 'Your task is due in $days days!',
          scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }

    if (deadline.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: task.id.hashCode,
        title: 'Task Due Today: ${task.title}',
        body: 'Your task is due today!',
        scheduledDate: tz.TZDateTime.from(deadline, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    if (!_supportsScheduling) return;
    for (final offset in [..._reminderDaysBefore, 0]) {
      await _plugin.cancel(id: taskId.hashCode + offset);
    }
  }
}
