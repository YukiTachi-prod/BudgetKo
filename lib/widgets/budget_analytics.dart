import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../database/budget_database.dart';

class BudgetAnalytics extends StatefulWidget {
  final List<BudgetCategory> categories;
  final Map<int, double> categoryExpenses;
  final List<LedgerTransaction> recentTransactions;

  const BudgetAnalytics({
    super.key,
    required this.categories,
    required this.categoryExpenses,
    required this.recentTransactions,
  });

  @override
  State<BudgetAnalytics> createState() => _BudgetAnalyticsState();
}

class _BudgetAnalyticsState extends State<BudgetAnalytics> {
  final PageController _pageController = PageController(initialPage: 1000);
  String _selectedPeriod = 'Week';

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
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final isPie = index % 2 == 0;
              if (isPie) {
                return Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: widget.categories
                            .map((c) {
                              final amount =
                                  widget.categoryExpenses[c.id] ?? 0.0;
                              return PieChartSectionData(
                                color: Color(c.colorHex),
                                value: amount,
                                title: '$currency${amount.toStringAsFixed(0)}',
                                radius: 50,
                              );
                            })
                            .where((s) => s.value > 0)
                            .toList(),
                        centerSpaceRadius: 40,
                      ),
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
              } else {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Expenses: ', style: theme.textTheme.titleMedium),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            isDense: true,
                            items: ['Week', 'Month', 'Year']
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedPeriod = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTitlesWidget: (value, meta) {
                                    if (_selectedPeriod == 'Month' &&
                                        value % 5 != 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      value.toInt().toString(),
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
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swipe, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'Swipe to switch views',
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
                    Text(c.name),
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
