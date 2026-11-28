import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasker/database/budget_database.dart';
import 'package:tasker/providers/group_wallet_provider.dart';
import 'package:tasker/providers/ledger_provider.dart';
import 'package:tasker/providers/notification_provider.dart';
import 'package:tasker/providers/settings_provider.dart';
import 'package:tasker/providers/temp_group_pool_provider.dart';
import 'package:tasker/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Delete All Data Tests', () {
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

      await ledger.addAccount('Cash', 1000.0);
      await tempPool.createPool(name: 'Dinner');
      await settings.toggleDarkMode(true);
    });

    tearDown(() async {
      await db.close();
    });

    Widget buildSettingsApp() {
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
        child: const MaterialApp(home: SettingsScreen()),
      );
    }

    testWidgets(
      'requires typing "delete" then "confirm" across two popups before deleting all data',
      (tester) async {
        await tester.pumpWidget(buildSettingsApp());
        await tester.pumpAndSettle();

        final deleteTile = find.text('Delete All Data');
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        await tester.ensureVisible(deleteTile);
        await tester.pumpAndSettle();
        await tester.tap(deleteTile);
        await tester.pumpAndSettle();

        // First popup: Continue button disabled until "delete" is typed
        expect(find.text('Type "delete" below to continue.'), findsOneWidget);
        FilledButton continueBtn = tester.widget(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(continueBtn.onPressed, isNull);

        await tester.enterText(find.byType(TextField), 'nope');
        await tester.pumpAndSettle();
        continueBtn = tester.widget(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(continueBtn.onPressed, isNull);

        await tester.enterText(find.byType(TextField), 'delete');
        await tester.pumpAndSettle();
        continueBtn = tester.widget(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(continueBtn.onPressed, isNotNull);

        // Proceed to second popup
        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        await tester.pumpAndSettle();

        // Data still intact before final confirmation
        expect(ledger.accounts, hasLength(1));
        expect(tempPool.hasActivePool, isTrue);

        // Second popup: Delete Everything disabled until "confirm" is typed
        expect(find.text('Final Confirmation'), findsOneWidget);
        FilledButton deleteEverythingBtn = tester.widget(
          find.widgetWithText(FilledButton, 'Delete Everything'),
        );
        expect(deleteEverythingBtn.onPressed, isNull);

        await tester.enterText(find.byType(TextField), 'confirm');
        await tester.pumpAndSettle();
        deleteEverythingBtn = tester.widget(
          find.widgetWithText(FilledButton, 'Delete Everything'),
        );
        expect(deleteEverythingBtn.onPressed, isNotNull);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Delete Everything'),
        );
        await tester.pumpAndSettle();

        // All data cleared
        expect(ledger.accounts, isEmpty);
        expect(ledger.allTransactions, isEmpty);
        expect(tempPool.hasActivePool, isFalse);
        expect(settings.isDarkMode, isFalse);
        expect(find.text('All data has been deleted.'), findsOneWidget);
      },
    );
  });
}
