import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_list_view.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).routines;
    return TaskListView(
      tasks: tasks,
      emptyMessage: 'No routines yet — tap + to add one',
      showRepeatBadge: true,
      itemName: 'routine',
    );
  }
}
