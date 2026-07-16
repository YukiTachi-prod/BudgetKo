import 'dart:math';
import 'package:flutter/material.dart';
import '../database/budget_database.dart';
import 'package:drift/drift.dart';

class LedgerProvider extends ChangeNotifier {
  final BudgetDatabase _db;

  List<Account> accounts = [];
  List<BudgetCategory> categories = [];
  List<LedgerTransaction> recentTransactions = [];
  List<Loan> loans = [];
  List<Subscription> subscriptions = [];

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
    loans = await _db.select(_db.loans).get();
    subscriptions = await _db.select(_db.subscriptions).get();
    notifyListeners();
  }

  Future<void> addAccount(
    String name,
    double initialBalance, {
    int? colorHex,
    double minBalance = 0.0,
    String? backgroundImagePath,
  }) async {
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name,
            iconCodePoint: Icons.account_balance_wallet.codePoint,
            colorHex: colorHex ?? Colors.blue.toARGB32(),
            initialBalance: Value(initialBalance),
            currentBalance: Value(initialBalance),
            minBalance: Value(minBalance),
            backgroundImagePath: Value(backgroundImagePath),
          ),
        );
    await refreshData();
  }

  Future<void> addCategory(
    String name,
    bool isExpense,
    double? monthlyLimit, {
    int? colorHex,
  }) async {
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name,
            iconCodePoint: isExpense
                ? Icons.shopping_bag.codePoint
                : Icons.attach_money.codePoint,
            colorHex:
                colorHex ??
                (isExpense
                    ? Colors.purple.toARGB32()
                    : Colors.green.toARGB32()),
            isExpense: isExpense,
            monthlyBudgetLimit: Value(monthlyLimit),
          ),
        );
    await refreshData();
  }

  Future<void> updateAccount(
    int accountId,
    String name,
    double balance, {
    int? colorHex,
    double? minBalance,
    String? backgroundImagePath,
    bool clearBackgroundImage = false,
  }) async {
    await (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(
        name: Value(name),
        currentBalance: Value(balance),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
        minBalance: minBalance != null
            ? Value(minBalance)
            : const Value.absent(),
        backgroundImagePath: clearBackgroundImage
            ? const Value(null)
            : (backgroundImagePath != null
                  ? Value(backgroundImagePath)
                  : const Value.absent()),
      ),
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
    double? monthlyLimit, {
    int? colorHex,
  }) async {
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
          colorHex ??
              (isExpense ? Colors.purple.toARGB32() : Colors.green.toARGB32()),
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

  // ── Loans Management ──────────────────────────────────────────
  Future<void> addLoan({
    required String creditorName,
    required double amount,
    required double remainingAmount,
    required DateTime dueDate,
    required int accountId,
    required bool isOutgoing,
    String? notes,
  }) async {
    await _db
        .into(_db.loans)
        .insert(
          LoansCompanion.insert(
            creditorName: creditorName,
            amount: amount,
            remainingAmount: remainingAmount,
            dueDate: dueDate,
            accountId: accountId,
            notes: Value(notes),
            isPaid: const Value(false),
            isOutgoing: Value(isOutgoing),
          ),
        );
    await refreshData();
  }

  Future<void> updateLoan({
    required int loanId,
    required String creditorName,
    required double amount,
    required double remainingAmount,
    required DateTime dueDate,
    required bool isPaid,
    required int accountId,
    required bool isOutgoing,
    String? notes,
  }) async {
    await _db.transaction(() async {
      final oldLoan = await (_db.select(
        _db.loans,
      )..where((l) => l.id.equals(loanId))).getSingle();

      if (!oldLoan.isPaid && isPaid) {
        final acc = accounts.firstWhere((a) => a.id == accountId);
        if (isOutgoing) {
          await _updateAccountBalance(
            accountId,
            acc.currentBalance + remainingAmount,
          );
        } else {
          await _updateAccountBalance(
            accountId,
            acc.currentBalance - remainingAmount,
          );
        }
      } else if (oldLoan.isPaid && !isPaid) {
        final acc = accounts.firstWhere((a) => a.id == accountId);
        if (isOutgoing) {
          await _updateAccountBalance(
            accountId,
            acc.currentBalance - remainingAmount,
          );
        } else {
          await _updateAccountBalance(
            accountId,
            acc.currentBalance + remainingAmount,
          );
        }
      }
      await (_db.update(_db.loans)..where((l) => l.id.equals(loanId))).write(
        LoansCompanion(
          creditorName: Value(creditorName),
          amount: Value(amount),
          remainingAmount: Value(remainingAmount),
          dueDate: Value(dueDate),
          isPaid: Value(isPaid),
          accountId: Value(accountId),
          notes: Value(notes),
          isOutgoing: Value(isOutgoing),
        ),
      );
    });
    await refreshData();
  }

  Future<void> deleteLoan(int loanId) async {
    await (_db.delete(_db.loans)..where((l) => l.id.equals(loanId))).go();
    await refreshData();
  }

  // ── Subscriptions Management ──────────────────────────────────
  Future<void> addSubscription({
    required String name,
    required double cost,
    required String billingCycle,
    required DateTime nextBillingDate,
    required int accountId,
    String? notes,
  }) async {
    await _db
        .into(_db.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            name: name,
            cost: cost,
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate,
            accountId: accountId,
            notes: Value(notes),
            isActive: const Value(true),
          ),
        );
    await refreshData();
  }

  Future<void> updateSubscription({
    required int subscriptionId,
    required String name,
    required double cost,
    required String billingCycle,
    required DateTime nextBillingDate,
    required bool isActive,
    required int accountId,
    String? notes,
  }) async {
    await (_db.update(
      _db.subscriptions,
    )..where((s) => s.id.equals(subscriptionId))).write(
      SubscriptionsCompanion(
        name: Value(name),
        cost: Value(cost),
        billingCycle: Value(billingCycle),
        nextBillingDate: Value(nextBillingDate),
        isActive: Value(isActive),
        accountId: Value(accountId),
        notes: Value(notes),
      ),
    );
    await refreshData();
  }

  Future<void> deleteSubscription(int subscriptionId) async {
    await (_db.delete(
      _db.subscriptions,
    )..where((s) => s.id.equals(subscriptionId))).go();
    await refreshData();
  }

  // ── Mock Analytics ────────────────────────────────────────────
  Future<void> insertMockAnalytics() async {
    if (accounts.isEmpty) return;
    final fromAccountId = accounts.first.id;
    final categoryId = categories.isNotEmpty
        ? categories
              .firstWhere((c) => c.isExpense, orElse: () => categories.first)
              .id
        : null;

    final now = DateTime.now();
    double totalAmount = 0;

    await _db.transaction(() async {
      final random = Random();
      for (int i = 0; i < 30; i++) {
        final amount = 250.0 + random.nextDouble() * 750.0;
        totalAmount += amount;
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                amount: amount,
                date: now.subtract(Duration(days: i)),
                transactionType: TransactionType.expense.index,
                fromAccountId: fromAccountId,
                categoryId: Value(categoryId),
                notes: const Value('Mock Analytics'),
              ),
            );
      }
      final acc = await (_db.select(
        _db.accounts,
      )..where((a) => a.id.equals(fromAccountId))).getSingle();
      await _updateAccountBalance(
        fromAccountId,
        acc.currentBalance - totalAmount,
      );
    });

    await refreshData();
  }

  Future<void> removeMockAnalytics() async {
    final mockTxs = await (_db.select(
      _db.transactions,
    )..where((t) => t.notes.equals('Mock Analytics'))).get();
    if (mockTxs.isEmpty) return;

    await _db.transaction(() async {
      final Map<int, double> refundMap = {};
      for (var tx in mockTxs) {
        if (tx.transactionType == TransactionType.expense.index) {
          refundMap[tx.fromAccountId] =
              (refundMap[tx.fromAccountId] ?? 0) + tx.amount;
        }
      }

      for (var entry in refundMap.entries) {
        final acc = await (_db.select(
          _db.accounts,
        )..where((a) => a.id.equals(entry.key))).getSingle();
        await _updateAccountBalance(
          entry.key,
          acc.currentBalance + entry.value,
        );
      }

      await (_db.delete(
        _db.transactions,
      )..where((t) => t.notes.equals('Mock Analytics'))).go();
    });

    await refreshData();
  }
}
