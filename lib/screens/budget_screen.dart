import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';
import '../widgets/budget_analytics.dart';
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

    // Compute category expenses
    final Map<int, double> categoryExpenses = {};
    for (var tx in provider.recentTransactions) {
      if (tx.transactionType == TransactionType.expense.index &&
          tx.categoryId != null) {
        categoryExpenses[tx.categoryId!] =
            (categoryExpenses[tx.categoryId!] ?? 0) + tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Calculator'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analytics Section
            if (provider.categories.isNotEmpty)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BudgetAnalytics(
                    categories: provider.categories,
                    categoryExpenses: categoryExpenses,
                    recentTransactions: provider.recentTransactions,
                  ),
                ),
              ),
            if (provider.categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No categories available yet. Please add a transaction to start.',
                ),
              ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Accounts', style: theme.textTheme.titleLarge),
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
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
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
                      cat.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: cat.isExpense ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    onPressed: () => _showCategoryDialog(context, cat),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),
            Text('Recent Transactions', style: theme.textTheme.titleLarge),
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
                          : (isInc ? Icons.arrow_downward : Icons.arrow_upward),
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
          ],
        ),
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
    );
  }
}
