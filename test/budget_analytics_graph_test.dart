import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tasker/widgets/budget_analytics.dart';
import 'package:tasker/providers/settings_provider.dart';
import 'package:tasker/database/budget_database.dart';

void main() {
  group('BudgetAnalytics line graph day & date mapping tests', () {
    testWidgets(
      'Week mode maps expense on specific weekday to matching day label',
      (tester) async {
        final now = DateTime.now();
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );

        // Create a transaction on Tuesday of this week at 14:00
        final tuesdayDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day + 1,
          14,
          0,
        );
        final txTuesday = LedgerTransaction(
          id: 1,
          amount: 25.0,
          date: tuesdayDate,
          transactionType: TransactionType.expense.index,
          fromAccountId: 1,
          categoryId: 1,
        );

        const category = BudgetCategory(
          id: 1,
          name: 'Food',
          iconCodePoint: 0xe000,
          colorHex: 0xFF00FF00,
          isExpense: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider(
              create: (_) => SettingsProvider(),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BudgetAnalytics(
                    accounts: const [],
                    categories: const [category],
                    categoryExpenses: const {1: 25.0},
                    recentTransactions: [txTuesday],
                    allTransactions: [txTuesday],
                    dateFilter: 'This Week',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final lineChartFinder = find.byType(LineChart);
        expect(lineChartFinder, findsOneWidget);

        final lineChart = tester.widget<LineChart>(lineChartFinder);
        final barData = lineChart.data.lineBarsData.first;

        // Spot at x = 1 (Tuesday, index = weekday - 1 = 1) should have y = 25.0
        final tuesdaySpot = barData.spots.firstWhere((s) => s.x == 1.0);
        expect(tuesdaySpot.y, 25.0);

        // Spot at x = 0 (Monday) should have y = 0.0
        final mondaySpot = barData.spots.firstWhere((s) => s.x == 0.0);
        expect(mondaySpot.y, 0.0);

        // Verify bottom titles widget for x = 0, 1, 2, ..., 6 matches Monday to Sunday
        final bottomTitles = lineChart.data.titlesData.bottomTitles;
        for (int i = 0; i < 7; i++) {
          final expectedDate = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day + i,
          );
          final expectedDayText = DateFormat('EEE').format(expectedDate);

          final titleWidget = bottomTitles.sideTitles.getTitlesWidget(
            i.toDouble(),
            TitleMeta(
              min: 0,
              max: 6,
              parentAxisSize: 100,
              axisSide: AxisSide.bottom,
              appliedInterval: 1,
              sideTitles: bottomTitles.sideTitles,
              formattedValue: '$i',
              axisPosition: 0,
              rotationQuarterTurns: 0,
            ),
          );
          expect(titleWidget, isA<Text>());
          expect((titleWidget as Text).data, expectedDayText);
        }
      },
    );

    testWidgets('Month mode maps expense day to matching day of month', (
      tester,
    ) async {
      final now = DateTime.now();
      final day5Date = DateTime(now.year, now.month, 5, 12, 0);
      final txDay5 = LedgerTransaction(
        id: 2,
        amount: 80.0,
        date: day5Date,
        transactionType: TransactionType.expense.index,
        fromAccountId: 1,
        categoryId: 1,
      );

      const category = BudgetCategory(
        id: 1,
        name: 'Bills',
        iconCodePoint: 0xe000,
        colorHex: 0xFF00FF00,
        isExpense: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => SettingsProvider(),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BudgetAnalytics(
                  accounts: const [],
                  categories: const [category],
                  categoryExpenses: const {1: 80.0},
                  recentTransactions: [txDay5],
                  allTransactions: [txDay5],
                  dateFilter: 'This Month',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lineChartFinder = find.byType(LineChart);
      expect(lineChartFinder, findsOneWidget);

      final lineChart = tester.widget<LineChart>(lineChartFinder);
      final barData = lineChart.data.lineBarsData.first;

      // Spot at x = 4 (Day 5, index = 5 - 1 = 4) should have y = 80.0
      final day5Spot = barData.spots.firstWhere((s) => s.x == 4.0);
      expect(day5Spot.y, 80.0);

      // Verify bottom titles widget for index 0 (Day 1) shows dd/MM for current month
      final bottomTitles = lineChart.data.titlesData.bottomTitles;
      final expectedDay1Date = DateTime(now.year, now.month, 1);
      final expectedDay1Text = DateFormat('dd/MM').format(expectedDay1Date);

      final titleWidget = bottomTitles.sideTitles.getTitlesWidget(
        0.0,
        TitleMeta(
          min: 0,
          max: 30,
          parentAxisSize: 100,
          axisSide: AxisSide.bottom,
          appliedInterval: 1,
          sideTitles: bottomTitles.sideTitles,
          formattedValue: '0',
          axisPosition: 0,
          rotationQuarterTurns: 0,
        ),
      );
      expect(titleWidget, isA<Text>());
      expect((titleWidget as Text).data, expectedDay1Text);
    });
  });
}
