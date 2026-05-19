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
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: const Color(0xFF6D28D9).withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status chips (horizontal scroll) ────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _StatusChip(
                  label: 'All',
                  isSelected: tasks.filterStatus == null,
                  onTap: () => tasks.setFilterStatus(null),
                ),
                ...settings.statuses.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _StatusChip(
                      label: s,
                      isSelected: tasks.filterStatus == s,
                      onTap: () => tasks.setFilterStatus(s),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Date + Category row ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                // Date chip
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: tasks.filterDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    tasks.setFilterDate(date);
                  },
                  child: _FilterPill(
                    icon: Icons.calendar_today_rounded,
                    label: tasks.filterDate == null
                        ? 'All dates'
                        : DateFormat('MMM d, yyyy').format(tasks.filterDate!),
                    isActive: tasks.filterDate != null,
                    onClear: tasks.filterDate != null
                        ? () => tasks.setFilterDate(null)
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.5)
                : theme.dividerColor,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? accent : theme.colorScheme.secondary,
          ),
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
        color: isActive
            ? accent.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
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
