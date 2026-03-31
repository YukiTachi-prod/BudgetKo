import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/import_export_service.dart';
import 'analytics_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    // This screen now provides only its content, without a Scaffold or AppBar.
    return ListView(
      children: [
        _buildSectionHeader('Appearance'),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Light: Creamy White, Dark: Dark Grey'),
          value: settings.isDarkMode,
          onChanged: (val) => settings.toggleDarkMode(val),
        ),
        SwitchListTile(
          title: const Text('24-Hour Format'),
          value: settings.isTime24h,
          onChanged: (val) => settings.toggleTime24h(val),
        ),
        SwitchListTile(
          title: const Text('Use Dial for Time Picker'),
          subtitle: const Text('Default: Numeric/Keyboard input'),
          value: settings.useDialTimePicker,
          onChanged: (val) => settings.toggleUseDialTimePicker(val),
        ),
        const Divider(),
        _buildSectionHeader('Analytics'),
        ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: const Text('View Analytics'),
          subtitle: const Text('Task status and category statistics'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          ),
        ),
        const Divider(),
        _buildSectionHeader('Data Management'),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Import Tasks'),
          subtitle: const Text('Import from ZIP file'),
          onTap: () => _handleImport(context, taskProvider, settings),
        ),
        ListTile(
          leading: const Icon(Icons.upload),
          title: const Text('Export Tasks'),
          subtitle: const Text('Export to ZIP file'),
          onTap: () => _handleExport(context, taskProvider),
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: const Text('Share Tasks'),
          subtitle: const Text('Send tasks via Messenger or other apps'),
          onTap: () => _handleShare(context, taskProvider),
        ),
        const Divider(),
        _buildSectionHeader('Categories'),
        ...settings.categories.map(
          (c) => ListTile(
            title: Text(c),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => settings.removeCategory(c),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Category'),
          onTap: () =>
              _showAddDialog(context, 'Category', settings.addCategory),
        ),
        const Divider(),
        _buildSectionHeader('Statuses'),
        ...settings.statuses.map(
          (p) => ListTile(
            title: Text(p),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(
                context,
                'Status',
                p,
                () => settings.removeStatus(p),
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Status'),
          onTap: () => _showAddDialog(context, 'Status', settings.addStatus),
        ),
        const Divider(),
        _buildSectionHeader('Danger Zone'),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text(
            'Delete All Data',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () => _showDeleteAllDialog(context, settings, taskProvider),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String type,
    String name,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $type'),
        content: Text('Are you sure you want to delete the "$name" $type?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    String title,
    Function(String) onAdd,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter $title name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(
    BuildContext context,
    SettingsProvider settings,
    TaskProvider taskProvider,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This will delete ALL tasks and reset ALL settings. This action cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  const Text('Type "confirm" to proceed:'),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'confirm'),
                    onChanged: (val) => setState(() {}),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: controller.text == 'confirm'
                      ? () async {
                          await taskProvider.clearAllTasks();
                          await settings.resetAllSettings();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All data cleared successfully'),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    'DELETE',
                    style: TextStyle(
                      color: controller.text == 'confirm'
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleImport(
    BuildContext context,
    TaskProvider taskProvider,
    SettingsProvider settingsProvider,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final service = ImportExportService();

      try {
        final importedTasks = await service.importFromZip(bytes);
        if (importedTasks.isNotEmpty && context.mounted) {
          // Add new categories and statuses to settings
          for (final task in importedTasks) {
            settingsProvider.addCategory(task.category);
            settingsProvider.addStatus(task.status);
          }
          taskProvider.importTasks(importedTasks);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${importedTasks.length} tasks')),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid tasks found in ZIP')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
        }
      }
    }
  }

  Future<void> _handleExport(
    BuildContext context,
    TaskProvider taskProvider,
  ) async {
    if (taskProvider.tasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tasks to export')));
      return;
    }

    final service = ImportExportService();
    final bytes = service.exportToZip(taskProvider.tasks);

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/tasks_export.zip';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tasks exported to $filePath')));
    }
  }

  Future<void> _handleShare(
    BuildContext context,
    TaskProvider taskProvider,
  ) async {
    if (taskProvider.tasks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tasks to share')));
      return;
    }

    final service = ImportExportService();
    final bytes = service.exportToZip(taskProvider.tasks);

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/tasks_share.zip';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      final result = await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Sharing my Tasker data');

      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Shared successfully')));
        }
      }
    }
  }
}
