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
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {},
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
          id: uniqueId,
          title: 'Task Reminder: ${task.title}',
          body: 'Your task is due in $days days!',
          scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription: 'Notifications for upcoming task deadlines',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }

    // Always schedule a notification for the deadline day itself if it's in the future
    if (deadline.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        id: task.id.hashCode,
        title: 'Task Due Today: ${task.title}',
        body: 'Your task is due today!',
        scheduledDate: tz.TZDateTime.from(deadline, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for upcoming task deadlines',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    // Cancel IDs for 7, 5, 3, 1, and 0 (due date)
    final List<int> idsToCancel = [7, 5, 3, 1, 0];
    for (int offset in idsToCancel) {
      await _notificationsPlugin.cancel(id: taskId.hashCode + offset);
    }
  }
}
