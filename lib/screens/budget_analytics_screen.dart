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
  String _dateFilter = 'This Week';

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

    final activeLoansCount = provider.loans.where((l) => !l.isPaid).length;
    final totalBorrowed = provider.loans.fold(0.0, (sum, l) => sum + l.amount);
    final totalRemaining = provider.loans.fold(
      0.0,
      (sum, l) => sum + l.remainingAmount,
    );
    final debtProgress = totalBorrowed > 0
        ? (totalBorrowed - totalRemaining) / totalBorrowed
        : 0.0;

    final activeSubsCount = provider.subscriptions
        .where((s) => s.isActive)
        .length;
    double monthlyCostSum = 0.0;
    for (final sub in provider.subscriptions.where((s) => s.isActive)) {
      if (sub.billingCycle == 'Monthly') {
        monthlyCostSum += sub.cost;
      } else if (sub.billingCycle == 'Yearly') {
        monthlyCostSum += sub.cost / 12.0;
      } else if (sub.billingCycle == 'Weekly') {
        monthlyCostSum += sub.cost * 4.33;
      }
    }

    Subscription? nextSub;
    final activeSubs = provider.subscriptions.where((s) => s.isActive).toList();
    if (activeSubs.isNotEmpty) {
      activeSubs.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
      nextSub = activeSubs.first;
    }

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
                  accounts: provider.accounts,
                  categories: provider.categories,
                  categoryExpenses: categoryExpenses,
                  recentTransactions: filteredTransactions,
                  dateFilter: _dateFilter,
                ),
              ),
            )
          else
            const Text('No categories available yet.'),
          const SizedBox(height: 24),
          Text(
            'Loans & Subscriptions Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.money_off, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Loans Summary',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Active Debts: $activeLoansCount',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total borrowed: $currency${totalBorrowed.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total remaining: $currency${totalRemaining.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Paid Off Progress:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: debtProgress,
                          color: Colors.green,
                          backgroundColor: Colors.grey.shade300,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${(debtProgress * 100).toStringAsFixed(0)}% paid',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.autorenew, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Subscriptions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Active: $activeSubsCount',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Est. Monthly Cost: $currency${monthlyCostSum.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (nextSub != null) ...[
                          const Text(
                            'Next Bill:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${nextSub.name} ($currency${nextSub.cost.toStringAsFixed(2)})',
                          ),
                          Text(
                            'Due: ${nextSub.nextBillingDate.toString().split(' ')[0]}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'No upcoming bills.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
