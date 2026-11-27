import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasker/database/budget_database.dart';
import 'package:tasker/providers/ledger_provider.dart';
import 'package:tasker/providers/settings_provider.dart';
import 'package:tasker/screens/transaction_entry_screen.dart';

void main() {
  testWidgets(
    'income default and switching types keep category dropdown valid',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = BudgetDatabase(NativeDatabase.memory());
      final ledger = LedgerProvider(db);
      final settings = SettingsProvider();
      await ledger.preload();
      await settings.preload();
      ledger.lastUsedCategoryId = ledger.categories
          .firstWhere((c) => !c.isExpense)
          .id;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: ledger),
            ChangeNotifierProvider.value(value: settings),
          ],
          child: const MaterialApp(home: TransactionEntryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ledger.dispose();
      settings.dispose();
      await db.close();
    },
  );
}
