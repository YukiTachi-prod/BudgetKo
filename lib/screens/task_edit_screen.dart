import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import 'pdf_view_screen.dart';

class TaskEditScreen extends StatefulWidget {
  final Task? task;
  const TaskEditScreen({super.key, this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late String _selectedStatus;
  late String _selectedCategory;
  String? _pdfPath;
  bool _isPdfCopied = false;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedDate = widget.task?.date ?? DateTime.now();
    _selectedStatus =
        widget.task?.status ??
        (settings.statuses.isNotEmpty
            ? settings.statuses.first
            : 'Not Started');
    _selectedCategory =
        widget.task?.category ??
        (settings.categories.isNotEmpty
            ? settings.categories.first
            : 'General');
    _pdfPath = widget.task?.pdfPath;
    _isPdfCopied = widget.task?.isPdfCopied ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                taskProvider.deleteTask(widget.task!.id);
                Navigator.pop(context);
              },
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _saveTask),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date & Time'),
                subtitle: Text(
                  DateFormat(
                    settings.isTime24h
                        ? 'MMM d, yyyy HH:mm'
                        : 'MMM d, yyyy hh:mm a',
                  ).format(_selectedDate),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const Divider(),
              DropdownButtonFormField<String>(
                initialValue: settings.statuses.contains(_selectedStatus)
                    ? _selectedStatus
                    : (settings.statuses.isNotEmpty
                        ? settings.statuses.first
                        : null),
                items: settings.statuses
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: settings.statuses.isEmpty
                    ? null
                    : (val) => setState(() => _selectedStatus = val!),
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: const OutlineInputBorder(),
                  errorText: settings.statuses.isEmpty
                      ? 'Please add a status in Settings'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: settings.categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : (settings.categories.isNotEmpty
                        ? settings.categories.first
                        : null),
                items: settings.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: settings.categories.isEmpty
                    ? null
                    : (val) => setState(() => _selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: const OutlineInputBorder(),
                  errorText: settings.categories.isEmpty
                      ? 'Please add a category in Settings'
                      : null,
                ),
              ),              const Divider(),
              const Text(
                'Attachment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_pdfPath != null) ...[
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(p.basename(_pdfPath!)),
                  subtitle: Text(
                    _isPdfCopied ? 'Stored in App' : 'Linked from Device',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _pdfPath = null;
                      _isPdfCopied = false;
                    }),
                  ),
                  onTap: () {
                    if (File(_pdfPath!).existsSync()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewScreen(
                            path: _pdfPath!,
                            title: _titleController.text,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File no longer exists at this path'),
                        ),
                      );
                    }
                  },
                ),
              ] else
                ElevatedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('ATTACH PDF'),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  child: const Text('SAVE TASK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final originalPath = result.files.single.path!;

      if (settings.hidePdfReminder) {
        // Use default: Copy (safest)
        _applyPdfChoice(originalPath, true);
      } else {
        _showPdfReminder(originalPath);
      }
    }
  }

  void _showPdfReminder(String originalPath) {
    bool dontShowAgain = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Storage Choice'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How would you like to attach this PDF?'),
                  const SizedBox(height: 16),
                  const Text(
                    'Option 1: Copy to App',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '• Pro: Always accessible even if the original is moved.\n• Con: Increases app storage usage.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Option 2: Save Path',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '• Pro: No extra storage used.\n• Con: PDF won\'t open if you move or delete the original file.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (val) =>
                            setStateDialog(() => dontShowAgain = val!),
                      ),
                      const Text('Don\'t remind me again'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (dontShowAgain) {
                      Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).setHidePdfReminder(true);
                    }
                    Navigator.pop(context);
                    _applyPdfChoice(originalPath, false); // Save Path
                  },
                  child: const Text('SAVE PATH'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (dontShowAgain) {
                      Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).setHidePdfReminder(true);
                    }
                    Navigator.pop(context);
                    _applyPdfChoice(originalPath, true); // Copy
                  },
                  child: const Text('COPY TO APP'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _applyPdfChoice(String originalPath, bool copy) async {
    if (copy) {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(p.join(directory.path, 'task_pdfs'));
      if (!pdfDir.existsSync()) {
        pdfDir.createSync();
      }

      final fileName = p.basename(originalPath);
      final newPath = p.join(
        pdfDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      await File(originalPath).copy(newPath);
      setState(() {
        _pdfPath = newPath;
        _isPdfCopied = true;
      });
    } else {
      setState(() {
        _pdfPath = originalPath;
        _isPdfCopied = false;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descController.text,
        date: _selectedDate,
        status: _selectedStatus,
        category: _selectedCategory,
        pdfPath: _pdfPath,
        isPdfCopied: _isPdfCopied,
      );

      if (widget.task == null) {
        taskProvider.addTask(task);
      } else {
        taskProvider.updateTask(task);
      }
      Navigator.pop(context);
    }
  }
}
