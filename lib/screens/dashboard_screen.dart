import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_list_view.dart';
import '../widgets/transition_placeholder.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context).tasks;
    return TransitionPlaceholder(
      child: TaskListView(
        tasks: tasks,
        emptyMessage: 'No tasks yet — tap + to add one',
      ),
    );
  }
}
