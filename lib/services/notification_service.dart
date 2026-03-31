import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Create a notification channel for Android
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_reminders',
            'Task Reminders',
            description: 'Notifications for upcoming task deadlines',
            importance: Importance.max,
          ),
        );
  }

  Future<void> scheduleTaskReminders(Task task) async {
    // First, cancel any existing notifications for this task
    await cancelTaskNotifications(task.id);

    if (task.isFinished) return;

    final now = DateTime.now();
    final deadline = task.endDate;

    // Only notify at specific "odd" days before deadline: 7, 5, 3, 1
    final List<int> daysBefore = [7, 5, 3, 1];

    for (int days in daysBefore) {
      final scheduledDate = deadline.subtract(Duration(days: days));

      // Only schedule if the calculated date is in the future
      if (scheduledDate.isAfter(now)) {
        final int uniqueId = task.id.hashCode + days;

        await _notificationsPlugin.zonedSchedule(
          uniqueId,
          'Task Reminder: ${task.title}',
          'Your task is due in $days days!',
          tz.TZDateTime.from(scheduledDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription: 'Notifications for upcoming task deadlines',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    // Always schedule a notification for the deadline day itself if it's in the future
    if (deadline.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        task.id.hashCode, // Offset 0 for the due date
        'Task Due Today: ${task.title}',
        'Your task is due today!',
        tz.TZDateTime.from(deadline, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for upcoming task deadlines',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    // Cancel IDs for 7, 5, 3, 1, and 0 (due date)
    final List<int> idsToCancel = [7, 5, 3, 1, 0];
    for (int offset in idsToCancel) {
      await _notificationsPlugin.cancel(taskId.hashCode + offset);
    }
  }
}
