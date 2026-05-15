import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final bool isMultiSelectionMode;
  final bool isSelected;
  final bool showRepeatBadge;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFinished;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.isMultiSelectionMode,
    required this.isSelected,
    this.showRepeatBadge = false,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFinished,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final timeFormat = settingsProvider.isTime24h ? 'HH:mm' : 'hh:mm a';
    final startFormatted = DateFormat('MMM d, $timeFormat').format(task.startDate);
    final endFormatted = DateFormat('MMM d, $timeFormat').format(task.endDate);

    Color? cardColor;
    if (task.isFinished) {
      cardColor = const Color(0xFF2E7D32).withValues(alpha: 0.15);
    } else {
      final now = DateTime.now();
      final difference = task.endDate.difference(now).inDays;
      final isToday = task.endDate.year == now.year &&
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
        onLongPress: onLongPress,
        onTap: onTap,
        child: ListTile(
          leading: isMultiSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                )
              : Checkbox(
                  value: task.isFinished,
                  onChanged: (_) => onToggleFinished(),
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
              if (showRepeatBadge &&
                  task.repeatInterval != null &&
                  task.repeatInterval != 'None')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.repeatInterval!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
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
          trailing: isMultiSelectionMode
              ? null
              : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
        ),
      ),
    );
  }
}
