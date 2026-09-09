import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'bulsako_reminders';
  static const _channelName = 'BulsaKo Reminders';
  static const _channelDesc =
      'Notifications for budgets, bills, and subscriptions';
  static const _alarmChannelId = 'bulsako_alarms';
  static const _alarmChannelName = 'BulsaKo Alarms';
  static const _alarmChannelDesc =
      'Loud alarm notifications for important bills and budgets';

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

  Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await androidImpl?.areNotificationsEnabled();
    if (granted != true) {
      await androidImpl?.requestNotificationsPermission();
    }
    // Android 12+ requires exact alarm permission for schedule/zonedSchedule
    // This usually doesn't show a popup unless denied, but it's good to request.
    await androidImpl?.requestExactAlarmsPermission();
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
    await requestPermissions();
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(seconds: seconds));
    final details = await _buildDetails(isAlarm);

    await _plugin.zonedSchedule(
      id: DateTime.now().millisecond, // unique ID to avoid overlapping
      title: 'Test Timed ${isAlarm ? 'Alarm' : 'Notification'}',
      body:
          'This ${isAlarm ? 'alarm' : 'notification'} was scheduled $seconds seconds ago.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
