import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

void insertTestTasks(
  TaskProvider taskProvider,
  List<String> availableCategories,
  List<String> availableStatuses,
) {
  final random = Random();
  const uuid = Uuid();
  final newTasks = <Task>[];

  final now = DateTime.now();

  for (int i = 0; i < 50; i++) {
    final daysOffset = random.nextInt(60) - 30;
    final startDate = now.add(Duration(days: daysOffset));
    final endDate = startDate.add(Duration(hours: random.nextInt(48) + 1));

    final category = availableCategories.isNotEmpty
        ? availableCategories[random.nextInt(availableCategories.length)]
        : 'Work';

    final status = availableStatuses.isNotEmpty
        ? availableStatuses[random.nextInt(availableStatuses.length)]
        : 'Not Started';

    newTasks.add(
      Task(
        id: uuid.v4(),
        title: 'Generated Task ${uuid.v4().substring(0, 8)}',
        description: 'This is an automatically generated test task.',
        startDate: startDate,
        endDate: endDate,
        category: category,
        status: status,
        isFinished: status == 'Finished',
      ),
    );
  }

  taskProvider.importTasks(newTasks);
}
