import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/settings_provider.dart';
import 'status_pill.dart';
import 'category_tag.dart';

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

  Color _urgencyAccent() {
    if (task.isFinished) return const Color(0xFF10B981);
    final now = DateTime.now();
    final diff = task.endDate.difference(now).inDays;
    final isToday =
        task.endDate.year == now.year &&
        task.endDate.month == now.month &&
        task.endDate.day == now.day;
    if (diff < 0 || isToday) return const Color(0xFFEF4444);
    if (diff <= 3) return const Color(0xFFF59E0B);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final timeFormat = settings.isTime24h ? 'HH:mm' : 'h:mm a';
    final endLabel = DateFormat('MMM d · $timeFormat').format(task.endDate);
    final subtext = theme.colorScheme.secondary;
    final urgency = _urgencyAccent();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: theme.colorScheme.surface,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.06),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.03),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left urgency bar ───────────────────────────
                    Container(width: 4, color: urgency),

                    // ── Content ────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Checkbox
                            SizedBox(
                              width: 36,
                              child: Checkbox(
                                value: isMultiSelectionMode
                                    ? isSelected
                                    : task.isFinished,
                                onChanged: (_) => isMultiSelectionMode
                                    ? onTap()
                                    : onToggleFinished(),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Task info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title row
                                  Row(
                                    children: [
                                      if (task.isLocked) ...[
                                        Icon(
                                          Icons.lock_rounded,
                                          size: 11,
                                          color: subtext,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: task.isFinished
                                                ? subtext
                                                : theme.colorScheme.onSurface,
                                            decoration: task.isFinished
                                                ? TextDecoration.lineThrough
                                                : null,
                                            decorationColor: subtext,
                                          ),
                                        ),
                                      ),
                                      if (showRepeatBadge &&
                                          task.repeatInterval != null &&
                                          task.repeatInterval != 'None') ...[
                                        const SizedBox(width: 6),
                                        _RepeatBadge(
                                          interval: task.repeatInterval!,
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // Metadata
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      StatusPill(status: task.status),
                                      CategoryTag(category: task.category),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 11,
                                            color: subtext,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            endLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: subtext,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (task.description.isNotEmpty)
                                        Text(
                                          '· ${task.description}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subtext,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Delete
                            if (!isMultiSelectionMode)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                ),
                                onPressed: onDelete,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                color: subtext,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatBadge extends StatelessWidget {
  final String interval;
  const _RepeatBadge({required this.interval});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        interval,
        style: TextStyle(
          fontSize: 10,
          color: accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
