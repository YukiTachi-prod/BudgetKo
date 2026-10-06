import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'budget_database.g.dart';

enum TransactionType { income, expense, transfer }

@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorHex => integer()();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  RealColumn get minBalance => real().withDefault(const Constant(0.0))();
  TextColumn get backgroundImagePath => text().nullable()();
}

@DataClassName('BudgetCategory')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorHex => integer()();
  BoolColumn get isExpense => boolean()();
  RealColumn get monthlyBudgetLimit => real().nullable()();
  RealColumn get dailyBudgetLimit => real().nullable()();
  RealColumn get weeklyBudgetLimit => real().nullable()();
}

@DataClassName('LedgerTransaction')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionType => integer()();

  // Foreign keys
  IntColumn get fromAccountId => integer()();
  IntColumn get toAccountId => integer().nullable()();
  IntColumn get categoryId => integer().nullable()();
}

@DataClassName('Loan')
class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get creditorName => text().withLength(min: 1, max: 50)();
  RealColumn get amount => real()();
  RealColumn get remainingAmount => real()();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  BoolColumn get isOutgoing => boolean().withDefault(const Constant(false))();
  IntColumn get accountId => integer()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('Subscription')
class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get cost => real()();
  TextColumn get billingCycle => text().withLength(min: 1, max: 20)();
  DateTimeColumn get nextBillingDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get accountId => integer()();
  TextColumn get notes => text().nullable()();
}

@DriftDatabase(
  tables: [Accounts, Categories, Transactions, Loans, Subscriptions],
)
class BudgetDatabase extends _$BudgetDatabase {
  BudgetDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(loans);
        await m.createTable(subscriptions);
      }
      if (from < 3) {
        await m.addColumn(accounts, accounts.minBalance);
      }
      if (from < 4) {
        await m.addColumn(loans, loans.isOutgoing);
      }
      if (from < 5) {
        await m.addColumn(accounts, accounts.backgroundImagePath);
      }
      if (from < 6) {
        await m.addColumn(categories, categories.dailyBudgetLimit);
        await m.addColumn(categories, categories.weeklyBudgetLimit);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budget.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
