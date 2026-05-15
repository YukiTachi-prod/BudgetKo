import '../../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {}
  Future<void> scheduleTaskReminders(Task task) async {}
  Future<void> cancelTaskNotifications(String taskId) async {}
}
