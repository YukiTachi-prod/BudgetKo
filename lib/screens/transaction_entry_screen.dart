import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ledger_provider.dart';
import '../database/budget_database.dart';
import '../utils/math_util.dart';

class TransactionEntryScreen extends StatefulWidget {
  final LedgerTransaction? transactionToEdit;

  const TransactionEntryScreen({super.key, this.transactionToEdit});

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  TransactionType _type = TransactionType.expense;
  String _amountStr = '0';
  int? _selectedFromAccountId;
  int? _selectedToAccountId;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _type = TransactionType.values[tx.transactionType];
      _amountStr = tx.amount.toString();
      if (_amountStr.endsWith('.0')) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 2);
      }
      _selectedFromAccountId = tx.fromAccountId;
      _selectedToAccountId = tx.toAccountId;
      _selectedCategoryId = tx.categoryId;
    } else {
      // Pre-fill sticky defaults
      final provider = context.read<LedgerProvider>();
      _selectedFromAccountId = provider.lastUsedAccountId;
      _selectedCategoryId = provider.lastUsedCategoryId;
    }
  }

  void _onNumpadTap(String value) {
    setState(() {
      if (value == '⌫') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (value == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
      } else if (value == '=') {
        _amountStr = parseAmount(_amountStr).toString();
        if (_amountStr.endsWith('.0')) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 2);
        }
      } else {
        if (_amountStr == '0' && value != '+' && value != '-') {
          _amountStr = value;
        } else {
          _amountStr += value;
        }
      }
    });
  }

  double _calculateHypotheticalBalance(LedgerProvider provider) {
    if (_selectedFromAccountId == null) return 0.0;
    final acc = provider.accounts.firstWhere(
      (a) => a.id == _selectedFromAccountId,
    );
    double balance = acc.currentBalance;
    final amount = parseAmount(_amountStr);

    // If editing, reverse the old transaction first
    if (widget.transactionToEdit != null) {
      final oldTx = widget.transactionToEdit!;
      final oldType = TransactionType.values[oldTx.transactionType];
      if (oldTx.fromAccountId == _selectedFromAccountId) {
        if (oldType == TransactionType.expense ||
            oldType == TransactionType.transfer) {
          balance += oldTx.amount;
        } else if (oldType == TransactionType.income) {
          balance -= oldTx.amount;
        }
      }
      if (oldTx.toAccountId == _selectedFromAccountId &&
          oldType == TransactionType.transfer) {
        balance -= oldTx.amount;
      }
    }

    // Now apply the new transaction
    if (_type == TransactionType.expense || _type == TransactionType.transfer) {
      balance -= amount;
    } else if (_type == TransactionType.income) {
      balance += amount;
    }

    return balance;
  }

  Future<void> _saveTransaction() async {
    final amount = parseAmount(_amountStr);
    if (amount <= 0 || _selectedFromAccountId == null) return;

    if (_type == TransactionType.transfer && _selectedToAccountId == null) {
      return;
    }
    if (_type != TransactionType.transfer && _selectedCategoryId == null) {
      return;
    }

    final provider = context.read<LedgerProvider>();
    final currency = context.read<SettingsProvider>().currency;

    if (_type == TransactionType.expense || _type == TransactionType.transfer) {
      final newBalance = _calculateHypotheticalBalance(provider);
      if (newBalance < 0) {
        final acc = provider.accounts.firstWhere(
          (a) => a.id == _selectedFromAccountId,
        );
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Negative Balance Warning'),
            content: Text(
              'This transaction will cause the account "${acc.name}" to drop to a negative balance ($currency${newBalance.toStringAsFixed(2)}).\n\nTransaction is blocked.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (widget.transactionToEdit != null) {
      await provider.updateTransaction(
        transactionId: widget.transactionToEdit!.id,
        amount: amount,
        date: widget.transactionToEdit!.date,
        type: _type,
        fromAccountId: _selectedFromAccountId!,
        toAccountId: _type == TransactionType.transfer
            ? _selectedToAccountId
            : null,
        categoryId: _type != TransactionType.transfer
            ? _selectedCategoryId
            : null,
      );
    } else {
      await provider.addTransaction(
        amount: amount,
        date: DateTime.now(),
        type: _type,
        fromAccountId: _selectedFromAccountId!,
        toAccountId: _type == TransactionType.transfer
            ? _selectedToAccountId
            : null,
        categoryId: _type != TransactionType.transfer
            ? _selectedCategoryId
            : null,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final isTransfer = _type == TransactionType.transfer;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit != null
              ? 'Edit Transaction'
              : 'New Transaction',
        ),
        actions: widget.transactionToEdit != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await context.read<LedgerProvider>().deleteTransaction(
                      widget.transactionToEdit!.id,
                    );
                    if (!context.mounted) return;
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Segmented Control for Type
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Transfer'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
          ),

          // Display Amount
          Text(
            '$currency$_amountStr',
            style: Theme.of(context).textTheme.displayLarge,
          ),

          // Dynamic Selectors
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedFromAccountId,
                  hint: const Text('From Account'),
                  items: provider.accounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFromAccountId = v),
                ),
                if (isTransfer) const SizedBox(height: 16),
                if (isTransfer)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedToAccountId,
                    hint: const Text('To Account'),
                    items: provider.accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedToAccountId = v),
                  ),
                if (!isTransfer) const SizedBox(height: 16),
                if (!isTransfer)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    hint: const Text('Category'),
                    items: provider.categories
                        .where(
                          (c) =>
                              c.isExpense == (_type == TransactionType.expense),
                        )
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(c.colorHex),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
              ],
            ),
          ),
          const Spacer(),

          // 4x4 Custom Numpad
          _buildNumpad(),

          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 40.0,
            ),
            child: Center(
              child: SizedBox(
                width: 160,
                height: 52,
                child: FilledButton(
                  onPressed: _saveTransaction,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      '7',
      '8',
      '9',
      '+',
      '4',
      '5',
      '6',
      '-',
      '1',
      '2',
      '3',
      '⌫',
      '.',
      '0',
      '00',
      '=',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.all(4),
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _onNumpadTap(keys[index]),
            child: Text(keys[index], style: const TextStyle(fontSize: 24)),
          ),
        );
      },
    );
  }
}
