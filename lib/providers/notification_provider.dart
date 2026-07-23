import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ledger_provider.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
      );
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  NotificationProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('app_notifications');
    if (data != null) {
      _notifications = data
          .map((e) => AppNotification.fromJson(jsonDecode(e)))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notifications.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('app_notifications', data);
  }

  void addNotification(AppNotification notification) {
    // Check if unread notification with same ID already exists to prevent spam
    final existsUnread = _notifications.any(
      (n) => n.id == notification.id && !n.isRead,
    );
    if (!existsUnread) {
      // Remove older notification with same ID if it was read
      _notifications.removeWhere((n) => n.id == notification.id);
      _notifications.insert(0, notification);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _saveToPrefs();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void checkLedgerWarnings(LedgerProvider ledger) {
    for (var acc in ledger.accounts) {
      if (acc.minBalance > 0 && acc.currentBalance < acc.minBalance) {
        addNotification(
          AppNotification(
            id: 'min_balance_${acc.id}',
            title: 'Low Balance Warning',
            message:
                'Account "${acc.name}" has fallen below its minimum balance of ${acc.minBalance}. Current balance is ${acc.currentBalance}.',
            timestamp: DateTime.now(),
          ),
        );
      } else {
        // if balance is restored, remove unread warnings? We can leave it for manual dismissal.
      }
    }

    // Check overdue loans
    final now = DateTime.now();
    for (var loan in ledger.loans) {
      if (!loan.isPaid && loan.dueDate.isBefore(now)) {
        addNotification(
          AppNotification(
            id: 'overdue_loan_${loan.id}',
            title: 'Overdue Loan Warning',
            message:
                'Loan "${loan.creditorName}" was due on ${loan.dueDate.toLocal().toString().split(' ')[0]} and is still unpaid.',
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    // Check upcoming subscriptions (within 3 days)
    for (var sub in ledger.subscriptions) {
      if (sub.isActive &&
          sub.nextBillingDate.isBefore(now.add(const Duration(days: 3)))) {
        addNotification(
          AppNotification(
            id: 'upcoming_sub_${sub.id}_${sub.nextBillingDate.toIso8601String().substring(0, 10)}',
            title: 'Upcoming Subscription',
            message:
                'Subscription "${sub.name}" is due on ${sub.nextBillingDate.toLocal().toString().split(' ')[0]}.',
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }
}
