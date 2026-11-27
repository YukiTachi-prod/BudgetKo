import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasker/database/budget_database.dart';
import 'package:tasker/providers/ledger_provider.dart';

void main() {
  late BudgetDatabase db;
  late LedgerProvider ledger;
  setUp(() async {
    db = BudgetDatabase(NativeDatabase.memory());
    ledger = LedgerProvider(db);
    await ledger.preload();
    await ledger.addAccount('Cash', 100);
    await ledger.addAccount('Bank', 100);
  });
  tearDown(() async {
    ledger.dispose();
    await db.close();
  });

  Future<void> expense(double amount) => ledger.addTransaction(
    amount: amount,
    date: DateTime.now(),
    type: TransactionType.expense,
    fromAccountId: ledger.accounts.first.id,
  );

  test('overlapping saves use persisted balances', () async {
    await Future.wait([expense(10), expense(20)]);
    expect(ledger.accounts.first.currentBalance, 70);
    expect(ledger.allTransactions, hasLength(2));
  });

  test('invalid amounts and overdrafts roll back', () async {
    await expectLater(expense(double.nan), throwsArgumentError);
    await expectLater(expense(double.infinity), throwsArgumentError);
    await expectLater(expense(101), throwsStateError);
    await ledger.refreshData();
    expect(ledger.accounts.first.currentBalance, 100);
    expect(ledger.allTransactions, isEmpty);
  });

  test('self transfers do not create money', () async {
    final id = ledger.accounts.first.id;
    await expectLater(
      ledger.addTransaction(
        amount: 10,
        date: DateTime.now(),
        type: TransactionType.transfer,
        fromAccountId: id,
        toAccountId: id,
      ),
      throwsArgumentError,
    );
    expect(ledger.accounts.first.currentBalance, 100);
  });

  test('failed edit leaves both database and cache unchanged', () async {
    await expense(20);
    final tx = ledger.allTransactions.single;
    await expectLater(
      ledger.updateTransaction(
        transactionId: tx.id,
        amount: 120,
        date: tx.date,
        type: TransactionType.expense,
        fromAccountId: tx.fromAccountId,
      ),
      throwsStateError,
    );
    expect(ledger.accounts.first.currentBalance, 80);
    await ledger.refreshData();
    expect(ledger.accounts.first.currentBalance, 80);
    expect(ledger.allTransactions.single.amount, 20);
  });

  test(
    'deleting account cleans dependent records and transfer effects',
    () async {
      final source = ledger.accounts.first.id;
      final destination = ledger.accounts.last.id;
      await ledger.addTransaction(
        amount: 20,
        date: DateTime.now(),
        type: TransactionType.transfer,
        fromAccountId: source,
        toAccountId: destination,
      );
      await ledger.addLoan(
        creditorName: 'Friend',
        amount: 10,
        remainingAmount: 10,
        dueDate: DateTime.now(),
        accountId: source,
        isOutgoing: false,
      );
      await ledger.addSubscription(
        name: 'Bill',
        cost: 5,
        billingCycle: 'Monthly',
        nextBillingDate: DateTime.now(),
        accountId: source,
      );
      await ledger.deleteAccount(source);
      expect(ledger.accounts.single.currentBalance, 100);
      expect(ledger.allTransactions, isEmpty);
      expect(ledger.loans, isEmpty);
      expect(ledger.subscriptions, isEmpty);
    },
  );
}
