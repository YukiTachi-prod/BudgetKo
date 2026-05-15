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
  final String itemName; // e.g., "task" or "routine"

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
      if (!_isMultiSelectionMode) {
        _selectedTaskIds.clear();
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
          title: Text('Delete Selected ${widget.itemName}s'),
          content: Text(
            'Are you sure you want to delete ${_selectedTaskIds.length} ${widget.itemName}s?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                taskProvider.deleteTasks(_selectedTaskIds.toList());
                setState(() {
                  _selectedTaskIds.clear();
                  _isMultiSelectionMode = false;
                });
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, String id, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.itemName[0].toUpperCase()}${widget.itemName.substring(1)}'),
        content: Text('Are you sure you want to delete this ${widget.itemName}?'),
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

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Column(
      children: [
        if (_isMultiSelectionMode)
          AppBar(
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
          )
        else
          const FilterBar(),
        Expanded(
          child: widget.tasks.isEmpty
              ? Center(child: Text(widget.emptyMessage))
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
                              builder: (context) => TaskEditScreen(task: task),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_isMultiSelectionMode) {
                          _toggleMultiSelectionMode();
                        }
                        _toggleTaskSelection(task.id);
                      },
                      onToggleFinished: () =>
                          taskProvider.toggleTaskFinished(task.id),
                      onDelete: () =>
                          _confirmDelete(context, task.id, taskProvider),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
