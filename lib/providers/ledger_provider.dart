import 'package:flutter/foundation.dart';
import '../database/budget_database.dart';
import 'package:drift/drift.dart';

class LedgerProvider extends ChangeNotifier {
  final BudgetDatabase _db;
  
  List<Account> accounts = [];
  List<Category> categories = [];
  List<LedgerTransaction> recentTransactions = [];

  // Sticky defaults
  int? lastUsedAccountId;
  int? lastUsedCategoryId;

  LedgerProvider(this._db) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await refreshData();
  }

  Future<void> refreshData() async {
    accounts = await _db.select(_db.accounts).get();
    categories = await _db.select(_db.categories).get();
    recentTransactions = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.dateTime)])
          ..limit(50))
        .get();
    notifyListeners();
  }

  Future<void> addTransaction({
    required double amount,
    required DateTime dateTime,
    required TransactionType type,
    required int fromAccountId,
    int? toAccountId,
    int? categoryId,
    String? notes,
  }) async {
    await _db.transaction(() async {
      // 1. Insert Transaction
      await _db.into(_db.transactions).insert(
        TransactionsCompanion.insert(
          amount: amount,
          dateTime: dateTime,
          transactionType: type,
          fromAccountId: fromAccountId,
          toAccountId: Value(toAccountId),
          categoryId: Value(categoryId),
          notes: Value(notes),
        ),
      );

      // 2. Update Balances
      final fromAccount = accounts.firstWhere((a) => a.id == fromAccountId);
      
      if (type == TransactionType.expense) {
        await _updateAccountBalance(fromAccountId, fromAccount.currentBalance - amount);
      } else if (type == TransactionType.income) {
        await _updateAccountBalance(fromAccountId, fromAccount.currentBalance + amount);
      } else if (type == TransactionType.transfer && toAccountId != null) {
        final toAccount = accounts.firstWhere((a) => a.id == toAccountId);
        await _updateAccountBalance(fromAccountId, fromAccount.currentBalance - amount);
        await _updateAccountBalance(toAccountId, toAccount.currentBalance + amount);
      }
    });

    // Update sticky defaults
    lastUsedAccountId = fromAccountId;
    if (categoryId != null) lastUsedCategoryId = categoryId;

    await refreshData();
  }

  Future<void> _updateAccountBalance(int accountId, double newBalance) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(currentBalance: Value(newBalance)),
    );
  }
}
