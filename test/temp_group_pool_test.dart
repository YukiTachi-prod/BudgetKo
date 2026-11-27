import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasker/database/budget_database.dart';
import 'package:tasker/models/temp_group_pool_models.dart';
import 'package:tasker/providers/group_wallet_provider.dart';
import 'package:tasker/providers/ledger_provider.dart';
import 'package:tasker/providers/notification_provider.dart';
import 'package:tasker/providers/settings_provider.dart';
import 'package:tasker/providers/temp_group_pool_provider.dart';
import 'package:tasker/screens/budget_screen.dart';
import 'package:tasker/screens/temp_group_pool_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TempGroupPoolProvider Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'creates isolated pool with Cash and E-Cash default categories',
      () async {
        final provider = TempGroupPoolProvider();
        await provider.preload();

        expect(provider.hasActivePool, isFalse);

        final pool = await provider.createPool(
          name: 'Friday Ramen',
          currency: '₱',
        );

        expect(provider.hasActivePool, isTrue);
        expect(pool.name, 'Friday Ramen');
        expect(pool.categories, ['Cash', 'E-Cash']);
        expect(pool.totalPooled, 0.0);
      },
    );

    test(
      'computes pooled total, unique shares, change back, still owed, and category totals',
      () async {
        final provider = TempGroupPoolProvider();
        await provider.preload();
        await provider.createPool(name: 'Samgyup Night', currency: '₱');

        await provider.addParticipant(
          name: 'Alex',
          amountPaid: 500,
          amountToPay: 350,
          category: 'Cash',
          notes: 'Paid with 500 bill',
        );
        await provider.addParticipant(
          name: 'Sam',
          amountPaid: 300,
          amountToPay: 350,
          category: 'E-Cash',
          notes: 'Sent via GCash, owes 50',
        );
        await provider.addParticipant(
          name: 'Jamie',
          amountPaid: 400,
          amountToPay: 400,
          category: 'Cash',
        );

        final pool = provider.activePool!;
        expect(pool.totalPooled, 1200.0);
        expect(pool.totalExpected, 1100.0);
        expect(pool.totalChangeBack, 150.0);
        expect(pool.totalStillOwed, 50.0);
        expect(pool.netBalance, 100.0);
        expect(pool.categoryTotals['Cash'], 900.0);
        expect(pool.categoryTotals['E-Cash'], 300.0);
        expect(pool.participants[0].notes, 'Paid with 500 bill');
        expect(pool.changeFor(pool.participants[0]), 150.0);
        expect(pool.changeFor(pool.participants[1]), -50.0);
        expect(pool.changeFor(pool.participants[2]), 0.0);
      },
    );

    test(
      'supports same amount for everyone and splitting total bill equally',
      () async {
        final provider = TempGroupPoolProvider();
        await provider.preload();
        await provider.createPool(
          name: 'Pizza Split',
          currency: '₱',
          isEqualShare: true,
          equalShareAmount: 250,
        );

        await provider.addParticipant(
          name: 'Alex',
          amountPaid: 500,
          amountToPay: 0,
          category: 'Cash',
        );
        await provider.addParticipant(
          name: 'Sam',
          amountPaid: 250,
          amountToPay: 0,
          category: 'E-Cash',
        );

        expect(provider.activePool!.totalExpected, 500.0);
        expect(
          provider.activePool!.changeFor(provider.activePool!.participants[0]),
          250.0,
        );
        expect(
          provider.activePool!.changeFor(provider.activePool!.participants[1]),
          0.0,
        );

        await provider.splitTotalBillEqually(600);
        expect(provider.activePool!.equalShareAmount, 300.0);
        expect(provider.activePool!.totalExpected, 600.0);
      },
    );

    test(
      'supports custom categories and protects default Cash / E-Cash',
      () async {
        final provider = TempGroupPoolProvider();
        await provider.preload();
        await provider.createPool(name: 'Dinner');

        await provider.addCategory('Card');
        expect(provider.activePool!.categories, ['Cash', 'E-Cash', 'Card']);

        await provider.addParticipant(
          name: 'Alex',
          amountPaid: 400,
          amountToPay: 400,
          category: 'Card',
        );

        // Removing a default category is ignored
        await provider.removeCategory('Cash');
        expect(provider.activePool!.categories.contains('Cash'), isTrue);

        // Removing a custom category reassigns participants to Cash
        await provider.removeCategory('Card');
        expect(provider.activePool!.categories, ['Cash', 'E-Cash']);
        expect(
          provider.activePool!.participants.single.category,
          TempGroupPool.defaultCashCategory,
        );
      },
    );

    test('persists across provider reloads and deletes cleanly', () async {
      final provider1 = TempGroupPoolProvider();
      await provider1.preload();
      final created = await provider1.createPool(name: 'Coffee Run');
      await provider1.addParticipant(
        name: 'Mina',
        amountPaid: 200,
        amountToPay: 145,
        category: 'Cash',
        notes: 'Iced latte',
      );

      final provider2 = TempGroupPoolProvider();
      await provider2.preload();
      expect(provider2.activePool?.name, 'Coffee Run');
      expect(provider2.activePool?.participants.length, 1);
      expect(provider2.activePool?.participants.first.notes, 'Iced latte');

      await provider2.deletePool(created.id);
      expect(provider2.hasActivePool, isFalse);
    });
  });

  group('TempGroupPoolScreen Widget Tests', () {
    late BudgetDatabase db;
    late LedgerProvider ledger;
    late SettingsProvider settings;
    late NotificationProvider notifications;
    late GroupWalletProvider groupWallet;
    late TempGroupPoolProvider tempPool;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = BudgetDatabase(NativeDatabase.memory());
      ledger = LedgerProvider(db);
      settings = SettingsProvider();
      notifications = NotificationProvider();
      groupWallet = GroupWalletProvider();
      tempPool = TempGroupPoolProvider();

      await Future.wait([
        ledger.preload(),
        settings.preload(),
        notifications.preload(),
        groupWallet.preload(),
        tempPool.preload(),
      ]);

      await ledger.addAccount('Personal Wallet', 5000.0);
    });

    tearDown(() async {
      await db.close();
    });

    Widget wrapApp(Widget home) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          Provider<BudgetDatabase>.value(value: db),
          ChangeNotifierProvider<LedgerProvider>.value(value: ledger),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: notifications,
          ),
          ChangeNotifierProvider<GroupWalletProvider>.value(value: groupWallet),
          ChangeNotifierProvider<TempGroupPoolProvider>.value(value: tempPool),
        ],
        child: MaterialApp(home: home),
      );
    }

    testWidgets(
      'creates pool, adds participant with notes, shows circle pool, requires delete+confirm, and never touches personal wallet',
      (tester) async {
        await tester.pumpWidget(wrapApp(const TempGroupPoolScreen()));
        await tester.pumpAndSettle();

        // Empty state
        expect(find.text('Create Temporary Pool'), findsOneWidget);

        // Create pool
        await tester.tap(find.text('Create Temporary Pool'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Team Lunch');
        await tester.tap(find.text('Create Pool'));
        await tester.pumpAndSettle();

        expect(find.text('Team Lunch'), findsOneWidget);
        expect(find.text('MONEY POOL'), findsOneWidget);

        // Add participant
        await tester.tap(
          find.widgetWithText(FloatingActionButton, 'Add Person'),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'Alex');
        await tester.enterText(fields.at(1), '500');
        await tester.enterText(fields.at(2), '320');
        await tester.enterText(fields.at(3), 'Ramen + Gyoza');
        await tester.tap(find.widgetWithText(FilledButton, 'Add'));
        await tester.pumpAndSettle();

        // Participant, note, change back, and total in pool circle are visible
        expect(find.text('Alex'), findsOneWidget);
        expect(find.text('Ramen + Gyoza'), findsOneWidget);
        expect(find.textContaining('Change:'), findsOneWidget);
        expect(find.textContaining('180.00'), findsAtLeastNWidgets(1));
        expect(find.textContaining('500.00'), findsAtLeastNWidgets(1));

        // Cancel delete keeps pool intact
        await tester.tap(find.byTooltip('Delete Temporary Pool'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm Delete'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tempPool.hasActivePool, isTrue);

        // Confirm delete removes pool
        await tester.tap(find.byTooltip('Delete Temporary Pool'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm Delete'));
        await tester.pumpAndSettle();
        expect(tempPool.hasActivePool, isFalse);
        expect(find.text('Create Temporary Pool'), findsOneWidget);

        // Personal wallet is completely untouched
        expect(ledger.accounts.single.currentBalance, 5000.0);
        expect(ledger.allTransactions, isEmpty);
      },
    );

    testWidgets(
      'BudgetScreen app bar button opens Temporary Group Pool screen',
      (tester) async {
        await tester.pumpWidget(wrapApp(const BudgetScreen()));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Temporary Group Pool'));
        await tester.pumpAndSettle();

        expect(find.text('Temporary Group Pool'), findsAtLeastNWidgets(1));
        expect(find.text('Create Temporary Pool'), findsOneWidget);
      },
    );
  });
}
