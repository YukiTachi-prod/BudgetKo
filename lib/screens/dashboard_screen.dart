import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../models/task.dart';
import 'task_edit_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isMultiSelectionMode = false;
  final Set<String> _selectedTaskIds = {};

  void _toggleMultiSelectionMode() {
    setState(() {
      _isMultiSelectionMode = !_isMultiSelectionMode;
      if (!_isMultiSelectionMode) {
        _selectedTaskIds.clear(); // Clear selection when exiting mode
      }
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _deleteSelectedTasks(TaskProvider taskProvider) {
    if (_selectedTaskIds.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Selected Tasks'),
          content: Text(
            'Are you sure you want to delete ${_selectedTaskIds.length} tasks?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                taskProvider.deleteTasks(_selectedTaskIds.toList());
                _selectedTaskIds.clear(); // Clear selection after deletion
                _isMultiSelectionMode = false; // Exit multi-selection mode
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final tasks = taskProvider.tasks;

    return Column(
      children: [
        _isMultiSelectionMode
            ? _buildMultiSelectionAppBar(context, taskProvider)
            : _buildFilterBar(context, taskProvider, settingsProvider),
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
    );
  }

  Widget _buildMultiSelectionAppBar(
    BuildContext context,
    TaskProvider taskProvider,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleMultiSelectionMode,
      ),
      title: Text('${_selectedTaskIds.length} selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: _selectedTaskIds.isNotEmpty
              ? () => _deleteSelectedTasks(taskProvider)
              : null,
        ),
      ],
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
    final startFormatted = DateFormat(
      'MMM d, $timeFormat',
    ).format(task.startDate);
    final endFormatted = DateFormat('MMM d, $timeFormat').format(task.endDate);

    Color? cardColor;
    if (task.isFinished) {
      cardColor = const Color(0xFF2E7D32).withValues(alpha: 0.15);
    } else {
      final now = DateTime.now();
      final difference = task.endDate.difference(now).inDays;
      final isToday =
          task.endDate.year == now.year &&
          task.endDate.month == now.month &&
          task.endDate.day == now.day;

      if (isToday || difference < 1) {
        cardColor = const Color(0xFFB71C1C).withValues(alpha: 0.15);
      } else if (difference <= 3) {
        cardColor = const Color(0xFFFBC02D).withValues(alpha: 0.2);
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: cardColor,
      child: GestureDetector(
        onLongPress: () {
          _toggleMultiSelectionMode();
          _toggleTaskSelection(task.id);
        },
        onTap: () {
          if (_isMultiSelectionMode) {
            _toggleTaskSelection(task.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskEditScreen(task: task),
              ),
            );
          }
        },
        child: ListTile(
          leading: _isMultiSelectionMode
              ? Checkbox(
                  value: _selectedTaskIds.contains(task.id),
                  onChanged: (val) => _toggleTaskSelection(task.id),
                )
              : Checkbox(
                  value: task.isFinished,
                  onChanged: (val) => taskProvider.toggleTaskFinished(task.id),
                ),
          title: Row(
            children: [
              if (task.isLocked)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.lock, size: 16, color: Colors.grey),
                ),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: task.isFinished ? Colors.grey : null,
                  ),
                ),
              ),
            ],
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
                '$startFormatted - $endFormatted',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${task.status} | ${task.category}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          trailing: _isMultiSelectionMode
              ? null
              : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () =>
                      _confirmDelete(context, task.id, taskProvider),
                ),
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
