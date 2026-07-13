import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../database/budget_database.dart';

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});

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
    // Pre-fill sticky defaults
    final provider = context.read<LedgerProvider>();
    _selectedFromAccountId = provider.lastUsedAccountId;
    _selectedCategoryId = provider.lastUsedCategoryId;
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
      } else {
        if (_amountStr == '0') {
          _amountStr = value;
        } else {
          _amountStr += value;
        }
      }
    });
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountStr) ?? 0.0;
    if (amount <= 0 || _selectedFromAccountId == null) return;
    
    if (_type == TransactionType.transfer && _selectedToAccountId == null) return;
    if (_type != TransactionType.transfer && _selectedCategoryId == null) return;

    await context.read<LedgerProvider>().addTransaction(
      amount: amount,
      dateTime: DateTime.now(),
      type: _type,
      fromAccountId: _selectedFromAccountId!,
      toAccountId: _type == TransactionType.transfer ? _selectedToAccountId : null,
      categoryId: _type != TransactionType.transfer ? _selectedCategoryId : null,
    );
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final isTransfer = _type == TransactionType.transfer;

    return Scaffold(
      appBar: AppBar(title: const Text('New Transaction')),
      body: Column(
        children: [
          // Segmented Control for Type
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ButtonSegment(value: TransactionType.transfer, label: Text('Transfer')),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
          ),
          
          // Display Amount
          Text(
            '\$$_amountStr',
            style: Theme.of(context).textTheme.displayLarge,
          ),

          // Dynamic Selectors
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedFromAccountId,
                  hint: const Text('From Account'),
                  items: provider.accounts.map((a) => DropdownMenuItem(
                    value: a.id, child: Text(a.name),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedFromAccountId = v),
                ),
                if (isTransfer)
                  DropdownButtonFormField<int>(
                    value: _selectedToAccountId,
                    hint: const Text('To Account'),
                    items: provider.accounts.map((a) => DropdownMenuItem(
                      value: a.id, child: Text(a.name),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedToAccountId = v),
                  ),
                if (!isTransfer)
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    hint: const Text('Category'),
                    items: provider.categories
                        .where((c) => c.isExpense == (_type == TransactionType.expense))
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
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
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveTransaction,
                child: const Text('Save'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      '7', '8', '9', '+',
      '4', '5', '6', '-',
      '1', '2', '3', '⌫',
      '.', '0', '00', '='
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
        return TextButton(
          onPressed: () => _onNumpadTap(keys[index]),
          child: Text(keys[index], style: const TextStyle(fontSize: 24)),
        );
      },
    );
  }
}
