import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/budget_database.dart';

class DataExportService {
  final BudgetDatabase _db;

  DataExportService(this._db);

  Future<void> exportLedgerToCsv() async {
    final transactions = await _db.select(_db.transactions).get();

    List<List<dynamic>> rows = [];
    // Header
    rows.add([
      "ID",
      "Amount",
      "Date",
      "Type",
      "Notes",
      "From Account",
      "To Account",
      "Category",
    ]);

    // Rows
    for (var tx in transactions) {
      rows.add([
        tx.id,
        tx.amount,
        tx.date.toIso8601String(),
        TransactionType.values[tx.transactionType].name,
        tx.notes ?? '',
        tx.fromAccountId,
        tx.toAccountId ?? '',
        tx.categoryId ?? '',
      ]);
    }

    String csvData = csv.encode(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/ledger_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path)], text: 'My Budget Ledger Backup');
  }
}
