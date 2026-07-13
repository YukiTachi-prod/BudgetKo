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
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get iconCodePoint => integer()();
  IntColumn get colorHex => integer()();
  BoolColumn get isExpense => boolean()();
  RealColumn get monthlyBudgetLimit => real().nullable()();
}

@DataClassName('LedgerTransaction')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  DateTimeColumn get dateTime => dateTime()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionType => intEnum<TransactionType>()();
  
  // Foreign keys
  IntColumn get fromAccountId => integer().references(Accounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
}

@DriftDatabase(tables: [Accounts, Categories, Transactions])
class BudgetDatabase extends _$BudgetDatabase {
  BudgetDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'budget.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
