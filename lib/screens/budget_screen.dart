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
import '../utils/math_util.dart';
import 'settings_screen.dart';
import 'main_tab.dart';
import 'group_wallet_screen.dart';
import 'temp_group_pool_screen.dart';
import '../widgets/notification_bell.dart';
import '../widgets/notification_drawer.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _showAllCategories = false;

  void _showAccountDialog(BuildContext context, [Account? accountToEdit]) {
    final nameCtrl = TextEditingController(text: accountToEdit?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: accountToEdit?.currentBalance.toString() ?? '',
    );
    final minBalanceCtrl = TextEditingController(
      text: accountToEdit?.minBalance.toString() ?? '0.0',
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: minBalanceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Balance (Warning trigger)',
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
                    final balance = parseAmount(balanceCtrl.text);
                    final minBalance = parseAmount(minBalanceCtrl.text);
                    if (name.isNotEmpty) {
                      if (accountToEdit == null) {
                        context.read<LedgerProvider>().addAccount(
                          name,
                          balance,
                          colorHex: currentColorHex,
                          minBalance: minBalance,
                        );
                      } else {
                        context.read<LedgerProvider>().updateAccount(
                          accountToEdit.id,
                          name,
                          balance,
                          colorHex: currentColorHex,
                          minBalance: minBalance,
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

    String selectedPeriod = 'Monthly';
    String limitText = '';
    if (categoryToEdit != null) {
      if (categoryToEdit.dailyBudgetLimit != null) {
        selectedPeriod = 'Daily';
        limitText = categoryToEdit.dailyBudgetLimit.toString();
      } else if (categoryToEdit.weeklyBudgetLimit != null) {
        selectedPeriod = 'Weekly';
        limitText = categoryToEdit.weeklyBudgetLimit.toString();
      } else if (categoryToEdit.monthlyBudgetLimit != null) {
        selectedPeriod = 'Monthly';
        limitText = categoryToEdit.monthlyBudgetLimit.toString();
      }
    }

    final limitCtrl = TextEditingController(text: limitText);
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
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButton<String>(
                              value: selectedPeriod,
                              isExpanded: true,
                              underline: Container(
                                height: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              items: ['Daily', 'Weekly', 'Monthly']
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedPeriod = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: limitCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Budget Limit (Optional)',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
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
                    final limit = limitCtrl.text.isNotEmpty
                        ? parseAmount(limitCtrl.text)
                        : null;

                    double? dailyLimit;
                    double? weeklyLimit;
                    double? monthlyLimit;

                    if (limit != null) {
                      if (selectedPeriod == 'Daily') {
                        dailyLimit = limit;
                      } else if (selectedPeriod == 'Weekly') {
                        weeklyLimit = limit;
                      } else {
                        monthlyLimit = limit;
                      }
                    }

                    if (name.isNotEmpty) {
                      if (categoryToEdit == null) {
                        context.read<LedgerProvider>().addCategory(
                          name,
                          isExpense,
                          monthlyLimit,
                          dailyLimit: dailyLimit,
                          weeklyLimit: weeklyLimit,
                          colorHex: currentColorHex,
                        );
                      } else {
                        context.read<LedgerProvider>().updateCategory(
                          categoryToEdit.id,
                          name,
                          isExpense,
                          monthlyLimit,
                          dailyLimit: dailyLimit,
                          weeklyLimit: weeklyLimit,
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
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context);
              return AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  const titles = [
                    'Main',
                    'Wallet',
                    'Expenses',
                    'Loans & Subs',
                    'Analytics',
                  ];
                  final index = tabController.index;
                  return Text(
                    index >= 0 && index < titles.length
                        ? titles[index]
                        : 'BudgetKo',
                  );
                },
              );
            },
          ),
          centerTitle: true,
          leadingWidth: 100,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: () async {
                  final db = context.read<BudgetDatabase>();
                  await DataExportService(db).exportLedgerToCsv();
                },
                tooltip: 'Export to CSV',
              ),
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
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Main'),
              Tab(text: 'Wallet'),
              Tab(text: 'Expenses'),
              Tab(text: 'Loans & Subs'),
              Tab(text: 'Analytics'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.donut_large_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TempGroupPoolScreen(),
                  ),
                );
              },
              tooltip: 'Temporary Group Pool',
            ),
            IconButton(
              icon: const Icon(Icons.groups_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupWalletScreen()),
                );
              },
              tooltip: 'Group Wallet Window',
            ),
            const NotificationBell(),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              tooltip: 'Settings',
            ),
          ],
        ),
        endDrawer: const NotificationDrawer(),
        body: TabBarView(
          children: [
            Builder(
              builder: (tabCtx) {
                return MainTab(
                  onAddAccount: () => _showAccountDialog(context),
                  onNavigateToTab: (index) {
                    DefaultTabController.of(tabCtx).animateTo(index);
                  },
                );
              },
            ),
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
                            settings.hideTotalAmount
                                ? '($currency••••••)'
                                : '($currency${totalMoney.toStringAsFixed(2)})',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: provider.accounts.map((acc) {
                        final accColor = Color(acc.colorHex);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: InkWell(
                            onTap: () => _showAccountDialog(context, acc),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.dividerColor,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      if (acc.currentBalance < acc.minBalance)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6.0),
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                        ),
                                      Text(
                                        '${acc.name}: $currency${acc.currentBalance.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...(_showAllCategories ||
                                    provider.categories.length <= 5
                                ? provider.categories
                                : provider.categories.take(5))
                            .map((cat) {
                              final catColor = Color(cat.colorHex);
                              final budgetStr = cat.dailyBudgetLimit != null
                                  ? ' ($currency${cat.dailyBudgetLimit!.toStringAsFixed(0)}/d)'
                                  : cat.weeklyBudgetLimit != null
                                  ? ' ($currency${cat.weeklyBudgetLimit!.toStringAsFixed(0)}/w)'
                                  : cat.monthlyBudgetLimit != null
                                  ? ' ($currency${cat.monthlyBudgetLimit!.toStringAsFixed(0)}/m)'
                                  : '';
                              return InkWell(
                                onTap: () => _showCategoryDialog(context, cat),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: catColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${cat.name}$budgetStr',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: theme.colorScheme.secondary
                                            .withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        if (provider.categories.length > 5) ...[
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => setState(
                              () => _showAllCategories = !_showAllCategories,
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _showAllCategories ? 'Show less' : 'Show all',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                    itemCount: provider.recentTransactions.length > 5
                        ? 5
                        : provider.recentTransactions.length,
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
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                              color: theme.dividerColor,
                              width: 1.0,
                            ),
                          ),
                          tileColor: theme.cardColor,
                          leading: CircleAvatar(
                            backgroundColor: isInc
                                ? Colors.green.withValues(alpha: 0.15)
                                : (isTransfer
                                      ? Colors.blueGrey.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15)),
                            child: Icon(
                              isTransfer
                                  ? Icons.swap_horiz
                                  : (isInc
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward),
                              color: isInc
                                  ? Colors.green
                                  : (isTransfer ? Colors.blueGrey : Colors.red),
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
                                    borderRadius: BorderRadius.circular(4),
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
                                  : (isTransfer ? Colors.blueGrey : Colors.red),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Total Expenses: $currency${totalExpenses.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium,
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
        floatingActionButton: () {
          final isDark = theme.brightness == Brightness.dark;
          final fabFgColor = isDark
              ? theme.scaffoldBackgroundColor
              : Colors.white;
          return FloatingActionButton.extended(
            elevation: 0,
            highlightElevation: 0,
            hoverElevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: theme.dividerColor, width: 1.0),
            ),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: fabFgColor,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionEntryScreen(),
                ),
              );
            },
            icon: Icon(Icons.add, color: fabFgColor),
            label: Text(
              'Add Transaction',
              style: TextStyle(color: fabFgColor, fontWeight: FontWeight.w500),
            ),
          );
        }(),
      ),
    );
  }
}
