import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ledger_provider.dart';
import '../utils/date_util.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final DateTime? dueDate;
  final String? entityKey;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.dueDate,
    this.entityKey,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    if (entityKey != null) 'entityKey': entityKey,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'] ?? false,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'])
            : null,
        entityKey: json['entityKey'],
      );
}

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  Map<String, String> _closedDueDates = {};

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  Map<String, String> get closedDueDates => Map.unmodifiable(_closedDueDates);

  Future<void>? _loadFuture;

  NotificationProvider() {
    preload();
  }

  Future<void> preload() {
    return _loadFuture ??= _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('app_notifications');
    if (data != null) {
      _notifications = data
          .map((e) => AppNotification.fromJson(jsonDecode(e)))
          .toList();
    }
    final closedData = prefs.getString('closed_notification_due_dates');
    if (closedData != null) {
      try {
        final decoded = jsonDecode(closedData) as Map<String, dynamic>;
        _closedDueDates = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notifications.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('app_notifications', data);
    await prefs.setString(
      'closed_notification_due_dates',
      jsonEncode(_closedDueDates),
    );
  }

  void _recordClosed(AppNotification notification) {
    final key = notification.entityKey ?? notification.id;
    if (notification.dueDate != null) {
      _closedDueDates[key] = notification.dueDate!.toIso8601String();
    } else {
      _closedDueDates[key] = notification.timestamp.toIso8601String();
    }
    _closedDueDates[notification.id] =
        (notification.dueDate ?? notification.timestamp).toIso8601String();
  }

  void addNotification(AppNotification notification) {
    final exists = _notifications.any((n) => n.id == notification.id);
    if (exists) {
      return;
    }
    _notifications.insert(0, notification);
    _saveToPrefs();
    notifyListeners();
  }

  void closeNotification(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final notif = _notifications[idx];
      _recordClosed(notif);
      _notifications.removeAt(idx);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      _recordClosed(_notifications[idx]);
      _saveToPrefs();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
      _recordClosed(n);
    }
    _saveToPrefs();
    notifyListeners();
  }

  void clearAll() {
    for (var n in _notifications) {
      _recordClosed(n);
    }
    _notifications.clear();
    _saveToPrefs();
    notifyListeners();
  }

  void checkLedgerWarnings(LedgerProvider ledger) {
    for (var acc in ledger.accounts) {
      if (acc.minBalance > 0 && acc.currentBalance < acc.minBalance) {
        final closed = _closedDueDates['min_balance_${acc.id}'];
        if (closed != null) {
          continue;
        }
        addNotification(
          AppNotification(
            id: 'min_balance_${acc.id}',
            title: 'Low Balance Warning',
            message:
                'Account "${acc.name}" has fallen below its minimum balance of ${acc.minBalance}. Current balance is ${acc.currentBalance}.',
            timestamp: DateTime.now(),
            entityKey: 'min_balance_${acc.id}',
          ),
        );
      } else {
        _closedDueDates.remove('min_balance_${acc.id}');
      }
    }

    // Check overdue loans
    final now = DateTime.now();
    for (var loan in ledger.loans) {
      if (!loan.isPaid && loan.dueDate.isBefore(now)) {
        final closedDueDateStr = _closedDueDates['loan_${loan.id}'];
        if (closedDueDateStr != null) {
          final closedDueDate = DateTime.tryParse(closedDueDateStr);
          if (closedDueDate != null && !loan.dueDate.isAfter(closedDueDate)) {
            continue;
          }
        }

        addNotification(
          AppNotification(
            id: 'overdue_loan_${loan.id}',
            title: 'Overdue Loan Warning',
            message:
                'Loan "${loan.creditorName}" was due on ${loan.dueDate.toLocal().toString().split(' ')[0]} and is still unpaid.',
            timestamp: DateTime.now(),
            dueDate: loan.dueDate,
            entityKey: 'loan_${loan.id}',
          ),
        );
      }
    }

    // Check upcoming subscriptions (within 3 days)
    for (var sub in ledger.subscriptions) {
      if (sub.isActive &&
          calendarDaysUntil(sub.nextBillingDate, from: now) <= 3) {
        final closedDueDateStr = _closedDueDates['sub_${sub.id}'];
        if (closedDueDateStr != null) {
          final closedDueDate = DateTime.tryParse(closedDueDateStr);
          if (closedDueDate != null &&
              !sub.nextBillingDate.isAfter(closedDueDate)) {
            continue;
          }
        }

        addNotification(
          AppNotification(
            id: 'upcoming_sub_${sub.id}_${sub.nextBillingDate.toIso8601String().substring(0, 10)}',
            title: 'Upcoming Subscription',
            message:
                'Subscription "${sub.name}" is due on ${sub.nextBillingDate.toLocal().toString().split(' ')[0]}.',
            timestamp: DateTime.now(),
            dueDate: sub.nextBillingDate,
            entityKey: 'sub_${sub.id}',
          ),
        );
      }
    }
  }
}
