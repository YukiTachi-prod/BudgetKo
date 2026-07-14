import 'package:flutter/material.dart';
import '../database/budget_database.dart';
import 'package:drift/drift.dart';

class LedgerProvider extends ChangeNotifier {
  final BudgetDatabase _db;

  List<Account> accounts = [];
  List<BudgetCategory> categories = [];
  List<LedgerTransaction> recentTransactions = [];

  // Sticky defaults
  int? lastUsedAccountId;
  int? lastUsedCategoryId;

  LedgerProvider(this._db) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await refreshData();
    if (categories.isEmpty) {
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Food',
              iconCodePoint: Icons.fastfood.codePoint,
              colorHex: Colors.orange.toARGB32(),
              isExpense: true,
            ),
          );
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Transport',
              iconCodePoint: Icons.directions_car.codePoint,
              colorHex: Colors.blue.toARGB32(),
              isExpense: true,
            ),
          );
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Salary',
              iconCodePoint: Icons.attach_money.codePoint,
              colorHex: Colors.green.toARGB32(),
              isExpense: false,
            ),
          );
      await refreshData();
    }
  }

  Future<void> refreshData() async {
    accounts = await _db.select(_db.accounts).get();
    categories = await _db.select(_db.categories).get();
    recentTransactions =
        await (_db.select(_db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(50))
            .get();
    notifyListeners();
  }

  Future<void> addAccount(String name, double initialBalance) async {
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name,
            iconCodePoint: Icons.account_balance_wallet.codePoint,
            colorHex: Colors.blue.toARGB32(),
            initialBalance: Value(initialBalance),
            currentBalance: Value(initialBalance),
          ),
        );
    await refreshData();
  }

  Future<void> addCategory(
    String name,
    bool isExpense,
    double? monthlyLimit,
  ) async {
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name,
            iconCodePoint: isExpense
                ? Icons.shopping_bag.codePoint
                : Icons.attach_money.codePoint,
            colorHex: isExpense
                ? Colors.purple.toARGB32()
                : Colors.green.toARGB32(),
            isExpense: isExpense,
            monthlyBudgetLimit: Value(monthlyLimit),
          ),
        );
    await refreshData();
  }

  Future<void> updateAccount(int accountId, String name, double balance) async {
    await (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(name: Value(name), currentBalance: Value(balance)),
    );
    await refreshData();
  }

  Future<void> deleteAccount(int accountId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.transactions)..where(
            (t) =>
                t.fromAccountId.equals(accountId) |
                t.toAccountId.equals(accountId),
          ))
          .go();
      await (_db.delete(
        _db.accounts,
      )..where((a) => a.id.equals(accountId))).go();
    });
    if (lastUsedAccountId == accountId) lastUsedAccountId = null;
    await refreshData();
  }

  Future<void> updateCategory(
    int categoryId,
    String name,
    bool isExpense,
    double? monthlyLimit,
  ) async {
    await (_db.update(
      _db.categories,
    )..where((c) => c.id.equals(categoryId))).write(
      CategoriesCompanion(
        name: Value(name),
        isExpense: Value(isExpense),
        monthlyBudgetLimit: Value(monthlyLimit),
        iconCodePoint: Value(
          isExpense
              ? Icons.shopping_bag.codePoint
              : Icons.attach_money.codePoint,
        ),
        colorHex: Value(
          isExpense ? Colors.purple.toARGB32() : Colors.green.toARGB32(),
        ),
      ),
    );
    await refreshData();
  }

  Future<void> deleteCategory(int categoryId) async {
    await _db.transaction(() async {
      await (_db.update(_db.transactions)
            ..where((t) => t.categoryId.equals(categoryId)))
          .write(const TransactionsCompanion(categoryId: Value(null)));
      await (_db.delete(
        _db.categories,
      )..where((c) => c.id.equals(categoryId))).go();
    });
    if (lastUsedCategoryId == categoryId) lastUsedCategoryId = null;
    await refreshData();
  }

  Future<void> addTransaction({
    required double amount,
    required DateTime date,
    required TransactionType type,
    required int fromAccountId,
    int? toAccountId,
    int? categoryId,
    String? notes,
  }) async {
    await _db.transaction(() async {
      // 1. Insert Transaction
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              amount: amount,
              date: date,
              transactionType: type.index,
              fromAccountId: fromAccountId,
              toAccountId: Value(toAccountId),
              categoryId: Value(categoryId),
              notes: Value(notes),
            ),
          );

      // 2. Update Balances
      final fromAccount = accounts.firstWhere((a) => a.id == fromAccountId);

      if (type == TransactionType.expense) {
        await _updateAccountBalance(
          fromAccountId,
          fromAccount.currentBalance - amount,
        );
      } else if (type == TransactionType.income) {
        await _updateAccountBalance(
          fromAccountId,
          fromAccount.currentBalance + amount,
        );
      } else if (type == TransactionType.transfer && toAccountId != null) {
        final toAccount = accounts.firstWhere((a) => a.id == toAccountId);
        await _updateAccountBalance(
          fromAccountId,
          fromAccount.currentBalance - amount,
        );
        await _updateAccountBalance(
          toAccountId,
          toAccount.currentBalance + amount,
        );
      }
    });

    // Update sticky defaults
    lastUsedAccountId = fromAccountId;
    if (categoryId != null) lastUsedCategoryId = categoryId;

    await refreshData();
  }

  Future<void> updateTransaction({
    required int transactionId,
    required double amount,
    required DateTime date,
    required TransactionType type,
    required int fromAccountId,
    int? toAccountId,
    int? categoryId,
    String? notes,
  }) async {
    await _db.transaction(() async {
      final oldTx = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).getSingle();

      // Reverse old tx
      if (oldTx.transactionType == TransactionType.expense.index) {
        final acc = accounts.firstWhere((a) => a.id == oldTx.fromAccountId);
        await _updateAccountBalance(acc.id, acc.currentBalance + oldTx.amount);
      } else if (oldTx.transactionType == TransactionType.income.index) {
        final acc = accounts.firstWhere((a) => a.id == oldTx.fromAccountId);
        await _updateAccountBalance(acc.id, acc.currentBalance - oldTx.amount);
      } else if (oldTx.transactionType == TransactionType.transfer.index &&
          oldTx.toAccountId != null) {
        final fromAcc = accounts.firstWhere((a) => a.id == oldTx.fromAccountId);
        final toAcc = accounts.firstWhere((a) => a.id == oldTx.toAccountId!);
        await _updateAccountBalance(
          fromAcc.id,
          fromAcc.currentBalance + oldTx.amount,
        );
        await _updateAccountBalance(
          toAcc.id,
          toAcc.currentBalance - oldTx.amount,
        );
      }

      accounts = await _db
          .select(_db.accounts)
          .get(); // refresh accounts inside tx

      // Apply new tx
      if (type == TransactionType.expense) {
        final acc = accounts.firstWhere((a) => a.id == fromAccountId);
        await _updateAccountBalance(acc.id, acc.currentBalance - amount);
      } else if (type == TransactionType.income) {
        final acc = accounts.firstWhere((a) => a.id == fromAccountId);
        await _updateAccountBalance(acc.id, acc.currentBalance + amount);
      } else if (type == TransactionType.transfer && toAccountId != null) {
        final fromAcc = accounts.firstWhere((a) => a.id == fromAccountId);
        final toAcc = accounts.firstWhere((a) => a.id == toAccountId);
        await _updateAccountBalance(
          fromAcc.id,
          fromAcc.currentBalance - amount,
        );
        await _updateAccountBalance(toAcc.id, toAcc.currentBalance + amount);
      }

      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).write(
        TransactionsCompanion(
          amount: Value(amount),
          date: Value(date),
          transactionType: Value(type.index),
          fromAccountId: Value(fromAccountId),
          toAccountId: Value(toAccountId),
          categoryId: Value(categoryId),
          notes: Value(notes),
        ),
      );
    });

    await refreshData();
  }

  Future<void> deleteTransaction(int transactionId) async {
    await _db.transaction(() async {
      final oldTx = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).getSingle();

      if (oldTx.transactionType == TransactionType.expense.index) {
        final acc = accounts.firstWhere((a) => a.id == oldTx.fromAccountId);
        await _updateAccountBalance(acc.id, acc.currentBalance + oldTx.amount);
      } else if (oldTx.transactionType == TransactionType.income.index) {
        final acc = accounts.firstWhere((a) => a.id == oldTx.fromAccountId);
        await _updateAccountBalance(acc.id, acc.currentBalance - oldTx.amount);
      } else if (oldTx.transactionType == TransactionType.transfer.index &&
          oldTx.toAccountId != null) {
        final fromAcc = accounts.firstWhere((a) => a.id == oldTx.fromAccountId);
        final toAcc = accounts.firstWhere((a) => a.id == oldTx.toAccountId!);
        await _updateAccountBalance(
          fromAcc.id,
          fromAcc.currentBalance + oldTx.amount,
        );
        await _updateAccountBalance(
          toAcc.id,
          toAcc.currentBalance - oldTx.amount,
        );
      }
      await (_db.delete(
        _db.transactions,
      )..where((t) => t.id.equals(transactionId))).go();
    });
    await refreshData();
  }

  Future<void> _updateAccountBalance(int accountId, double newBalance) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId)))
        .write(AccountsCompanion(currentBalance: Value(newBalance)));
  }
}
