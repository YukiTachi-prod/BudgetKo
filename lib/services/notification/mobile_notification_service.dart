import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _alarmChannelId = 'task_alarms';
  static const _alarmChannelName = 'Task Alarms';
  static const _alarmChannelDesc =
      'Loud alarm notifications for important tasks';
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
      final granted = await androidImpl?.areNotificationsEnabled();
      if (granted != true) {
        await androidImpl?.requestNotificationsPermission();
      }
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

  Future<NotificationDetails> _buildDetails(bool isAlarm) async {
    if (!isAlarm) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
        ),
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('alarm_sound_path');
    final channelId = prefs.getString('alarm_channel_id') ?? _alarmChannelId;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        sound: customPath != null
            ? UriAndroidNotificationSound(customPath)
            : const RawResourceAndroidNotificationSound('alarm_sound'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  Future<void> scheduleTaskReminders(Task task) async {
    await cancelTaskNotifications(task.id);
    if (task.isFinished || !_supportsScheduling || !task.hasDates) return;

    final now = DateTime.now();
    final deadline = task.endDate;
    final details = await _buildDetails(task.isAlarm);

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

    if (task.isAlarm) {
      if (task.alarmTriggerDate != null &&
          task.alarmTriggerDate!.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: task.id.hashCode + 900,
          title: 'Alarm: ${task.title}',
          body: 'Your task is starting!',
          scheduledDate: tz.TZDateTime.from(task.alarmTriggerDate!, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        if (task.ringIntervalValue != null && task.ringIntervalUnit != null) {
          int value = task.ringIntervalValue!;
          String unit = task.ringIntervalUnit!;
          for (int i = 1; i <= 30; i++) {
            DateTime scheduled = task.alarmTriggerDate!;
            if (unit == 'minutes') {
              scheduled = scheduled.add(Duration(minutes: value * i));
            } else if (unit == 'hours') {
              scheduled = scheduled.add(Duration(hours: value * i));
            } else if (unit == 'days') {
              scheduled = scheduled.add(Duration(days: value * i));
            } else if (unit == 'weeks') {
              scheduled = scheduled.add(Duration(days: 7 * value * i));
            } else if (unit == 'months') {
              scheduled = scheduled.add(Duration(days: 30 * value * i));
            }

            if (scheduled.isAfter(now)) {
              await _plugin.zonedSchedule(
                id: task.id.hashCode + 1000 + i,
                title: 'Repeating Alarm: ${task.title}',
                body: 'Time for your task!',
                scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
                notificationDetails: details,
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              );
            }
          }
        }
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
    await _plugin.cancel(id: taskId.hashCode + 900);
    for (int i = 1; i <= 30; i++) {
      await _plugin.cancel(id: taskId.hashCode + 1000 + i);
    }
  }

  Future<void> showImmediateNotification(
    String title,
    String body, {
    bool isAlarm = false,
  }) async {
    final details = await _buildDetails(isAlarm);
    await _plugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> scheduleTestNotification(
    int seconds, {
    bool isAlarm = false,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(seconds: seconds));
    final details = await _buildDetails(isAlarm);

    await _plugin.zonedSchedule(
      id: isAlarm ? 99998 : 99999,
      title: 'Test Timed ${isAlarm ? 'Alarm' : 'Notification'}',
      body:
          'This ${isAlarm ? 'alarm' : 'notification'} was scheduled $seconds seconds ago.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
