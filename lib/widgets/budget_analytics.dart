import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/budget_database.dart';

class BudgetAnalytics extends StatelessWidget {
  final List<Category> categories;
  final Map<int, double> categoryExpenses;

  const BudgetAnalytics({
    super.key,
    required this.categories,
    required this.categoryExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: categories.map((c) {
                final amount = categoryExpenses[c.id] ?? 0.0;
                return PieChartSectionData(
                  color: Color(c.colorHex),
                  value: amount,
                  title: '\$${amount.toStringAsFixed(0)}',
                  radius: 50,
                );
              }).where((s) => s.value > 0).toList(),
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...categories.where((c) => c.monthlyBudgetLimit != null).map((c) {
          final spent = categoryExpenses[c.id] ?? 0.0;
          final limit = c.monthlyBudgetLimit!;
          final percent = (spent / limit).clamp(0.0, 1.0);
          
          Color progressColor = Colors.green;
          if (percent > 0.9) progressColor = Colors.red;
          else if (percent > 0.75) progressColor = Colors.orange;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.name),
                    Text('\$${spent.toStringAsFixed(2)} / \$${limit.toStringAsFixed(2)}'),
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
