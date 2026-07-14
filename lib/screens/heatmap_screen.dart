import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;

    // Filter finished tasks
    final finishedTasks = tasks.where((t) => t.isFinished).toList();

    if (finishedTasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Heatmap')),
        body: const Center(child: Text('No finished tasks available')),
      );
    }

    // Group tasks by date finished (endDate)
    final Map<DateTime, int> finishedCountByDate = {};
    DateTime minDate = finishedTasks.first.endDate;
    DateTime maxDate = finishedTasks.first.endDate;

    int maxCount = 0;

    for (var task in finishedTasks) {
      final date = DateTime(
        task.endDate.year,
        task.endDate.month,
        task.endDate.day,
      );
      if (date.isBefore(minDate)) minDate = date;
      if (date.isAfter(maxDate)) maxDate = date;

      final count = (finishedCountByDate[date] ?? 0) + 1;
      finishedCountByDate[date] = count;
      if (count > maxCount) maxCount = count;
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
                          final count = finishedCountByDate[currentDate] ?? 0;

                          Color cellColor = Colors.grey.withValues(
                            alpha: 0.2,
                          ); // default for 0
                          if (count > 0) {
                            final opacity = (count / maxCount).clamp(0.2, 1.0);
                            cellColor = Colors.cyan.withValues(alpha: opacity);
                          }

                          return Expanded(
                            child: Tooltip(
                              message:
                                  '${DateFormat('MMM d, yyyy').format(currentDate)}\nFinished: $count',
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                ),
                                decoration: BoxDecoration(
                                  color: cellColor,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    count > 0 ? count.toString() : '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2.0,
                                          color: Colors.black45,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
