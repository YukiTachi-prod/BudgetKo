import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';
import 'budget_analytics_screen.dart';
import '../services/export_service.dart';
import 'transaction_entry_screen.dart';
import 'loans_and_subscriptions_tab.dart';
import 'expenses_tab.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  void _showAccountDialog(BuildContext context, [Account? accountToEdit]) {
    final nameCtrl = TextEditingController(text: accountToEdit?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: accountToEdit?.currentBalance.toString() ?? '',
    );
    int? selectedColorHex = accountToEdit?.colorHex;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentColorHex = selectedColorHex ?? Colors.blue.toARGB32();

            return AlertDialog(
              title: Text(
                accountToEdit == null ? 'Add Account' : 'Edit Account',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Account Name (e.g. GCash)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Initial Balance',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Account Color:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (colorCtx) {
                                Color tempColor = Color(currentColorHex);
                                return AlertDialog(
                                  title: const Text('Pick Account Color'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: tempColor,
                                      onColorChanged: (c) => tempColor = c,
                                      pickerAreaHeightPercent: 0.8,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(colorCtx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedColorHex = tempColor
                                              .toARGB32();
                                        });
                                        Navigator.pop(colorCtx);
                                      },
                                      child: const Text('Select'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(currentColorHex),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (accountToEdit != null)
                  TextButton(
                    onPressed: () {
                      context.read<LedgerProvider>().deleteAccount(
                        accountToEdit.id,
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
                    final balance = double.tryParse(balanceCtrl.text) ?? 0.0;
                    if (name.isNotEmpty) {
                      if (accountToEdit == null) {
                        context.read<LedgerProvider>().addAccount(
                          name,
                          balance,
                          colorHex: currentColorHex,
                        );
                      } else {
                        context.read<LedgerProvider>().updateAccount(
                          accountToEdit.id,
                          name,
                          balance,
                          colorHex: currentColorHex,
                        );
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(accountToEdit == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
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
    int? selectedColorHex = categoryToEdit?.colorHex;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentColorHex =
                selectedColorHex ??
                (isExpense
                    ? Colors.purple.toARGB32()
                    : Colors.green.toARGB32());

            return AlertDialog(
              title: Text(
                categoryToEdit == null ? 'Add Category' : 'Edit Category',
              ),
              content: SingleChildScrollView(
                child: Column(
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
                          onSelected: (v) {
                            setState(() {
                              isExpense = true;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: !isExpense,
                          onSelected: (v) {
                            setState(() {
                              isExpense = false;
                            });
                          },
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Category Color:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (colorCtx) {
                                Color tempColor = Color(currentColorHex);
                                return AlertDialog(
                                  title: const Text('Pick Category Color'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: tempColor,
                                      onColorChanged: (c) => tempColor = c,
                                      pickerAreaHeightPercent: 0.8,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(colorCtx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedColorHex = tempColor
                                              .toARGB32();
                                        });
                                        Navigator.pop(colorCtx);
                                      },
                                      child: const Text('Select'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Color(currentColorHex),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                          colorHex: currentColorHex,
                        );
                      } else {
                        context.read<LedgerProvider>().updateCategory(
                          categoryToEdit.id,
                          name,
                          isExpense,
                          limit,
                          colorHex: currentColorHex,
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wallet'),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.description_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Tasks',
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Wallet'),
              Tab(text: 'Expenses'),
              Tab(text: 'Loans & Subs'),
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
                        final accColor = Color(acc.colorHex);
                        return ActionChip(
                          label: Text(
                            '${acc.name}: $currency${acc.currentBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: accColor,
                            ),
                          ),
                          backgroundColor: accColor.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: accColor.withValues(alpha: 0.3),
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
                        final catColor = Color(cat.colorHex);
                        return ActionChip(
                          label: Text(
                            '${cat.name} ${cat.monthlyBudgetLimit != null ? '($currency${cat.monthlyBudgetLimit!.toStringAsFixed(0)})' : ''}',
                            style: TextStyle(
                              color: catColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          avatar: Icon(
                            cat.isExpense
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: catColor,
                            size: 16,
                          ),
                          backgroundColor: catColor.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: catColor.withValues(alpha: 0.3),
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

                      BudgetCategory? cat;
                      if (tx.categoryId != null) {
                        for (final c in provider.categories) {
                          if (c.id == tx.categoryId) {
                            cat = c;
                            break;
                          }
                        }
                      }
                      final catColor = cat != null ? Color(cat.colorHex) : null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionEntryScreen(
                                  transactionToEdit: tx,
                                ),
                              ),
                            );
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: catColor?.withValues(alpha: 0.08),
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tx.notes ??
                                      (isTransfer
                                          ? 'Transfer'
                                          : (isInc ? 'Income' : 'Expense')),
                                ),
                              ),
                              if (cat != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: catColor!.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: catColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: catColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
            const ExpensesTab(),
            const LoansAndSubscriptionsTab(),
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
