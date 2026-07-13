import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = Provider.of<TaskProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final subtext = theme.colorScheme.secondary;
    final border = theme.dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Date chip
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'all') {
                  tasks.setFilterDate(null);
                  tasks.setFilterDateRange(null);
                } else if (val == 'specific') {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tasks.filterDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    tasks.setFilterDateRange(null);
                    tasks.setFilterDate(date);
                  }
                } else if (val == 'range') {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: tasks.filterDateRange,
                  );
                  if (range != null) {
                    tasks.setFilterDate(null);
                    tasks.setFilterDateRange(range);
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Text(
                    'All dates',
                    style: TextStyle(color: subtext, fontSize: 13),
                  ),
                ),
                const PopupMenuItem(
                  value: 'specific',
                  child: Text('Specific date', style: TextStyle(fontSize: 13)),
                ),
                const PopupMenuItem(
                  value: 'range',
                  child: Text('Date Range', style: TextStyle(fontSize: 13)),
                ),
              ],
              child: _FilterPill(
                icon: Icons.calendar_today_rounded,
                label: tasks.filterDate != null
                    ? DateFormat('MMM d, yyyy').format(tasks.filterDate!)
                    : (tasks.filterDateRange != null
                          ? '${DateFormat('MMM d').format(tasks.filterDateRange!.start)} - ${DateFormat('MMM d').format(tasks.filterDateRange!.end)}'
                          : 'All dates'),
                isActive:
                    tasks.filterDate != null || tasks.filterDateRange != null,
                onClear:
                    (tasks.filterDate != null || tasks.filterDateRange != null)
                    ? () {
                        tasks.setFilterDate(null);
                        tasks.setFilterDateRange(null);
                      }
                    : null,
              ),
            ),

            const SizedBox(width: 8),

            // Category popup
            PopupMenuButton<String?>(
              initialValue: tasks.filterCategory,
              onSelected: (val) =>
                  tasks.setFilterCategory(val == '__all__' ? null : val),
              itemBuilder: (context) => [
                PopupMenuItem<String?>(
                  value: '__all__',
                  child: Text(
                    'All categories',
                    style: TextStyle(color: subtext, fontSize: 13),
                  ),
                ),
                ...settings.categories.map(
                  (c) => PopupMenuItem<String?>(
                    value: c,
                    child: Text(c, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              child: _FilterPill(
                icon: Icons.folder_open_rounded,
                label: tasks.filterCategory ?? 'All categories',
                isActive: tasks.filterCategory != null,
                onClear: tasks.filterCategory != null
                    ? () => tasks.setFilterCategory(null)
                    : null,
              ),
            ),

            const SizedBox(width: 8),

            // Status popup
            PopupMenuButton<String?>(
              initialValue: tasks.filterStatus,
              onSelected: (val) =>
                  tasks.setFilterStatus(val == '__all__' ? null : val),
              itemBuilder: (context) => [
                PopupMenuItem<String?>(
                  value: '__all__',
                  child: Text(
                    'All statuses',
                    style: TextStyle(color: subtext, fontSize: 13),
                  ),
                ),
                ...settings.statuses.map(
                  (s) => PopupMenuItem<String?>(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              child: _FilterPill(
                icon: Icons.radio_button_checked_rounded,
                label: tasks.filterStatus ?? 'All statuses',
                isActive: tasks.filterStatus != null,
                onClear: tasks.filterStatus != null
                    ? () => tasks.setFilterStatus(null)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onClear;

  const _FilterPill({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final subtext = theme.colorScheme.secondary;
    final color = isActive ? accent : subtext;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? accent.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive ? accent.withValues(alpha: 0.4) : theme.dividerColor,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded, size: 12, color: color),
            ),
          ],
        ],
      ),
    );
  }
}
