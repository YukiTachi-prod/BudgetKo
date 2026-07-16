import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/transition_placeholder.dart';

class DtrScreen extends StatefulWidget {
  const DtrScreen({super.key});

  @override
  State<DtrScreen> createState() => _DtrScreenState();
}

class _DtrScreenState extends State<DtrScreen> {
  String _filter = 'All'; // 'All', 'Weekly', 'Monthly'

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddDtrEntryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final dtrTasks = provider.allTasks
        .where((t) => t.category == 'DTR')
        .toList();

    // Sort descending by date
    dtrTasks.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Filter logic
    final now = DateTime.now();
    final filteredTasks = dtrTasks.where((t) {
      if (_filter == 'Weekly') {
        return now.difference(t.startDate).inDays < 7;
      } else if (_filter == 'Monthly') {
        return now.difference(t.startDate).inDays < 30;
      }
      return true;
    }).toList();

    // Calculate total hours for the filtered view
    double totalHours = 0.0;
    for (final t in filteredTasks) {
      totalHours += t.endDate.difference(t.startDate).inMinutes / 60.0;
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Time Record'),
        actions: [
          DropdownButton<String>(
            value: _filter,
            items: [
              'All',
              'Weekly',
              'Monthly',
            ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _filter = v);
            },
            underline: const SizedBox(),
            icon: const Icon(Icons.filter_list),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TransitionPlaceholder(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Hours ($_filter):',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    totalHours.toStringAsFixed(2),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredTasks.isEmpty
                  ? const Center(child: Text('No DTR entries found.'))
                  : ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        final duration = task.endDate.difference(
                          task.startDate,
                        );
                        final hours = duration.inMinutes / 60.0;

                        return ExpansionTile(
                          title: Text(task.title), // Entry #1
                          subtitle: Text(
                            DateFormat('MMM d, yyyy').format(task.startDate),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Time In: ${DateFormat('hh:mm a').format(task.startDate)}',
                                      ),
                                      Text(
                                        'Time Out: ${DateFormat('hh:mm a').format(task.endDate)}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total Hours: ${hours.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Remarks: ${task.description.isEmpty ? "None" : task.description}',
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed: () {
                                        provider.deleteTask(task.id);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

class _AddDtrEntryDialog extends StatefulWidget {
  const _AddDtrEntryDialog();

  @override
  State<_AddDtrEntryDialog> createState() => _AddDtrEntryDialogState();
}

class _AddDtrEntryDialogState extends State<_AddDtrEntryDialog> {
  DateTime _date = DateTime.now();
  TimeOfDay _timeIn = TimeOfDay.now();
  TimeOfDay _timeOut = TimeOfDay.now();
  final TextEditingController _remarksCtrl = TextEditingController();

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isIn) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isIn ? _timeIn : _timeOut,
    );
    if (t != null) {
      setState(() {
        if (isIn) {
          _timeIn = t;
        } else {
          _timeOut = t;
        }
      });
    }
  }

  void _save() {
    final provider = context.read<TaskProvider>();
    final dtrCount = provider.allTasks.where((t) => t.category == 'DTR').length;
    final title = 'Entry #${dtrCount + 1}';

    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _timeIn.hour,
      _timeIn.minute,
    );
    var end = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _timeOut.hour,
      _timeOut.minute,
    );
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1)); // Handle overnight shift
    }

    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: _remarksCtrl.text,
      startDate: start,
      endDate: end,
      status: 'Finished',
      category: 'DTR',
      isLocked: true,
    );

    provider.addTask(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New DTR Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(_date)}',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => setState(() => _date = DateTime.now()),
                  child: const Text('Today'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _pickDate,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Time In: ${_timeIn.format(context)}')),
                FilledButton.tonal(
                  onPressed: () => setState(() => _timeIn = TimeOfDay.now()),
                  child: const Text('Now'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _pickTime(true),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('Time Out: ${_timeOut.format(context)}')),
                FilledButton.tonal(
                  onPressed: () => setState(() => _timeOut = TimeOfDay.now()),
                  child: const Text('Now'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _pickTime(false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
