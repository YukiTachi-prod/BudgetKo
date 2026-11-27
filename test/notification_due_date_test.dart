import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:tasker/database/budget_database.dart';
import 'package:tasker/providers/ledger_provider.dart';
import 'package:tasker/providers/notification_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BudgetDatabase db;
  late LedgerProvider ledger;
  late NotificationProvider notificationProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = BudgetDatabase(NativeDatabase.memory());
    ledger = LedgerProvider(db);
    notificationProvider = NotificationProvider();

    await Future.wait([ledger.preload(), notificationProvider.preload()]);

    await ledger.addAccount('Test Account', 1000);
  });

  tearDown(() async {
    await db.close();
  });

  group('Notification due date suppression tests', () {
    test(
      'Closed subscription notification does not pop back up until next due date',
      () async {
        final now = DateTime.now();
        final due1 = now.add(const Duration(days: 1));
        await ledger.addSubscription(
          name: 'Netflix',
          cost: 15.0,
          billingCycle: 'Monthly',
          nextBillingDate: due1,
          accountId: ledger.accounts.first.id,
        );

        // First check: notification should be generated
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.notifications.length, 1);
        expect(notificationProvider.unreadNotifications.length, 1);
        final notifId = notificationProvider.notifications.first.id;

        // User closes the notification
        notificationProvider.closeNotification(notifId);
        expect(notificationProvider.notifications, isEmpty);
        expect(notificationProvider.unreadNotifications, isEmpty);

        // Second check with same due date: should NOT pop back up
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.notifications, isEmpty);
        expect(notificationProvider.unreadNotifications, isEmpty);

        // Subscription nextBillingDate is updated to next cycle (e.g. next month, but set within 3 days for test)
        final nextDue = due1.add(const Duration(days: 30));
        final sub = ledger.subscriptions.first;
        await ledger.updateSubscription(
          subscriptionId: sub.id,
          name: sub.name,
          cost: sub.cost,
          billingCycle: sub.billingCycle,
          nextBillingDate: nextDue,
          isActive: true,
          accountId: sub.accountId,
        );

        // Check again: nextDue is 30 days away, so not within 3 days -> no notification
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.notifications, isEmpty);

        // Now advance due date to next due date that is within 3 days (e.g. now + 2 days)
        final nextDueSoon = now.add(const Duration(days: 2));
        await ledger.updateSubscription(
          subscriptionId: sub.id,
          name: sub.name,
          cost: sub.cost,
          billingCycle: sub.billingCycle,
          nextBillingDate: nextDueSoon,
          isActive: true,
          accountId: sub.accountId,
        );

        // Next due date has arrived: notification should pop up!
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.notifications.length, 1);
        expect(notificationProvider.unreadNotifications.length, 1);
        expect(
          notificationProvider.notifications.first.title,
          'Upcoming Subscription',
        );
      },
    );

    test(
      'Closed overdue loan notification does not pop back up until next due date',
      () async {
        final now = DateTime.now();
        final due1 = now.subtract(const Duration(days: 2));
        await ledger.addLoan(
          creditorName: 'Bank Loan',
          amount: 500,
          remainingAmount: 500,
          dueDate: due1,
          accountId: ledger.accounts.first.id,
          isOutgoing: false,
        );

        // First check: generates overdue warning
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.notifications.length, 1);
        final notifId = notificationProvider.notifications.first.id;

        // User marks as read / closes it
        notificationProvider.closeNotification(notifId);
        expect(notificationProvider.notifications, isEmpty);

        // Subsequent check: should NOT pop back up
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.notifications, isEmpty);

        // Loan due date is extended to future date then becomes overdue again (next due date)
        final loan = ledger.loans.first;
        final due2 = now.subtract(const Duration(hours: 1)); // later than due1
        await ledger.updateLoan(
          loanId: loan.id,
          creditorName: loan.creditorName,
          amount: loan.amount,
          remainingAmount: loan.remainingAmount,
          dueDate: due2,
          isPaid: false,
          accountId: loan.accountId,
          isOutgoing: loan.isOutgoing,
        );

        // Next due date: notification pops up
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.notifications.length, 1);
        expect(
          notificationProvider.notifications.first.title,
          'Overdue Loan Warning',
        );
      },
    );

    test(
      'Marking notification as read prevents it from resetting to unread on next check',
      () async {
        final now = DateTime.now();
        await ledger.addSubscription(
          name: 'Spotify',
          cost: 10.0,
          billingCycle: 'Monthly',
          nextBillingDate: now.add(const Duration(days: 1)),
          accountId: ledger.accounts.first.id,
        );

        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.unreadNotifications.length, 1);

        final id = notificationProvider.notifications.first.id;
        notificationProvider.markAsRead(id);
        expect(notificationProvider.unreadNotifications, isEmpty);
        expect(notificationProvider.notifications.length, 1);

        // Re-check: notification stays read and unreadNotifications remains empty
        notificationProvider.checkLedgerWarnings(ledger);
        expect(notificationProvider.unreadNotifications, isEmpty);
        expect(notificationProvider.notifications.length, 1);
        expect(notificationProvider.notifications.first.isRead, isTrue);
      },
    );
  });
}
