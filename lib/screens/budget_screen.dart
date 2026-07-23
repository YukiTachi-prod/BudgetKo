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
import 'main_screen.dart';
import 'settings_screen.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import '../services/platform/platform_file_service.dart';
import '../widgets/transition_placeholder.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/notification_bell.dart';
import '../widgets/notification_drawer.dart';

class BudgetScreen extends StatefulWidget {
  final bool isDefault;
  const BudgetScreen({super.key, this.isDefault = false});

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
    String? currentBgPath = accountToEdit?.backgroundImagePath;
    bool clearBg = false;

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
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Custom Background (1000x300 PNG Only)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (currentBgPath != null && !clearBg)
                      Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(File(currentBgPath!)),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => clearBg = true),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                try {
                                  final byteData = await rootBundle.load(
                                    'lib/assets/Format.png',
                                  );
                                  await PlatformFileService().shareFile(
                                    byteData.buffer.asUint8List(),
                                    'Format.png',
                                    text:
                                        'Edit this 1000x300 PNG for your account background!',
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to load format file.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Export Format'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final res = await FilePicker.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['png'],
                                );
                                if (res != null &&
                                    res.files.single.path != null) {
                                  final path = res.files.single.path!;
                                  final fileName = res.files.single.name;

                                  final fileExists = await PlatformFileService()
                                      .fileExistsInAppStorage(fileName);
                                  if (fileExists && context.mounted) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Overwrite Background?',
                                        ),
                                        content: Text(
                                          'A background named "$fileName" already exists. Do you want to overwrite it?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'Overwrite',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;
                                  }

                                  final bytes = await File(path).readAsBytes();
                                  final codec = await ui.instantiateImageCodec(
                                    bytes,
                                  );
                                  final frame = await codec.getNextFrame();
                                  if (frame.image.width == 1000 &&
                                      frame.image.height == 300) {
                                    final savedPath =
                                        await PlatformFileService()
                                            .copyFileToAppStorage(
                                              path,
                                              fileName,
                                            );
                                    setState(() {
                                      currentBgPath = savedPath;
                                      clearBg = false;
                                    });
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Image must be exactly 1000x300 pixels!',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: const Text('Import'),
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
                          backgroundImagePath: clearBg ? null : currentBgPath,
                        );
                      } else {
                        context.read<LedgerProvider>().updateAccount(
                          accountToEdit.id,
                          name,
                          balance,
                          colorHex: currentColorHex,
                          minBalance: minBalance,
                          backgroundImagePath: currentBgPath,
                          clearBackgroundImage: clearBg,
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wallet'),
          centerTitle: true,
          leadingWidth: 180,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.description_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  if (widget.isDefault) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                tooltip: 'Tasks',
              ),
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
            tabs: [
              Tab(text: 'Wallet'),
              Tab(text: 'Expenses'),
              Tab(text: 'Loans & Subs'),
              Tab(text: 'Analytics'),
            ],
          ),
          actions: [
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
        body: TransitionPlaceholder(
          child: TabBarView(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: provider.accounts.map((acc) {
                          final accColor = Color(acc.colorHex);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () => _showAccountDialog(context, acc),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: acc.backgroundImagePath == null
                                      ? accColor.withValues(alpha: 0.08)
                                      : null,
                                  image: acc.backgroundImagePath != null
                                      ? DecorationImage(
                                          image: FileImage(
                                            File(acc.backgroundImagePath!),
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Spacer(flex: 7),
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        height: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              theme.brightness ==
                                                  Brightness.dark
                                              ? Colors.black87
                                              : Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                if (acc.currentBalance <
                                                    acc.minBalance)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 8.0,
                                                    ),
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                      size: 16,
                                                    ),
                                                  ),
                                                Flexible(
                                                  child: Text(
                                                    acc.name,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color:
                                                          theme.brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Flexible(
                                              child: Text(
                                                '$currency${acc.currentBalance.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 20,
                                                  color:
                                                      theme.brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                      const Text(
                        'No categories yet. Add one to start tracking!',
                      )
                    else
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          ...(_showAllCategories ||
                                      provider.categories.length <= 4
                                  ? provider.categories
                                  : provider.categories.take(4))
                              .map((cat) {
                                final catColor = Color(cat.colorHex);
                                return ActionChip(
                                  label: Text(
                                    '${cat.name} ${cat.dailyBudgetLimit != null
                                        ? '($currency${cat.dailyBudgetLimit!.toStringAsFixed(0)}/d)'
                                        : cat.weeklyBudgetLimit != null
                                        ? '($currency${cat.weeklyBudgetLimit!.toStringAsFixed(0)}/w)'
                                        : cat.monthlyBudgetLimit != null
                                        ? '($currency${cat.monthlyBudgetLimit!.toStringAsFixed(0)}/m)'
                                        : ''}',
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
                                  backgroundColor: catColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  side: BorderSide(
                                    color: catColor.withValues(alpha: 0.3),
                                  ),
                                  onPressed: () =>
                                      _showCategoryDialog(context, cat),
                                );
                              }),
                          if (!_showAllCategories &&
                              provider.categories.length > 4)
                            ActionChip(
                              label: const Text('Show More'),
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                              onPressed: () =>
                                  setState(() => _showAllCategories = true),
                            ),
                          if (_showAllCategories &&
                              provider.categories.length > 4)
                            ActionChip(
                              label: const Text('Show Less'),
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                              onPressed: () =>
                                  setState(() => _showAllCategories = false),
                            ),
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
                            tx.transactionType ==
                            TransactionType.transfer.index;

                        BudgetCategory? cat;
                        if (tx.categoryId != null) {
                          for (final c in provider.categories) {
                            if (c.id == tx.categoryId) {
                              cat = c;
                              break;
                            }
                          }
                        }
                        final catColor = cat != null
                            ? Color(cat.colorHex)
                            : null;

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
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward),
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
