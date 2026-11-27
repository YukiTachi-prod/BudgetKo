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
  final List<LedgerTransaction> allTransactions;
  final String dateFilter;

  const BudgetAnalytics({
    super.key,
    required this.accounts,
    required this.categories,
    required this.categoryExpenses,
    required this.recentTransactions,
    this.allTransactions = const [],
    required this.dateFilter,
  });

  @override
  State<BudgetAnalytics> createState() => _BudgetAnalyticsState();
}

class _BudgetAnalyticsState extends State<BudgetAnalytics> {
  final PageController _chartPageController = PageController(initialPage: 1000);
  final PageController _donutPageController = PageController(initialPage: 1000);

  String get _selectedPeriod {
    switch (widget.dateFilter) {
      case 'This Week':
        return 'Week';
      case 'This Month':
        return 'Month';
      case 'This Year':
        return 'Year';
      case 'Today':
      default:
        return 'Today';
    }
  }

  bool get _hasEnoughDataForFilter {
    final now = DateTime.now();
    DateTime priorStart;
    DateTime priorEnd;

    switch (widget.dateFilter) {
      case 'Today':
        final currentStart = DateTime(now.year, now.month, now.day);
        priorStart = currentStart.subtract(const Duration(days: 1));
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
      case 'This Week':
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        final currentStart = startOfWeek;
        priorStart = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day - 7,
        );
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
      case 'This Month':
        final currentStart = DateTime(now.year, now.month, 1);
        final priorYear = now.month == 1 ? now.year - 1 : now.year;
        final priorMonth = now.month == 1 ? 12 : now.month - 1;
        priorStart = DateTime(priorYear, priorMonth, 1);
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
      case 'This Year':
      default:
        final currentStart = DateTime(now.year, 1, 1);
        priorStart = DateTime(now.year - 1, 1, 1);
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
    }

    final txList = widget.allTransactions.isNotEmpty
        ? widget.allTransactions
        : widget.recentTransactions;

    return txList.any(
      (tx) => !tx.date.isBefore(priorStart) && !tx.date.isAfter(priorEnd),
    );
  }

  Map<String, dynamic> _getCategoryTrend(BudgetCategory c) {
    final now = DateTime.now();
    DateTime currentStart;
    DateTime currentEnd = now;
    DateTime priorStart;
    DateTime priorEnd;
    String periodLabel;

    switch (widget.dateFilter) {
      case 'Today':
        periodLabel = 'yesterday';
        currentStart = DateTime(now.year, now.month, now.day);
        priorStart = currentStart.subtract(const Duration(days: 1));
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
      case 'This Week':
        periodLabel = 'last week';
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        currentStart = startOfWeek;
        priorStart = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day - 7,
        );
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
      case 'This Month':
        periodLabel = 'last month';
        currentStart = DateTime(now.year, now.month, 1);
        final priorYear = now.month == 1 ? now.year - 1 : now.year;
        final priorMonth = now.month == 1 ? 12 : now.month - 1;
        priorStart = DateTime(priorYear, priorMonth, 1);
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
      case 'This Year':
      default:
        periodLabel = 'last year';
        currentStart = DateTime(now.year, 1, 1);
        priorStart = DateTime(now.year - 1, 1, 1);
        priorEnd = currentStart.subtract(const Duration(milliseconds: 1));
        break;
    }

    final txList = widget.allTransactions.isNotEmpty
        ? widget.allTransactions
        : widget.recentTransactions;

    final priorPeriodAllTx = txList.where(
      (tx) => !tx.date.isBefore(priorStart) && !tx.date.isAfter(priorEnd),
    );

    final bool hasEnoughData = priorPeriodAllTx.isNotEmpty;

    if (!hasEnoughData) {
      return {
        'hasEnoughData': false,
        'periodLabel': periodLabel,
        'message': 'Not enough data',
        'rate': 0.0,
        'isIncrease': false,
      };
    }

    final currentAmount = txList
        .where(
          (tx) =>
              tx.transactionType == TransactionType.expense.index &&
              tx.categoryId == c.id &&
              !tx.date.isBefore(currentStart) &&
              !tx.date.isAfter(currentEnd),
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final priorAmount = txList
        .where(
          (tx) =>
              tx.transactionType == TransactionType.expense.index &&
              tx.categoryId == c.id &&
              !tx.date.isBefore(priorStart) &&
              !tx.date.isAfter(priorEnd),
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);

    if (priorAmount == 0) {
      if (currentAmount > 0) {
        return {
          'hasEnoughData': true,
          'periodLabel': periodLabel,
          'message': 'New spending on ${c.name.toLowerCase()} vs $periodLabel',
          'rate': 100.0,
          'isIncrease': true,
        };
      } else {
        return {
          'hasEnoughData': true,
          'periodLabel': periodLabel,
          'message': 'No spending on ${c.name.toLowerCase()} in this period',
          'rate': 0.0,
          'isIncrease': false,
        };
      }
    }

    final diff = currentAmount - priorAmount;
    final percent = (diff / priorAmount) * 100;
    final absPercent = percent.abs().toStringAsFixed(0);

    if (diff > 0) {
      return {
        'hasEnoughData': true,
        'periodLabel': periodLabel,
        'message':
            '$absPercent% spent more on ${c.name.toLowerCase()} than $periodLabel',
        'rate': percent,
        'isIncrease': true,
      };
    } else if (diff < 0) {
      return {
        'hasEnoughData': true,
        'periodLabel': periodLabel,
        'message':
            '$absPercent% spent less on ${c.name.toLowerCase()} than $periodLabel',
        'rate': percent,
        'isIncrease': false,
      };
    } else {
      return {
        'hasEnoughData': true,
        'periodLabel': periodLabel,
        'message': 'Same spending on ${c.name.toLowerCase()} as $periodLabel',
        'rate': 0.0,
        'isIncrease': false,
      };
    }
  }

  @override
  void dispose() {
    _chartPageController.dispose();
    _donutPageController.dispose();
    super.dispose();
  }

  DateTime _getDateForIndex(int index, DateTime now) {
    if (_selectedPeriod == 'Week') {
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );
      return DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      );
    } else if (_selectedPeriod == 'Month') {
      return DateTime(now.year, now.month, index + 1);
    } else {
      return DateTime(now.year, index + 1, 1);
    }
  }

  String _formatTooltipDate(int index, DateTime now) {
    final date = _getDateForIndex(index, now);
    if (_selectedPeriod == 'Week' || _selectedPeriod == 'Month') {
      return DateFormat('EEE, MMM d').format(date);
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    if (value != value.toInt()) {
      return const SizedBox.shrink();
    }
    final int i = value.toInt();
    final now = DateTime.now();
    String text = '';
    if (_selectedPeriod == 'Week') {
      if (i < 0 || i > 6) return const SizedBox.shrink();
      final date = _getDateForIndex(i, now);
      text = DateFormat('EEE').format(date);
    } else if (_selectedPeriod == 'Month') {
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      if (i < 0 || i >= daysInMonth) return const SizedBox.shrink();
      if (i % 5 != 0 && i != daysInMonth - 1) {
        return const SizedBox.shrink();
      }
      if (i == 25 && daysInMonth - 1 - i <= 2) {
        return const SizedBox.shrink();
      }
      final date = _getDateForIndex(i, now);
      text = DateFormat('dd/MM').format(date);
    } else if (_selectedPeriod == 'Year') {
      if (i < 0 || i >= 12) return const SizedBox.shrink();
      final date = _getDateForIndex(i, now);
      text = DateFormat('MMM').format(date);
    }
    return Text(text, style: const TextStyle(fontSize: 10));
  }

  List<FlSpot> _getSpots() {
    final Map<int, double> grouped = {};
    final now = DateTime.now();
    for (var tx in widget.recentTransactions) {
      if (tx.transactionType == TransactionType.expense.index) {
        if (_selectedPeriod == 'Week') {
          final startOfWeek = DateTime(
            now.year,
            now.month,
            now.day - (now.weekday - 1),
          );
          final endOfWeek = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day + 7,
          );
          if (!tx.date.isBefore(startOfWeek) && tx.date.isBefore(endOfWeek)) {
            grouped[tx.date.weekday - 1] =
                (grouped[tx.date.weekday - 1] ?? 0) + tx.amount;
          }
        } else if (_selectedPeriod == 'Month') {
          if (tx.date.year == now.year && tx.date.month == now.month) {
            grouped[tx.date.day - 1] =
                (grouped[tx.date.day - 1] ?? 0) + tx.amount;
          }
        } else if (_selectedPeriod == 'Year') {
          if (tx.date.year == now.year) {
            grouped[tx.date.month - 1] =
                (grouped[tx.date.month - 1] ?? 0) + tx.amount;
          }
        }
      }
    }
    final int maxIndex = _selectedPeriod == 'Week'
        ? 7
        : (_selectedPeriod == 'Month'
              ? DateUtils.getDaysInMonth(now.year, now.month)
              : 12);
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
        ...widget.categories
            .where(
              (c) =>
                  c.monthlyBudgetLimit != null ||
                  c.weeklyBudgetLimit != null ||
                  c.dailyBudgetLimit != null,
            )
            .map((c) {
              final spent = widget.categoryExpenses[c.id] ?? 0.0;
              double baseLimit = 0.0;
              String basePeriod = '';
              if (c.dailyBudgetLimit != null) {
                baseLimit = c.dailyBudgetLimit!;
                basePeriod = 'Daily';
              } else if (c.weeklyBudgetLimit != null) {
                baseLimit = c.weeklyBudgetLimit!;
                basePeriod = 'Weekly';
              } else if (c.monthlyBudgetLimit != null) {
                baseLimit = c.monthlyBudgetLimit!;
                basePeriod = 'Monthly';
              }

              double limit = baseLimit;
              String periodLabel = basePeriod;

              final now = DateTime.now();
              final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
              final daysInYear =
                  DateTime(
                    now.year,
                    12,
                    31,
                  ).difference(DateTime(now.year, 1, 1)).inDays +
                  1;

              switch (widget.dateFilter) {
                case 'Today':
                  if (basePeriod == 'Weekly') {
                    limit = baseLimit / 7;
                  } else if (basePeriod == 'Monthly') {
                    limit = baseLimit / daysInMonth;
                  }
                  periodLabel = 'Today';
                  break;
                case 'This Week':
                  if (basePeriod == 'Daily') {
                    limit = baseLimit * 7;
                  } else if (basePeriod == 'Monthly') {
                    limit = (baseLimit * 12) / 52;
                  }
                  periodLabel = 'This Week';
                  break;
                case 'This Month':
                  if (basePeriod == 'Daily') {
                    limit = baseLimit * daysInMonth;
                  } else if (basePeriod == 'Weekly') {
                    limit = baseLimit * (daysInMonth / 7);
                  }
                  periodLabel = 'This Month';
                  break;
                case 'This Year':
                  if (basePeriod == 'Daily') {
                    limit = baseLimit * daysInYear;
                  } else if (basePeriod == 'Weekly') {
                    limit = baseLimit * 52;
                  } else if (basePeriod == 'Monthly') {
                    limit = baseLimit * 12;
                  }
                  periodLabel = 'This Year';
                  break;
              }

              final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

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
                          '${c.name} ($periodLabel)',
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final trend = _getCategoryTrend(c);
                        if (!trend['hasEnoughData']) {
                          return Text(
                            'Not enough data',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                        final isIncrease = trend['isIncrease'] as bool;
                        final message = trend['message'] as String;
                        final trendColor = isIncrease
                            ? (theme.brightness == Brightness.dark
                                  ? const Color(0xFFEF9A9A)
                                  : Colors.red.shade700)
                            : (theme.brightness == Brightness.dark
                                  ? const Color(0xFFA5D6A7)
                                  : Colors.green.shade700);

                        return Row(
                          children: [
                            Icon(
                              isIncrease
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 13,
                              color: trendColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                message,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: trendColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: widget.dateFilter == 'Today' ? 1 : null,
                controller: _chartPageController,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final pageType = index % 2;
                  if (pageType == 0) {
                    if (widget.dateFilter == 'Today') {
                      final totalToday = widget.categoryExpenses.values.fold(
                        0.0,
                        (a, b) => a + b,
                      );
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Expenses (Today)',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            'Today\'s Total',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currency${totalToday.toStringAsFixed(2)}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                        ],
                      );
                    }
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
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (spot) => theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final int i = spot.x.toInt();
                                        final now = DateTime.now();
                                        final dateLabel = _formatTooltipDate(
                                          i,
                                          now,
                                        );
                                        return LineTooltipItem(
                                          '$dateLabel\n$currency${spot.y.toStringAsFixed(2)}',
                                          TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
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
                                      interval: 1,
                                      getTitlesWidget: _buildBottomTitle,
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
                    if (widget.dateFilter == 'Today') {
                      final totalToday = widget.categoryExpenses.values.fold(
                        0.0,
                        (a, b) => a + b,
                      );
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Expenses (Bar - Today)',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            'Today\'s Total',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$currency${totalToday.toStringAsFixed(2)}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                        ],
                      );
                    }
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
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (group) => theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                          final int i = group.x;
                                          final now = DateTime.now();
                                          final dateLabel = _formatTooltipDate(
                                            i,
                                            now,
                                          );
                                          return BarTooltipItem(
                                            '$dateLabel\n$currency${rod.toY.toStringAsFixed(2)}',
                                            TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                  ),
                                ),
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
                                      interval: 1,
                                      getTitlesWidget: _buildBottomTitle,
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
              if (widget.dateFilter != 'Today')
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          _chartPageController.previousPage(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          _chartPageController.nextPage(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          height: 290,
          child: Stack(
            children: [
              PageView.builder(
                controller: _donutPageController,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final pageType = index % 2;
                  if (pageType == 0) {
                    // Horizontal bar chart for account balances
                    final activeAccounts = widget.accounts
                        .where((a) => a.currentBalance > 0)
                        .toList();
                    final maxBalance = activeAccounts.isEmpty
                        ? 0.0
                        : activeAccounts
                              .map((a) => a.currentBalance)
                              .reduce((a, b) => a > b ? a : b);

                    return Column(
                      children: [
                        Text(
                          'Account Balances',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: activeAccounts.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No positive account balances to display.',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: activeAccounts.length,
                                  itemBuilder: (context, idx) {
                                    final a = activeAccounts[idx];
                                    final percent = maxBalance > 0
                                        ? (a.currentBalance / maxBalance).clamp(
                                            0.0,
                                            1.0,
                                          )
                                        : 0.0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                a.name,
                                                style: TextStyle(
                                                  color: Color(a.colorHex),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '$currency${a.currentBalance.toStringAsFixed(2)}',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: percent,
                                            color: Color(a.colorHex),
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            minHeight: 8,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  } else {
                    // Horizontal bar chart for expense categories
                    final activeCategories = widget.categories
                        .where(
                          (c) => (widget.categoryExpenses[c.id] ?? 0.0) > 0,
                        )
                        .toList();
                    final maxExpense = activeCategories.isEmpty
                        ? 0.0
                        : activeCategories
                              .map((c) => widget.categoryExpenses[c.id] ?? 0.0)
                              .reduce((a, b) => a > b ? a : b);

                    return Column(
                      children: [
                        Text(
                          'Expense Categories',
                          style: theme.textTheme.titleMedium,
                        ),
                        if (!_hasEnoughDataForFilter) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Not enough data to calculate rates for this filter',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Expanded(
                          child: activeCategories.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No expenses recorded in this period.',
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: activeCategories.length,
                                  itemBuilder: (context, idx) {
                                    final c = activeCategories[idx];
                                    final amount =
                                        widget.categoryExpenses[c.id] ?? 0.0;
                                    final percent = maxExpense > 0
                                        ? (amount / maxExpense).clamp(0.0, 1.0)
                                        : 0.0;
                                    final trend = _getCategoryTrend(c);
                                    final bool hasEnoughData =
                                        trend['hasEnoughData'] as bool;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 6.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                c.name,
                                                style: TextStyle(
                                                  color: Color(c.colorHex),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '$currency${amount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: percent,
                                            color: Color(c.colorHex),
                                            backgroundColor:
                                                Colors.grey.shade300,
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (!hasEnoughData)
                                            Text(
                                              'Not enough data',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                          else ...[
                                            Row(
                                              children: [
                                                Icon(
                                                  (trend['isIncrease'] as bool)
                                                      ? Icons.trending_up
                                                      : Icons.trending_down,
                                                  size: 13,
                                                  color:
                                                      (trend['isIncrease']
                                                          as bool)
                                                      ? (theme.brightness ==
                                                                Brightness.dark
                                                            ? const Color(
                                                                0xFFEF9A9A,
                                                              )
                                                            : Colors
                                                                  .red
                                                                  .shade700)
                                                      : (theme.brightness ==
                                                                Brightness.dark
                                                            ? const Color(
                                                                0xFFA5D6A7,
                                                              )
                                                            : Colors
                                                                  .green
                                                                  .shade700),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    trend['message'] as String,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          (trend['isIncrease']
                                                              as bool)
                                                          ? (theme.brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? const Color(
                                                                    0xFFEF9A9A,
                                                                  )
                                                                : Colors
                                                                      .red
                                                                      .shade700)
                                                          : (theme.brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? const Color(
                                                                    0xFFA5D6A7,
                                                                  )
                                                                : Colors
                                                                      .green
                                                                      .shade700),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
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
                        _donutPageController.previousPage(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _donutPageController.nextPage(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
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
