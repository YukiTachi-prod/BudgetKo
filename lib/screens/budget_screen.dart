import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';
import 'budget_analytics_screen.dart';
import '../services/export_service.dart';
import 'transaction_entry_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  void _showAccountDialog(BuildContext context, [Account? accountToEdit]) {
    final nameCtrl = TextEditingController(text: accountToEdit?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: accountToEdit?.currentBalance.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accountToEdit == null ? 'Add Account' : 'Edit Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Name (e.g. GCash)',
              ),
            ),
            TextField(
              controller: balanceCtrl,
              decoration: const InputDecoration(labelText: 'Initial Balance'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          if (accountToEdit != null)
            TextButton(
              onPressed: () {
                context.read<LedgerProvider>().deleteAccount(accountToEdit.id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final balance = double.tryParse(balanceCtrl.text) ?? 0.0;
              if (name.isNotEmpty) {
                if (accountToEdit == null) {
                  context.read<LedgerProvider>().addAccount(name, balance);
                } else {
                  context.read<LedgerProvider>().updateAccount(
                    accountToEdit.id,
                    name,
                    balance,
                  );
                }
                Navigator.pop(ctx);
              }
            },
            child: Text(accountToEdit == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context, [
    BudgetCategory? categoryToEdit,
  ]) {
    final nameCtrl = TextEditingController(text: categoryToEdit?.name ?? '');
    final limitCtrl = TextEditingController(
      text: categoryToEdit?.monthlyBudgetLimit?.toString() ?? '',
    );
    bool isExpense = categoryToEdit?.isExpense ?? true;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                categoryToEdit == null ? 'Add Category' : 'Edit Category',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category Name (e.g. Food)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Type: '),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Expense'),
                        selected: isExpense,
                        onSelected: (v) => setState(() => isExpense = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Income'),
                        selected: !isExpense,
                        onSelected: (v) => setState(() => isExpense = false),
                      ),
                    ],
                  ),
                  if (isExpense) const SizedBox(height: 12),
                  if (isExpense)
                    TextField(
                      controller: limitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Budget Limit (Optional)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                ],
              ),
              actions: [
                if (categoryToEdit != null)
                  TextButton(
                    onPressed: () {
                      context.read<LedgerProvider>().deleteCategory(
                        categoryToEdit.id,
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final limit = double.tryParse(limitCtrl.text);
                    if (name.isNotEmpty) {
                      if (categoryToEdit == null) {
                        context.read<LedgerProvider>().addCategory(
                          name,
                          isExpense,
                          limit,
                        );
                      } else {
                        context.read<LedgerProvider>().updateCategory(
                          categoryToEdit.id,
                          name,
                          isExpense,
                          limit,
                        );
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(categoryToEdit == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final settings = context.watch<SettingsProvider>();
    final currency = settings.currency;
    final theme = Theme.of(context);

    final totalMoney = provider.accounts.fold(
      0.0,
      (sum, acc) => sum + acc.currentBalance,
    );
    final totalExpenses = provider.recentTransactions
        .where((tx) => tx.transactionType == TransactionType.expense.index)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Budget Calculator'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Wallet'),
              Tab(text: 'Analytics'),
            ],
          ),
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currency,
                icon: const Icon(Icons.arrow_drop_down),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    settings.setCurrency(newValue);
                  }
                },
                items: <String>['\$', '€', '£', '¥', '₱', '₹', '₽']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () async {
                final db = context.read<BudgetDatabase>();
                await DataExportService(db).exportLedgerToCsv();
              },
              tooltip: 'Export to CSV',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Accounts', style: theme.textTheme.titleLarge),
                          const SizedBox(width: 8),
                          Text(
                            '($currency${totalMoney.toStringAsFixed(2)})',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showAccountDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.accounts.isEmpty)
                    const Text('No accounts yet. Add one to start tracking!')
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: provider.accounts.map((acc) {
                        return ActionChip(
                          label: Text(
                            '${acc.name}: $currency${acc.currentBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: acc.currentBalance >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          onPressed: () => _showAccountDialog(context, acc),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categories', style: theme.textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showCategoryDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.categories.isEmpty)
                    const Text('No categories yet. Add one to start tracking!')
                  else
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: provider.categories.map((cat) {
                        return ActionChip(
                          label: Text(
                            '${cat.name} ${cat.monthlyBudgetLimit != null ? '($currency${cat.monthlyBudgetLimit!.toStringAsFixed(0)})' : ''}',
                          ),
                          avatar: Icon(
                            cat.isExpense
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: cat.isExpense ? Colors.red : Colors.green,
                            size: 16,
                          ),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                          onPressed: () => _showCategoryDialog(context, cat),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),
                  Text(
                    'Recent Transactions',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),

                  // Transactions List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.recentTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = provider.recentTransactions[index];
                      final isInc =
                          tx.transactionType == TransactionType.income.index;
                      final isTransfer =
                          tx.transactionType == TransactionType.transfer.index;

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransactionEntryScreen(transactionToEdit: tx),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: isInc
                              ? Colors.green.withValues(alpha: 0.2)
                              : (isTransfer
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2)),
                          child: Icon(
                            isTransfer
                                ? Icons.swap_horiz
                                : (isInc
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward),
                            color: isInc
                                ? Colors.green
                                : (isTransfer ? Colors.blue : Colors.red),
                          ),
                        ),
                        title: Text(
                          tx.notes ??
                              (isTransfer
                                  ? 'Transfer'
                                  : (isInc ? 'Income' : 'Expense')),
                        ),
                        subtitle: Text(tx.date.toString().split('.')[0]),
                        trailing: Text(
                          '${isInc ? '+' : (isTransfer ? '' : '-')}$currency${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isInc
                                ? Colors.green
                                : (isTransfer ? Colors.blue : Colors.red),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Total Expenses: $currency${totalExpenses.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const BudgetAnalyticsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionEntryScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Transaction'),
        ),
      ),
    );
  }
}
