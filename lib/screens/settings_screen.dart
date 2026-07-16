import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../utils/test_data_script.dart';
import '../services/import_export_service.dart';
import '../providers/ledger_provider.dart';
import 'analytics_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../services/platform/platform_file_service.dart';
import '../services/notification/notification_service.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          ListTile(
            title: const Text('Default Main Screen'),
            subtitle: const Text('Choose what opens when the app starts'),
            trailing: DropdownButton<String>(
              value: settings.defaultMainScreen,
              onChanged: (val) {
                if (val != null) {
                  settings.setDefaultMainScreen(val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'Notes', child: Text('Notes')),
                DropdownMenuItem(value: 'Wallet', child: Text('Wallet')),
              ],
            ),
          ),
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
          ListTile(
            title: const Text('Button Color Scheme'),
            subtitle: const Text(
              'Customize the accent/button color for the app',
            ),
            trailing: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    Color selectedColor = settings.themeColor != null
                        ? Color(settings.themeColor!)
                        : const Color(0xFF7C3AED); // default violet
                    return AlertDialog(
                      title: const Text('Choose Color Scheme'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: selectedColor,
                          onColorChanged: (c) => selectedColor = c,
                          pickerAreaHeightPercent: 0.8,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            settings.setThemeColor(null);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset Default'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            settings.setThemeColor(selectedColor.toARGB32());
                            Navigator.pop(ctx);
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: settings.themeColor != null
                      ? Color(settings.themeColor!)
                      : const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            ),
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
          Container(
            constraints: const BoxConstraints(maxHeight: 56.0 * 4),
            child: ListView(
              shrinkWrap: true,
              children: settings.categories
                  .map(
                    (c) => ListTile(
                      title: Text(c),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => settings.removeCategory(c),
                      ),
                    ),
                  )
                  .toList(),
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
          Container(
            constraints: const BoxConstraints(maxHeight: 56.0 * 4),
            child: ListView(
              shrinkWrap: true,
              children: settings.statuses
                  .map(
                    (p) => ListTile(
                      leading: GestureDetector(
                        onTap: () => _showColorPicker(context, settings, p),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(
                              settings.statusColors[p] ??
                                  Colors.grey.toARGB32(),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
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
                  )
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Status'),
            onTap: () => _showAddDialog(context, 'Status', settings.addStatus),
          ),
          const Divider(),
          _buildSectionHeader('Notifications'),
          ListTile(
            leading: const Icon(Icons.music_note, color: Colors.blue),
            title: const Text('Custom Alarm Sound'),
            subtitle: Text(
              settings.alarmSoundPath == null
                  ? 'Default sound\n(Note: Accepts .wav only. Custom sounds are not included in data export.)'
                  : 'Custom: ${settings.alarmSoundPath!.split('/').last}\n(Note: Accepts .wav only. Custom sounds are not included in data export.)',
            ),
            onTap: () async {
              final result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['wav'],
              );
              if (result != null && result.files.single.path != null) {
                final fileService = PlatformFileService();
                final fileName = result.files.single.name;
                final savedFilePath = await fileService.copyFileToAppStorage(
                  result.files.single.path!,
                  fileName,
                );
                await settings.setAlarmSoundPath(savedFilePath);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alarm sound updated!')),
                  );
                }
              }
            },
            trailing: settings.alarmSoundPath != null
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () {
                      settings.setAlarmSoundPath(null);
                    },
                  )
                : null,
          ),
          const Divider(),
          _buildSectionHeader('Developer Settings'),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
            title: const Text('Developer Options'),
            onTap: () => _showDeveloperPasswordDialog(context),
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
      ),
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

  void _showColorPicker(
    BuildContext context,
    SettingsProvider settings,
    String status,
  ) {
    Color selectedColor = Color(
      settings.statusColors[status] ?? Colors.grey.toARGB32(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select color for $status'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final colorVal = selectedColor.toARGB32();
                String? duplicateStatus;
                for (var e in settings.statusColors.entries) {
                  if (e.key != status && e.value == colorVal) {
                    duplicateStatus = e.key;
                    break;
                  }
                }

                if (duplicateStatus != null) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Duplicate Color'),
                      content: Text(
                        'This color is already used by "$duplicateStatus". Continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            settings.setStatusColor(status, colorVal);
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Okay'),
                        ),
                      ],
                    ),
                  );
                } else {
                  settings.setStatusColor(status, colorVal);
                  Navigator.pop(context);
                }
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null) {
      final bytes = await result.xFiles.first.readAsBytes();
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
    final fileService = PlatformFileService();

    try {
      final filePath = await fileService.saveExportZip(
        bytes,
        'tasks_export.zip',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Tasks exported to $filePath')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
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
    final fileService = PlatformFileService();

    try {
      await fileService.shareZip(bytes, 'tasks_share.zip');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  void _showDeveloperPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text == 'jaceywashere') {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeveloperOptionsScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Incorrect Password')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

class DeveloperOptionsScreen extends StatelessWidget {
  const DeveloperOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final ledgerProvider = Provider.of<LedgerProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Options')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Send Immediate Notification'),
            onTap: () async {
              await NotificationService().showImmediateNotification(
                'Test Notification',
                'This is an immediate test notification triggered manually.',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification sent!')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Schedule Notification (15s)'),
            subtitle: const Text(
              'Sends a notification in 15 seconds so you can close the app to test.',
            ),
            onTap: () async {
              await NotificationService().scheduleTestNotification(15);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notification scheduled in 15s. Close the app now!',
                    ),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm_on),
            title: const Text('Send Immediate Alarm'),
            onTap: () async {
              await NotificationService().showImmediateNotification(
                'Test Alarm',
                'This is an immediate test alarm triggered manually.',
                isAlarm: true,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Alarm sent!')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Schedule Alarm (15s)'),
            subtitle: const Text(
              'Sends an alarm in 15 seconds so you can close the app to test.',
            ),
            onTap: () async {
              await NotificationService().scheduleTestNotification(
                15,
                isAlarm: true,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alarm scheduled in 15s. Close the app now!'),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.purple),
            title: const Text('Insert 50 Test Tasks'),
            onTap: () {
              insertTestTasks(
                taskProvider,
                settings.categories,
                settings.statuses,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('50 test tasks generated!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Colors.blue),
            title: const Text('Insert Mock Analytics'),
            onTap: () async {
              await ledgerProvider.insertMockAnalytics();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mock analytics inserted!')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('Remove Mock Analytics'),
            onTap: () async {
              await ledgerProvider.removeMockAnalytics();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mock analytics removed!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
