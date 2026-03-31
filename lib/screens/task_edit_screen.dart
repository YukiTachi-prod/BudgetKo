import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedStatus;
  late String _selectedCategory;
  String? _pdfPath;
  bool _isPdfCopied = false;
  bool _isLocked = false;
  bool _isRoutine = false;
  String _repeatInterval = 'Daily';

  static const Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _startDate = widget.task?.startDate ?? DateTime.now();
    _endDate =
        widget.task?.endDate ?? DateTime.now().add(const Duration(hours: 1));
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
    _isLocked = widget.task?.isLocked ?? false;
    _isRoutine = widget.task?.isRoutine ?? false;
    _repeatInterval = widget.task?.repeatInterval ?? 'Daily';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStart) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final initialDate = isStart ? _startDate : _endDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        initialEntryMode: settings.useDialTimePicker
            ? TimePickerEntryMode.dial
            : TimePickerEntryMode.input,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(alwaysUse24HourFormat: settings.isTime24h),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startDate = newDateTime;
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(hours: 1));
            }
          } else {
            _endDate = newDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isEditingLocked = _isLocked && widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        actions: [
          if (widget.task != null && !isEditingLocked)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Provider.of<TaskProvider>(
                  context,
                  listen: false,
                ).deleteTask(widget.task!.id);
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
              if (isEditingLocked)
                const Card(
                  color: Colors.amber,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This task is locked. Only status can be changed.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TextFormField(
                controller: _titleController,
                enabled: !isEditingLocked,
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
                enabled: !isEditingLocked,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Starts',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat(
                          settings.isTime24h
                              ? 'MMM d, HH:mm'
                              : 'MMM d, hh:mm a',
                        ).format(_startDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: isEditingLocked
                          ? null
                          : () => _selectDateTime(true),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  Expanded(
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 16),
                      title: const Text(
                        'Ends',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat(
                          settings.isTime24h
                              ? 'MMM d, HH:mm'
                              : 'MMM d, hh:mm a',
                        ).format(_endDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: isEditingLocked
                          ? null
                          : () => _selectDateTime(false),
                    ),
                  ),
                ],
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
                onChanged: isEditingLocked || settings.categories.isEmpty
                    ? null
                    : (val) => setState(() => _selectedCategory = val!),
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: const OutlineInputBorder(),
                  errorText: settings.categories.isEmpty
                      ? 'Please add a category in Settings'
                      : null,
                ),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lock Task'),
                subtitle: const Text('Prevents further editing of details'),
                value: _isLocked,
                onChanged: (val) => setState(() => _isLocked = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as Routine'),
                subtitle: const Text('Appears in the Routines tab'),
                value: _isRoutine,
                onChanged: isEditingLocked
                    ? null
                    : (val) => setState(() => _isRoutine = val),
              ),
              if (_isRoutine)
                DropdownButtonFormField<String>(
                  initialValue: _repeatInterval,
                  decoration: const InputDecoration(
                    labelText: 'Repeat Interval',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Daily', 'Weekly', 'Monthly']
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: isEditingLocked
                      ? null
                      : (val) => setState(() => _repeatInterval = val!),
                ),
              const Divider(),
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
                  trailing: isEditingLocked
                      ? null
                      : IconButton(
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
              ] else if (!isEditingLocked)
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
                      const Text("Don't remind me again"),
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
      try {
        final task = Task(
          id: widget.task?.id ?? _uuid.v4(),
          title: _titleController.text,
          description: _descController.text,
          startDate: _startDate,
          endDate: _endDate,
          status: _selectedStatus,
          category: _selectedCategory,
          pdfPath: _pdfPath,
          isPdfCopied: _isPdfCopied,
          isFinished: widget.task?.isFinished ?? false,
          isLocked: _isLocked,
          isRoutine: _isRoutine,
          repeatInterval: _isRoutine ? _repeatInterval : null,
        );

        if (widget.task == null) {
          taskProvider.addTask(task);
        } else {
          taskProvider.updateTask(task);
        }
        Navigator.pop(context);
      } on ArgumentError catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
