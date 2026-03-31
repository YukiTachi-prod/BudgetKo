import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../models/task.dart';
import 'task_edit_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final tasks = taskProvider.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASKo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TaskEditScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, taskProvider, settingsProvider),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks found'))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskTile(
                        context,
                        task,
                        taskProvider,
                        settingsProvider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    TaskProvider taskProvider,
    SettingsProvider settingsProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Date Filter Row (Now single centered button)
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                taskProvider.filterDate == null
                    ? 'All Dates'
                    : DateFormat(
                        'MMM d, yyyy',
                      ).format(taskProvider.filterDate!),
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: taskProvider.filterDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                taskProvider.setFilterDate(date);
              },
            ),
          ),
          const SizedBox(height: 8),
          // Status Filter Row
          DropdownButtonFormField<String>(
            initialValue: taskProvider.filterStatus ?? 'All',
            decoration: const InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['All', ...settingsProvider.statuses].map((p) {
              return DropdownMenuItem(value: p, child: Text(p));
            }).toList(),
            onChanged: (val) =>
                taskProvider.setFilterStatus(val == 'All' ? null : val),
          ),
          const SizedBox(height: 12),
          // Category Filter Row
          DropdownButtonFormField<String>(
            initialValue: taskProvider.filterCategory ?? 'All',
            decoration: const InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['All', ...settingsProvider.categories].map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (val) =>
                taskProvider.setFilterCategory(val == 'All' ? null : val),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
    SettingsProvider settingsProvider,
  ) {
    final timeFormat = settingsProvider.isTime24h ? 'HH:mm' : 'hh:mm a';
    final formattedDate = DateFormat(
      'MMM d, yyyy $timeFormat',
    ).format(task.date);

    // Determine card background color based on deadline or status
    Color? cardColor;
    if (task.isFinished) {
      cardColor = const Color(
        0xFF2E7D32,
      ).withValues(alpha: 0.15); // Dim green for finished tasks
    } else {
      final now = DateTime.now();
      final difference = task.date.difference(now).inDays;
      final isToday =
          task.date.year == now.year &&
          task.date.month == now.month &&
          task.date.day == now.day;

      if (isToday || difference < 1) {
        cardColor = const Color(
          0xFFB71C1C,
        ).withValues(alpha: 0.15); // Dim red (Darker maroon-ish)
      } else if (difference <= 3) {
        cardColor = const Color(
          0xFFFBC02D,
        ).withValues(alpha: 0.2); // Dim yellow (Golden yellow-ish)
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: cardColor,
      child: ListTile(
        leading: Checkbox(
          value: task.isFinished,
          onChanged: (val) => taskProvider.toggleTaskFinished(task.id),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: task.isFinished ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$formattedDate | ${task.status} | ${task.category}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _confirmDelete(context, task.id, taskProvider),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskEditScreen(task: task)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTask(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
