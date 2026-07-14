import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';
import '../widgets/budget_analytics.dart';

class BudgetAnalyticsTab extends StatefulWidget {
  const BudgetAnalyticsTab({super.key});

  @override
  State<BudgetAnalyticsTab> createState() => _BudgetAnalyticsTabState();
}

class _BudgetAnalyticsTabState extends State<BudgetAnalyticsTab> {
  String _dateFilter = 'All Time';

  bool _isWithinFilter(DateTime date) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'This Week':
        return now.difference(date).inDays < 7;
      case 'This Month':
        return now.difference(date).inDays < 30;
      case 'This Year':
        return now.difference(date).inDays < 365;
      case 'All Time':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;

    final filteredTransactions = provider.recentTransactions
        .where((tx) => _isWithinFilter(tx.date))
        .toList();

    final Map<int, double> categoryExpenses = {};
    for (var tx in filteredTransactions) {
      if (tx.transactionType == TransactionType.expense.index &&
          tx.categoryId != null) {
        categoryExpenses[tx.categoryId!] =
            (categoryExpenses[tx.categoryId!] ?? 0) + tx.amount;
      }
    }

    final expenses = filteredTransactions
        .where((tx) => tx.transactionType == TransactionType.expense.index)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics Filter',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              DropdownButton<String>(
                value: _dateFilter,
                items: ['All Time', 'This Week', 'This Month', 'This Year']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _dateFilter = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.categories.isNotEmpty)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BudgetAnalytics(
                  categories: provider.categories,
                  categoryExpenses: categoryExpenses,
                  recentTransactions: filteredTransactions,
                ),
              ),
            )
          else
            const Text('No categories available yet.'),
          const SizedBox(height: 24),
          Text('All Expenses', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Expense')),
                DataColumn(label: Text('Date')),
              ],
              rows: expenses.map((tx) {
                final catList = provider.categories
                    .where((c) => c.id == tx.categoryId)
                    .toList();
                final catName = catList.isNotEmpty
                    ? catList.first.name
                    : 'Unknown';
                return DataRow(
                  cells: [
                    DataCell(Text(catName)),
                    DataCell(Text('$currency${tx.amount.toStringAsFixed(2)}')),
                    DataCell(Text(tx.date.toString().split(' ')[0])),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
