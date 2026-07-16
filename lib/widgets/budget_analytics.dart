import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';

class BudgetAnalytics extends StatefulWidget {
  final List<Account> accounts;
  final List<BudgetCategory> categories;
  final Map<int, double> categoryExpenses;
  final List<LedgerTransaction> recentTransactions;
  final String dateFilter;

  const BudgetAnalytics({
    super.key,
    required this.accounts,
    required this.categories,
    required this.categoryExpenses,
    required this.recentTransactions,
    required this.dateFilter,
  });

  @override
  State<BudgetAnalytics> createState() => _BudgetAnalyticsState();
}

class _BudgetAnalyticsState extends State<BudgetAnalytics> {
  final PageController _pageController = PageController(initialPage: 1002);

  String get _selectedPeriod {
    switch (widget.dateFilter) {
      case 'This Week':
        return 'Week';
      case 'This Month':
        return 'Month';
      case 'This Year':
      case 'All Time':
      default:
        return 'Year';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<FlSpot> _getSpots() {
    final Map<int, double> grouped = {};
    final now = DateTime.now();
    for (var tx in widget.recentTransactions) {
      if (tx.transactionType == TransactionType.expense.index) {
        if (_selectedPeriod == 'Week') {
          final diff = now.difference(tx.date).inDays;
          if (diff >= 0 && diff < 7) {
            grouped[6 - diff] = (grouped[6 - diff] ?? 0) + tx.amount;
          }
        } else if (_selectedPeriod == 'Month') {
          final diff = now.difference(tx.date).inDays;
          if (diff >= 0 && diff < 30) {
            grouped[29 - diff] = (grouped[29 - diff] ?? 0) + tx.amount;
          }
        } else if (_selectedPeriod == 'Year') {
          final monthDiff =
              (now.year - tx.date.year) * 12 + now.month - tx.date.month;
          if (monthDiff >= 0 && monthDiff < 12) {
            grouped[11 - monthDiff] =
                (grouped[11 - monthDiff] ?? 0) + tx.amount;
          }
        }
      }
    }
    final int maxIndex = _selectedPeriod == 'Week'
        ? 7
        : (_selectedPeriod == 'Month' ? 30 : 12);
    final spots = <FlSpot>[];
    for (int i = 0; i < maxIndex; i++) {
      spots.add(FlSpot(i.toDouble(), grouped[i] ?? 0.0));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final pageType = index % 4;
                  if (pageType == 0) {
                    // Donut chart comparing amount of money inside accounts
                    final sections = widget.accounts
                        .map((a) {
                          return PieChartSectionData(
                            color: Color(a.colorHex),
                            value: a.currentBalance > 0
                                ? a.currentBalance
                                : 0.0,
                            title:
                                '${a.name}\n$currency${a.currentBalance.toStringAsFixed(0)}',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        })
                        .where((s) => s.value > 0)
                        .toList();

                    return Column(
                      children: [
                        Text(
                          'Account Balances',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: sections.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No positive account balances to display.',
                                  ),
                                )
                              : PieChart(
                                  PieChartData(
                                    sections: sections,
                                    centerSpaceRadius: 40,
                                  ),
                                ),
                        ),
                      ],
                    );
                  } else if (pageType == 1) {
                    // Donut chart showing expense categories
                    final sections = widget.categories
                        .map((c) {
                          final amount = widget.categoryExpenses[c.id] ?? 0.0;
                          return PieChartSectionData(
                            color: Color(c.colorHex),
                            value: amount,
                            title:
                                '${c.name}\n$currency${amount.toStringAsFixed(0)}',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        })
                        .where((s) => s.value > 0)
                        .toList();

                    return Stack(
                      children: [
                        Column(
                          children: [
                            Text(
                              'Expense Categories',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: sections.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No expenses recorded in this period.',
                                      ),
                                    )
                                  : PieChart(
                                      PieChartData(
                                        sections: sections,
                                        centerSpaceRadius: 40,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenDonutChart(
                                    categories: widget.categories,
                                    categoryExpenses: widget.categoryExpenses,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  } else if (pageType == 2) {
                    return Column(
                      children: [
                        Text(
                          'Expenses (${widget.dateFilter})',
                          style: theme.textTheme.titleMedium,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 16.0,
                              top: 16.0,
                            ),
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.2),
                                    strokeWidth: 1.5,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, meta) {
                                        if (value != value.toInt()) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      getTitlesWidget: (value, meta) {
                                        if (value != value.toInt()) {
                                          return const SizedBox.shrink();
                                        }
                                        final int i = value.toInt();
                                        final now = DateTime.now();
                                        String text = '';
                                        if (_selectedPeriod == 'Week') {
                                          final date = now.subtract(
                                            Duration(days: 6 - i),
                                          );
                                          text = DateFormat('EEE').format(date);
                                        } else if (_selectedPeriod == 'Month') {
                                          if (i % 5 != 0 && i != 29) {
                                            return const SizedBox.shrink();
                                          }
                                          final date = now.subtract(
                                            Duration(days: 29 - i),
                                          );
                                          text = DateFormat(
                                            'dd/MM',
                                          ).format(date);
                                        } else if (_selectedPeriod == 'Year') {
                                          final date = DateTime(
                                            now.year,
                                            now.month - (11 - i),
                                            1,
                                          );
                                          text = DateFormat('MMM').format(date);
                                        }
                                        return Text(
                                          text,
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _getSpots(),
                                    isCurved: false,
                                    color: theme.colorScheme.primary,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Text(
                          'Expenses (Bar - ${widget.dateFilter})',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 16.0,
                              top: 16.0,
                            ),
                            child: BarChart(
                              BarChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.2),
                                    strokeWidth: 1.5,
                                    dashArray: [4, 4],
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, meta) {
                                        if (value != value.toInt()) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      getTitlesWidget: (value, meta) {
                                        if (value != value.toInt()) {
                                          return const SizedBox.shrink();
                                        }
                                        final int i = value.toInt();
                                        final now = DateTime.now();
                                        String text = '';
                                        if (_selectedPeriod == 'Week') {
                                          final date = now.subtract(
                                            Duration(days: 6 - i),
                                          );
                                          text = DateFormat('EEE').format(date);
                                        } else if (_selectedPeriod == 'Month') {
                                          if (i % 5 != 0 && i != 29) {
                                            return const SizedBox.shrink();
                                          }
                                          final date = now.subtract(
                                            Duration(days: 29 - i),
                                          );
                                          text = DateFormat(
                                            'dd/MM',
                                          ).format(date);
                                        } else if (_selectedPeriod == 'Year') {
                                          final date = DateTime(
                                            now.year,
                                            now.month - (11 - i),
                                            1,
                                          );
                                          text = DateFormat('MMM').format(date);
                                        }
                                        return Text(
                                          text,
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: () {
                                  final spots = _getSpots();
                                  return spots
                                      .map(
                                        (spot) => BarChartGroupData(
                                          x: spot.x.toInt(),
                                          barRods: [
                                            BarChartRodData(
                                              toY: spot.y,
                                              color: theme.colorScheme.primary,
                                              width: _selectedPeriod == 'Month'
                                                  ? 4
                                                  : 16,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(4),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList();
                                }(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Tap left or right to switch views',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...widget.categories.where((c) => c.monthlyBudgetLimit != null).map((
          c,
        ) {
          final spent = widget.categoryExpenses[c.id] ?? 0.0;
          final limit = c.monthlyBudgetLimit!;
          final percent = (spent / limit).clamp(0.0, 1.0);

          Color progressColor = Colors.green;
          if (percent > 0.9) {
            progressColor = Colors.red;
          } else if (percent > 0.75) {
            progressColor = Colors.orange;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        color: Color(c.colorHex),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$currency${spent.toStringAsFixed(2)} / $currency${limit.toStringAsFixed(2)}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percent,
                  color: progressColor,
                  backgroundColor: Colors.grey.shade300,
                  minHeight: 8,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class FullScreenDonutChart extends StatefulWidget {
  final List<BudgetCategory> categories;
  final Map<int, double> categoryExpenses;

  const FullScreenDonutChart({
    super.key,
    required this.categories,
    required this.categoryExpenses,
  });

  @override
  State<FullScreenDonutChart> createState() => _FullScreenDonutChartState();
}

class _FullScreenDonutChartState extends State<FullScreenDonutChart> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currency;
    final validSections = widget.categories
        .map((c) {
          final amount = widget.categoryExpenses[c.id] ?? 0.0;
          return MapEntry(c, amount);
        })
        .where((e) => e.value > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses Chart')),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: validSections.map((e) {
                  return PieChartSectionData(
                    color: Color(e.key.colorHex),
                    value: e.value,
                    title: '$currency${e.value.toStringAsFixed(0)}',
                    radius: 80,
                  );
                }).toList(),
                centerSpaceRadius: 60,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              children: validSections.map((e) {
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Color(e.key.colorHex)),
                  title: Text(e.key.name),
                  trailing: Text('$currency${e.value.toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
