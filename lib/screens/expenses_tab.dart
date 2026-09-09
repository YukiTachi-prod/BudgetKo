import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';

class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  String _dateFilter = 'This Week';
  double _scale = 1.0;

  bool _isWithinFilter(DateTime date) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return date.isAfter(weekAgo);
      case 'This Month':
        return date.year == now.year && date.month == now.month;
      case 'This Year':
        return date.year == now.year;
      default:
        return true;
    }
  }

  void _zoomIn() {
    setState(() {
      if (_scale < 4.0) {
        _scale *= 1.2;
      }
    });
  }

  void _zoomOut() {
    setState(() {
      if (_scale > 0.3) {
        _scale /= 1.2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final currency = context.watch<SettingsProvider>().currency;
    final theme = Theme.of(context);

    final expenses = provider.recentTransactions
        .where(
          (tx) =>
              tx.transactionType == TransactionType.expense.index &&
              _isWithinFilter(tx.date),
        )
        .toList();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Expenses', style: theme.textTheme.titleLarge),
                  DropdownButton<String>(
                    value: _dateFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'All Time',
                        child: Text('All Time'),
                      ),
                      DropdownMenuItem(
                        value: 'This Week',
                        child: Text('This Week'),
                      ),
                      DropdownMenuItem(
                        value: 'This Month',
                        child: Text('This Month'),
                      ),
                      DropdownMenuItem(
                        value: 'This Year',
                        child: Text('This Year'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _dateFilter = val);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No expenses found for this period.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Transform.scale(
                    scale: _scale,
                    alignment: Alignment.topLeft,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Account')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Expense')),
                        DataColumn(label: Text('Date')),
                      ],
                      rows: expenses.map((tx) {
                        final catList = provider.categories
                            .where((c) => c.id == tx.categoryId)
                            .toList();
                        final cat = catList.isNotEmpty ? catList.first : null;
                        final catName = cat?.name ?? 'Unknown';
                        final catColor = cat != null
                            ? Color(cat.colorHex)
                            : null;

                        final accList = provider.accounts
                            .where((a) => a.id == tx.fromAccountId)
                            .toList();
                        final acc = accList.isNotEmpty ? accList.first : null;
                        final accName = acc?.name ?? 'Unknown';
                        final accColor = acc != null
                            ? Color(acc.colorHex)
                            : null;

                        return DataRow(
                          color: catColor != null
                              ? WidgetStateProperty.all(
                                  catColor.withValues(alpha: 0.08),
                                )
                              : null,
                          cells: [
                            DataCell(
                              Text(
                                accName,
                                style: TextStyle(
                                  color: accColor,
                                  fontWeight: accColor != null
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                catName,
                                style: TextStyle(
                                  color: catColor,
                                  fontWeight: catColor != null
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                            DataCell(
                              Text('$currency${tx.amount.toStringAsFixed(2)}'),
                            ),
                            DataCell(
                              Text(() {
                                final d = tx.date;
                                final dateStr = d.toString().split(' ')[0];
                                if (d.hour == 0 &&
                                    d.minute == 0 &&
                                    d.second == 0) {
                                  return dateStr;
                                }
                                final timeStr =
                                    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                                return '$dateStr $timeStr';
                              }()),
                              showEditIcon: true,
                              onTap: () async {
                                final newDate = await showDatePicker(
                                  context: context,
                                  initialDate: tx.date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (newDate != null && newDate != tx.date) {
                                  if (!context.mounted) return;
                                  context
                                      .read<LedgerProvider>()
                                      .updateTransaction(
                                        transactionId: tx.id,
                                        amount: tx.amount,
                                        date: newDate,
                                        type: TransactionType
                                            .values[tx.transactionType],
                                        fromAccountId: tx.fromAccountId,
                                        toAccountId: tx.toAccountId,
                                        categoryId: tx.categoryId,
                                        notes: tx.notes,
                                      );
                                }
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              // Add some extra space at the bottom so the zoomed table doesn't get cut off by FABs
              const SizedBox(height: 200),
            ],
          ),
        ),
        if (expenses.isNotEmpty)
          Positioned(
            bottom: 100, // Positioned safely above the Scaffold's extended FAB
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomInExpenses',
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 0,
                  highlightElevation: 0,
                  hoverElevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                  onPressed: _zoomIn,
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'zoomOutExpenses',
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 0,
                  highlightElevation: 0,
                  hoverElevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                  onPressed: _zoomOut,
                  child: const Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
