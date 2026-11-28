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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final currency = context.watch<SettingsProvider>().currency;

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    const horizontalMargin = 4.0;
                    const columnSpacing = 4.0;
                    final availableColumnWidth =
                        constraints.maxWidth -
                        horizontalMargin * 2 -
                        columnSpacing * 3;

                    return DataTable(
                      horizontalMargin: horizontalMargin,
                      columnSpacing: columnSpacing,
                      columns: const [
                        DataColumn(label: Text('Account', maxLines: 1)),
                        DataColumn(label: Text('Category', maxLines: 1)),
                        DataColumn(label: Text('Expense', maxLines: 1)),
                        DataColumn(label: Text('Date', maxLines: 1)),
                      ],
                      rows: expenses.map((tx) {
                        Widget compactCell(
                          String text,
                          double width, {
                          TextStyle? style,
                        }) {
                          return SizedBox(
                            width: width,
                            child: Text(
                              text,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                          );
                        }

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
                              compactCell(
                                accName,
                                availableColumnWidth * 0.21,
                                style: TextStyle(
                                  color: accColor,
                                  fontWeight: accColor != null
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                            DataCell(
                              compactCell(
                                catName,
                                availableColumnWidth * 0.21,
                                style: TextStyle(
                                  color: catColor,
                                  fontWeight: catColor != null
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                            DataCell(
                              compactCell(
                                '$currency${tx.amount.toStringAsFixed(2)}',
                                availableColumnWidth * 0.25,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: availableColumnWidth * 0.33,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        (() {
                                          final d = tx.date;
                                          final dateStr = d.toString().split(
                                            ' ',
                                          )[0];
                                          if (d.hour == 0 &&
                                              d.minute == 0 &&
                                              d.second == 0) {
                                            return dateStr;
                                          }
                                          final timeStr =
                                              '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                                          return '$dateStr $timeStr';
                                        })(),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.edit, size: 14),
                                  ],
                                ),
                              ),
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
                    );
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
