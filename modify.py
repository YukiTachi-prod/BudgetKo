import re

with open('lib/widgets/budget_analytics.dart', 'r') as f:
    content = f.read()

# 1. Update _selectedPeriod
content = content.replace("""  String get _selectedPeriod {
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
  }""", """  String get _selectedPeriod {
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
  }""")

# 2. Update _getSpots
content = content.replace("""  List<FlSpot> _getSpots() {
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
  }""", """  List<FlSpot> _getSpots() {
    final Map<int, double> grouped = {};
    final now = DateTime.now();
    for (var tx in widget.recentTransactions) {
      if (tx.transactionType == TransactionType.expense.index) {
        if (_selectedPeriod == 'Week') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          if (!tx.date.isBefore(start)) {
            grouped[tx.date.weekday - 1] = (grouped[tx.date.weekday - 1] ?? 0) + tx.amount;
          }
        } else if (_selectedPeriod == 'Month') {
          if (tx.date.year == now.year && tx.date.month == now.month) {
            grouped[tx.date.day - 1] = (grouped[tx.date.day - 1] ?? 0) + tx.amount;
          }
        } else if (_selectedPeriod == 'Year') {
          if (tx.date.year == now.year) {
            grouped[tx.date.month - 1] = (grouped[tx.date.month - 1] ?? 0) + tx.amount;
          }
        }
      }
    }
    final int maxIndex = _selectedPeriod == 'Week'
        ? 7
        : (_selectedPeriod == 'Month' ? DateUtils.getDaysInMonth(now.year, now.month) : 12);
    final spots = <FlSpot>[];
    for (int i = 0; i < maxIndex; i++) {
      spots.add(FlSpot(i.toDouble(), grouped[i] ?? 0.0));
    }
    return spots;
  }""")

content = content.replace("""            case 'All Time':
              periodLabel = '$basePeriod (Avg)';
              break;""", "")

bottom_titles_orig = """                                          if (_selectedPeriod == 'Week') {
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
                                          }"""

bottom_titles_new = """                                          if (_selectedPeriod == 'Week') {
                                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                            if (i >= 0 && i < 7) {
                                              text = days[i];
                                            }
                                          } else if (_selectedPeriod == 'Month') {
                                            if (i % 5 != 0 && i != DateUtils.getDaysInMonth(now.year, now.month) - 1) {
                                              return const SizedBox.shrink();
                                            }
                                            text = '${i + 1}';
                                          } else if (_selectedPeriod == 'Year') {
                                            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                            if (i >= 0 && i < 12) {
                                              text = months[i];
                                            }
                                          }"""

content = content.replace(bottom_titles_orig, bottom_titles_new)

overlay_line = """                  } else if (pageType == 2) {
                    if (widget.dateFilter == 'Today') {
                      final totalToday = widget.categoryExpenses.values.fold(0.0, (a, b) => a + b);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Expenses (Today)',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            'Today\\'s Total',
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
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
                    return Column("""

content = content.replace("                  } else if (pageType == 2) {\n                    return Column(", overlay_line)

overlay_bar = """                  } else {
                    if (widget.dateFilter == 'Today') {
                      final totalToday = widget.categoryExpenses.values.fold(0.0, (a, b) => a + b);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Expenses (Bar - Today)',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            'Today\\'s Total',
                            style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
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
                    return Column("""
content = content.replace("                  } else {\n                    return Column(", overlay_bar)

content = content.replace(
    "final PageController _pageController = PageController(initialPage: 1002);",
    "final PageController _chartPageController = PageController(initialPage: 1000);\n  final PageController _donutPageController = PageController(initialPage: 1000);"
)

content = content.replace(
    "_pageController.dispose();",
    "_chartPageController.dispose();\n    _donutPageController.dispose();"
)

parts = content.split("final pageType = index % 4;")
if len(parts) == 2:
    before = parts[0].replace("controller: _pageController,", "controller: _chartPageController,")
    rest = parts[1]
    
    b0_split = rest.split("} else if (pageType == 1) {")
    block_0 = b0_split[0].replace("if (pageType == 0) {", "").strip()
    
    b1_split = b0_split[1].split("} else if (pageType == 2) {")
    block_1 = b1_split[0].strip()
    
    b2_split = b1_split[1].split("} else {")
    block_2 = b2_split[0].strip()
    
    b3_split = b2_split[1].split("}\n                },")
    block_3 = b3_split[0].strip()
    
    after_item_builder = "}\n                }," + b3_split[1]
    
    new_item_builder_1 = f"""final pageType = index % 2;
                  if (pageType == 0) {{
                    {block_2}
                  }} else {{
                    {block_3}
"""
                
    after_chart_nav = after_item_builder.replace("_pageController.previousPage(", "_chartPageController.previousPage(").replace("_pageController.nextPage(", "_chartPageController.nextPage(")
    
    nav_split = after_chart_nav.split("const SizedBox(height: 8),")
    chart_nav = nav_split[0]
    after_first_sized_box = "const SizedBox(height: 8)," + "const SizedBox(height: 8),".join(nav_split[1:])
    
    second_container = f"""
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              PageView.builder(
                controller: _donutPageController,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {{
                  final pageType = index % 2;
                  if (pageType == 0) {{
                    {block_0}
                  }} else {{
                    {block_1}
                  }}
                }},
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {{
                        _donutPageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }},
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {{
                        _donutPageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
"""
    
    final_content = before + new_item_builder_1 + chart_nav + second_container + after_first_sized_box
    final_content = final_content.replace("isCurved: false,", "isCurved: true,")
    
    with open('lib/widgets/budget_analytics.dart', 'w') as f:
        f.write(final_content)
    print("Modified successfully")
else:
    print("Could not split content")

