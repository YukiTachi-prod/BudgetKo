import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:tasker/database/budget_database.dart';
import 'package:tasker/providers/ledger_provider.dart';
import 'package:tasker/providers/notification_provider.dart';
import 'package:tasker/providers/settings_provider.dart';
import 'package:tasker/providers/group_wallet_provider.dart';
import 'package:tasker/screens/budget_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider - Hide Total Amount', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('hideTotalAmount defaults to true', () async {
      final settings = SettingsProvider();
      await settings.preload();
      expect(settings.hideTotalAmount, isTrue);
    });

    test('toggleHideTotalAmount flips boolean value', () async {
      final settings = SettingsProvider();
      await settings.preload();
      expect(settings.hideTotalAmount, isTrue);

      await settings.toggleHideTotalAmount();
      expect(settings.hideTotalAmount, isFalse);

      await settings.toggleHideTotalAmount();
      expect(settings.hideTotalAmount, isTrue);
    });

    test('setHideTotalAmount sets explicit value', () async {
      final settings = SettingsProvider();
      await settings.preload();

      await settings.setHideTotalAmount(false);
      expect(settings.hideTotalAmount, isFalse);

      await settings.setHideTotalAmount(true);
      expect(settings.hideTotalAmount, isTrue);
    });
  });

  group('MainTab and BudgetScreen Widget Tests', () {
    late BudgetDatabase db;
    late LedgerProvider ledger;
    late SettingsProvider settings;
    late NotificationProvider notifications;
    late GroupWalletProvider groupWallet;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = BudgetDatabase(NativeDatabase.memory());
      ledger = LedgerProvider(db);
      settings = SettingsProvider();
      notifications = NotificationProvider();
      groupWallet = GroupWalletProvider();

      await Future.wait([
        ledger.preload(),
        settings.preload(),
        notifications.preload(),
        groupWallet.preload(),
      ]);

      // Add a test account
      await ledger.addAccount('Test GCash', 5000.0);
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          Provider<BudgetDatabase>.value(value: db),
          ChangeNotifierProvider<LedgerProvider>.value(value: ledger),
          ChangeNotifierProvider<NotificationProvider>.value(
            value: notifications,
          ),
          ChangeNotifierProvider<GroupWalletProvider>.value(value: groupWallet),
        ],
        child: const MaterialApp(home: BudgetScreen()),
      );
    }

    testWidgets('BudgetScreen has tabs without Group tab', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Main'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Wallet'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Group'), findsNothing);
      expect(find.widgetWithText(Tab, 'Expenses'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Loans & Subs'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Analytics'), findsOneWidget);
    });

    testWidgets(
      'Group wallet setup in window and return to Main preserve personal wallet',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Group Wallet Window'));
        await tester.pumpAndSettle();
        expect(find.text('Create Your Local Profile'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await groupWallet.saveProfile('Alex', 0xFF2196F3);
        await tester.pumpAndSettle();
        expect(find.text('Connect Supabase API'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Total Balance'), findsOneWidget);
        expect(ledger.accounts.single.currentBalance, 5000);
      },
    );

    testWidgets('Group wallet window opens and closes independently', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Group Wallet Window'));
      await tester.pumpAndSettle();
      expect(find.text('Group Wallet'), findsOneWidget);
      expect(find.text('Create Your Local Profile'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Total Balance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Main tab group wallet card Open button launches Group Wallet window',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Open'));
        await tester.pumpAndSettle();
        expect(find.text('Group Wallet'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Total Balance'), findsOneWidget);
      },
    );

    testWidgets('Main tab displays total amount hidden by default', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Total balance label exists
      expect(find.text('Total Balance'), findsOneWidget);

      // Amount should be hidden by default (masked with bullets)
      expect(find.textContaining('••••••'), findsAtLeastNWidgets(1));

      // 5000.00 should NOT be visible when hidden
      expect(find.textContaining('5,000.00'), findsNothing);

      // The visibility off icon should be shown initially
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('Tapping visibility icon reveals and re-hides total amount', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially hidden
      expect(settings.hideTotalAmount, isTrue);
      expect(find.textContaining('5,000.00'), findsNothing);

      // Tap toggle button to reveal
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(settings.hideTotalAmount, isFalse);
      expect(find.textContaining('5,000.00'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap toggle button again to hide
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(settings.hideTotalAmount, isTrue);
      expect(find.textContaining('••••••'), findsAtLeastNWidgets(1));
      expect(find.textContaining('5,000.00'), findsNothing);
    });
  });
}
