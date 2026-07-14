import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We want to see ALL tasks for analytics, ignoring filters
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final allTasks = taskProvider.allTasks;

    // Calculate Status statistics
    final Map<String, int> statusCounts = {};
    for (var status in settingsProvider.statuses) {
      statusCounts[status] = allTasks.where((t) => t.status == status).length;
    }

    // Calculate Category statistics
    final Map<String, int> categoryCounts = {};
    for (var category in settingsProvider.categories) {
      categoryCounts[category] = allTasks
          .where((t) => t.category == category)
          .length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Task Status Distribution'),
            const SizedBox(height: 8),
            _buildStatusTable(statusCounts),
            const SizedBox(height: 24),
            _buildSectionTitle('Category Overview'),
            const SizedBox(height: 12),
            ...categoryCounts.entries.map(
              (entry) =>
                  _buildCategoryStat(entry.key, entry.value, allTasks.length),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _buildStatusTable(Map<String, int> counts) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Table(
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Count',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            ...counts.entries.map(
              (entry) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(entry.key),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      entry.value.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStat(String name, int count, int total) {
    final double percentage = total > 0 ? (count / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              Text(
                '$count tasks',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
