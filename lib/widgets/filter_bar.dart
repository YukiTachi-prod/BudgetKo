import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                taskProvider.filterDate == null
                    ? 'All Dates'
                    : DateFormat('MMM d, yyyy').format(taskProvider.filterDate!),
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: taskProvider.filterDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                taskProvider.setFilterDate(date);
              },
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: taskProvider.filterStatus ?? 'All',
            decoration: const InputDecoration(
              labelText: 'Filter by Status',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['All', ...settingsProvider.statuses].map((p) {
              return DropdownMenuItem(value: p, child: Text(p));
            }).toList(),
            onChanged: (val) =>
                taskProvider.setFilterStatus(val == 'All' ? null : val),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: taskProvider.filterCategory ?? 'All',
            decoration: const InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['All', ...settingsProvider.categories].map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (val) =>
                taskProvider.setFilterCategory(val == 'All' ? null : val),
          ),
        ],
      ),
    );
  }
}
