import 'package:flutter/material.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final List<Map<String, dynamic>> _transactions = [];
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _isIncome = false;

  void _addTransaction() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount and description')),
      );
      return;
    }

    setState(() {
      _transactions.add({
        'amount': amount,
        'desc': _descController.text,
        'isIncome': _isIncome,
        'date': DateTime.now(),
      });
      _amountController.clear();
      _descController.clear();
    });
  }

  double get _totalBalance {
    return _transactions.fold(0.0, (sum, item) {
      return item['isIncome'] ? sum + item['amount'] : sum - item['amount'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Balance Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Total Balance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_totalBalance.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _totalBalance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Input Area
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Expense')),
                      ButtonSegment(value: true, label: Text('Income')),
                    ],
                    selected: {_isIncome},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _isIncome = newSelection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _addTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            // Transaction List
            Expanded(
              child: _transactions.isEmpty
                  ? const Center(child: Text('No transactions yet.'))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions.reversed.toList()[index];
                        final isInc = tx['isIncome'] as bool;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isInc
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.red.withValues(alpha: 0.2),
                            child: Icon(
                              isInc ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isInc ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(tx['desc']),
                          subtitle: Text(
                            (tx['date'] as DateTime).toString().split('.')[0],
                          ),
                          trailing: Text(
                            '${isInc ? '+' : '-'}\$${tx['amount'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isInc ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
