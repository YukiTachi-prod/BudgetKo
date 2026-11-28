import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'ledger_provider.dart';
import 'group_wallet_provider.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../utils/date_util.dart';

class AppNotification {
  static const String actionGroupWalletDeleteVote = 'group_wallet_delete_vote';

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final DateTime? dueDate;
  final String? entityKey;
  final String? actionType;
  final String? actionPayload;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.dueDate,
    this.entityKey,
    this.actionType,
    this.actionPayload,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    if (entityKey != null) 'entityKey': entityKey,
    if (actionType != null) 'actionType': actionType,
    if (actionPayload != null) 'actionPayload': actionPayload,
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
        actionType: json['actionType']?.toString(),
        actionPayload: json['actionPayload']?.toString(),
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

    // Check due today / overdue and upcoming subscriptions (within 3 days)
    for (var sub in ledger.subscriptions) {
      if (!sub.isActive) continue;
      final daysUntil = calendarDaysUntil(sub.nextBillingDate, from: now);
      if (daysUntil <= 3) {
        final dateStr = sub.nextBillingDate.toLocal().toString().split(' ')[0];
        final isDueNow = daysUntil <= 0;
        final entityKey = isDueNow ? 'sub_due_${sub.id}' : 'sub_${sub.id}';
        final closedDueDateStr = _closedDueDates[entityKey];
        if (closedDueDateStr != null) {
          final closedDueDate = DateTime.tryParse(closedDueDateStr);
          if (closedDueDate != null &&
              !sub.nextBillingDate.isAfter(closedDueDate)) {
            continue;
          }
        }

        final notifId = isDueNow
            ? 'due_sub_${sub.id}_${sub.nextBillingDate.toIso8601String().substring(0, 10)}'
            : 'upcoming_sub_${sub.id}_${sub.nextBillingDate.toIso8601String().substring(0, 10)}';
        final alreadyExists = _notifications.any((n) => n.id == notifId);

        final title = isDueNow
            ? 'You have a subscription/bill due'
            : 'Upcoming Subscription';
        final message = isDueNow
            ? (daysUntil == 0
                  ? 'Subscription "${sub.name}" is due today ($dateStr). Tap it in Loans & Subs if you\'ve paid.'
                  : 'Subscription "${sub.name}" was due on $dateStr. Tap it in Loans & Subs if you\'ve paid.')
            : 'Subscription "${sub.name}" is due on $dateStr.';

        addNotification(
          AppNotification(
            id: notifId,
            title: title,
            message: message,
            timestamp: DateTime.now(),
            dueDate: sub.nextBillingDate,
            entityKey: entityKey,
          ),
        );

        if (isDueNow && !alreadyExists) {
          NotificationService()
              .showImmediateNotification(title, message)
              .catchError((_) {});
        }
      }
    }
  }

  /// Non-blocking startup check for Shorebird OTA patches.
  /// Adds an in-app notification and triggers an OS notification if a patch is
  /// available or ready to apply on restart.
  Future<void> checkForPatchUpdate({UpdateService? updateService}) async {
    final service = updateService ?? UpdateService();
    final result = await service.checkForPatchOnly();

    if (result.status != UpdateStatus.patchAvailable &&
        result.status != UpdateStatus.restartRequired) {
      return;
    }

    final isRestartRequired = result.status == UpdateStatus.restartRequired;
    final notifId =
        'shorebird_patch_${result.currentVersion}_${result.currentPatchNumber ?? 0}_${result.status.name}';
    final alreadyExists = _notifications.any((n) => n.id == notifId);

    final title = isRestartRequired ? 'App Patch Ready' : 'App Patch Available';
    final message = isRestartRequired
        ? 'A new update patch has been downloaded. Restart BudgetKo to apply it.'
        : 'A new update patch is available for BudgetKo. Open Settings → Scan for Updates to download it.';

    addNotification(
      AppNotification(
        id: notifId,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        entityKey: notifId,
      ),
    );

    if (!alreadyExists) {
      NotificationService()
          .showImmediateNotification(title, message)
          .catchError((_) {});
    }
  }

  /// Syncs active group wallet 2/3 removal votes into in-app notifications so
  /// members who haven't voted yet can confirm directly from Notifications.
  void syncGroupWalletDeleteVotes(GroupWalletProvider groupWallet) {
    final userId = groupWallet.profile?.id;
    final activeVoteIds = <String>{};
    bool changed = false;

    for (final summary in groupWallet.pendingDeleteVotes) {
      if (userId != null && summary.hasVoted(userId)) {
        continue;
      }
      final notifId = 'delete_vote_${summary.walletId}';
      activeVoteIds.add(notifId);

      final title = 'Vote to Remove "${summary.walletName}"';
      final message =
          '${summary.initiatorName} initiated a vote to remove "${summary.walletName}" (${summary.voteCount}/${summary.requiredVotes} votes needed, 2/3 majority). Tap to confirm.';

      final existingIdx = _notifications.indexWhere((n) => n.id == notifId);
      if (existingIdx == -1) {
        _notifications.insert(
          0,
          AppNotification(
            id: notifId,
            title: title,
            message: message,
            timestamp: DateTime.now(),
            entityKey: notifId,
            actionType: AppNotification.actionGroupWalletDeleteVote,
            actionPayload: summary.walletId,
          ),
        );
        changed = true;
      } else if (_notifications[existingIdx].message != message) {
        final prev = _notifications[existingIdx];
        _notifications[existingIdx] = AppNotification(
          id: prev.id,
          title: title,
          message: message,
          timestamp: prev.timestamp,
          isRead: prev.isRead,
          entityKey: prev.entityKey,
          actionType: AppNotification.actionGroupWalletDeleteVote,
          actionPayload: summary.walletId,
        );
        changed = true;
      }
    }

    // Remove stale delete-vote notifications that were completed, cancelled, or already voted on
    final beforeLen = _notifications.length;
    _notifications.removeWhere(
      (n) =>
          n.actionType == AppNotification.actionGroupWalletDeleteVote &&
          !activeVoteIds.contains(n.id),
    );
    if (_notifications.length != beforeLen) {
      changed = true;
    }

    if (changed) {
      _saveToPrefs();
      notifyListeners();
    }
  }
}
