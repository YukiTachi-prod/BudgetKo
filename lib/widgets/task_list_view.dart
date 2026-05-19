import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/task_edit_screen.dart';
import 'task_tile.dart';
import 'filter_bar.dart';

class TaskListView extends StatefulWidget {
  final List<Task> tasks;
  final String emptyMessage;
  final bool showRepeatBadge;
  final String itemName;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.emptyMessage,
    this.showRepeatBadge = false,
    this.itemName = 'task',
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  bool _isMultiSelectionMode = false;
  final Set<String> _selectedTaskIds = {};

  void _toggleMultiSelectionMode() {
    setState(() {
      _isMultiSelectionMode = !_isMultiSelectionMode;
      if (!_isMultiSelectionMode) _selectedTaskIds.clear();
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

  void _deleteSelected(TaskProvider provider) {
    if (_selectedTaskIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_selectedTaskIds.length} ${widget.itemName}s?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTasks(_selectedTaskIds.toList());
              setState(() {
                _selectedTaskIds.clear();
                _isMultiSelectionMode = false;
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, TaskProvider provider) {
    final name =
        widget.itemName[0].toUpperCase() + widget.itemName.substring(1);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTask(id);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Selection bar / filter bar ───────────────────────────
        if (_isMultiSelectionMode)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: _toggleMultiSelectionMode,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  '${_selectedTaskIds.length} selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                  onPressed: _selectedTaskIds.isNotEmpty
                      ? () => _deleteSelected(provider)
                      : null,
                  color: _selectedTaskIds.isNotEmpty
                      ? const Color(0xFFFF5252)
                      : theme.colorScheme.secondary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          )
        else
          const FilterBar(),

        // ── Task list ────────────────────────────────────────────
        Expanded(
          child: widget.tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 40,
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.emptyMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.tasks.length,
                  itemBuilder: (context, index) {
                    final task = widget.tasks[index];
                    return TaskTile(
                      task: task,
                      isMultiSelectionMode: _isMultiSelectionMode,
                      isSelected: _selectedTaskIds.contains(task.id),
                      showRepeatBadge: widget.showRepeatBadge,
                      onTap: () {
                        if (_isMultiSelectionMode) {
                          _toggleTaskSelection(task.id);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskEditScreen(task: task),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_isMultiSelectionMode) _toggleMultiSelectionMode();
                        _toggleTaskSelection(task.id);
                      },
                      onToggleFinished: () =>
                          provider.toggleTaskFinished(task.id),
                      onDelete: () =>
                          _confirmDelete(context, task.id, provider),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
