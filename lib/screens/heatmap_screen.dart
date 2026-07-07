import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../models/task.dart';

enum HeatmapSort { status, category, startDate, endDate }

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  HeatmapSort _currentSort = HeatmapSort.startDate;

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    final settings = Provider.of<SettingsProvider>(context);

    if (tasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Heatmap')),
        body: const Center(child: Text('No tasks available')),
      );
    }

    // Group tasks by date
    final Map<DateTime, List<Task>> tasksByDate = {};
    DateTime minDate = tasks.first.startDate;
    DateTime maxDate = tasks.first.startDate;

    for (var task in tasks) {
      final date = DateTime(
        task.startDate.year,
        task.startDate.month,
        task.startDate.day,
      );
      if (date.isBefore(minDate)) minDate = date;
      if (date.isAfter(maxDate)) maxDate = date;

      tasksByDate.putIfAbsent(date, () => []).add(task);
    }

    // Normalize minDate to Monday
    minDate = minDate.subtract(Duration(days: minDate.weekday - 1));
    // Normalize maxDate to Sunday
    maxDate = maxDate.add(Duration(days: 7 - maxDate.weekday));

    final weeksCount = maxDate.difference(minDate).inDays ~/ 7 + 1;
    final weekDates = List.generate(
      weeksCount,
      (i) => minDate.add(Duration(days: i * 7)),
    );

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Heatmap'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Row(
            children: [
              const Text('Sort tasks: ', style: TextStyle(fontSize: 13)),
              DropdownButton<HeatmapSort>(
                value: _currentSort,
                underline: const SizedBox(),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                ),
                items: const [
                  DropdownMenuItem(
                    value: HeatmapSort.startDate,
                    child: Text('Start Date'),
                  ),
                  DropdownMenuItem(
                    value: HeatmapSort.endDate,
                    child: Text('Date Finished'),
                  ),
                  DropdownMenuItem(
                    value: HeatmapSort.status,
                    child: Text('Status'),
                  ),
                  DropdownMenuItem(
                    value: HeatmapSort.category,
                    child: Text('Category'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _currentSort = val);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // X-Axis Labels (Days of Week)
            Row(
              children: [
                const SizedBox(width: 60), // Space for Y-Axis labels
                ...dayLabels.map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Heatmap Grid (Y-Axis = Weeks)
            Expanded(
              child: ListView.builder(
                itemCount: weeksCount,
                itemBuilder: (context, weekIndex) {
                  final weekStart = weekDates[weekIndex];

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Y-Axis Label (Week Start Date)
                        Container(
                          width: 60,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DateFormat('MMM d').format(weekStart),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        // Days in the week (X-Axis cells)
                        ...List.generate(7, (dayIndex) {
                          final currentDate = weekStart.add(
                            Duration(days: dayIndex),
                          );
                          final dailyTasks = List<Task>.from(
                            tasksByDate[currentDate] ?? [],
                          );

                          // Sort tasks within this day based on selection
                          dailyTasks.sort((a, b) {
                            switch (_currentSort) {
                              case HeatmapSort.status:
                                return a.status.compareTo(b.status);
                              case HeatmapSort.category:
                                return a.category.compareTo(b.category);
                              case HeatmapSort.startDate:
                                return a.startDate.compareTo(b.startDate);
                              case HeatmapSort.endDate:
                                return a.endDate.compareTo(b.endDate);
                            }
                          });

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(minHeight: 40),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                alignment: WrapAlignment.start,
                                children: dailyTasks.map((task) {
                                  final colorValue =
                                      settings.statusColors[task.status] ??
                                      Colors.grey.toARGB32();
                                  return Tooltip(
                                    message:
                                        '${task.title}\nStatus: ${task.status}\nCategory: ${task.category}',
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Color(colorValue),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }),
                      ],
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
