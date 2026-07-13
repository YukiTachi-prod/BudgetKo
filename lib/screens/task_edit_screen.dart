import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/status_pill.dart';
import '../widgets/category_tag.dart';
import '../services/platform/platform_file_service.dart';
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
  late DateTime _startDate;
  late DateTime _endDate;
  late String _selectedStatus;
  late String _selectedCategory;
  String? _pdfPath;
  bool _isPdfCopied = false;
  bool _isLocked = false;
  bool _isAlarm = false;
  bool _hasDates = true;
  DateTime? _alarmTriggerDate;
  int? _ringIntervalValue;
  String _ringIntervalUnit = 'minutes';
  bool _enableRingInterval = false;

  static const Uuid _uuid = Uuid();
  final PlatformFileService _fileService = PlatformFileService();

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
    _isAlarm = widget.task?.isAlarm ?? false;
    _hasDates = widget.task?.hasDates ?? true;
    _alarmTriggerDate = widget.task?.alarmTriggerDate ?? DateTime.now();
    _ringIntervalValue = widget.task?.ringIntervalValue ?? 1;
    _ringIntervalUnit = widget.task?.ringIntervalUnit ?? 'minutes';
    _enableRingInterval = widget.task?.ringIntervalValue != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(bool isStart) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final initial = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      initialEntryMode: settings.useDialTimePicker
          ? TimePickerEntryMode.dial
          : TimePickerEntryMode.input,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(
          ctx,
        ).copyWith(alwaysUse24HourFormat: settings.isTime24h),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _startDate = dt;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
        }
      } else {
        _endDate = dt;
      }
    });
  }

  Future<void> _selectAlarmTriggerDateTime() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final date = await showDatePicker(
      context: context,
      initialDate: _alarmTriggerDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_alarmTriggerDate ?? DateTime.now()),
      initialEntryMode: settings.useDialTimePicker
          ? TimePickerEntryMode.dial
          : TimePickerEntryMode.input,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(
          ctx,
        ).copyWith(alwaysUse24HourFormat: settings.isTime24h),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _alarmTriggerDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      final task = Task(
        id: widget.task?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        hasDates: _hasDates,
        status: _selectedStatus,
        category: _selectedCategory,
        pdfPath: _pdfPath,
        isPdfCopied: _isPdfCopied,
        isFinished: widget.task?.isFinished ?? false,
        isLocked: _isLocked,
        isAlarm: _isAlarm,
        alarmTriggerDate: _alarmTriggerDate,
        ringIntervalValue: _enableRingInterval ? _ringIntervalValue : null,
        ringIntervalUnit: _enableRingInterval ? _ringIntervalUnit : null,
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

  Future<void> _pickPdf() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    if (result.files.single.path == null) return;
    final originalPath = result.files.single.path!;
    if (settings.hidePdfReminder) {
      _applyPdfChoice(originalPath, true);
    } else {
      _showPdfReminder(originalPath);
    }
  }

  void _showPdfReminder(String originalPath) {
    bool dontShowAgain = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Attach PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy to app storage (always available) or link the original path (no extra storage, breaks if file moves)?',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: dontShowAgain,
                    onChanged: (v) => setDialog(() => dontShowAgain = v!),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  const Text("Don't ask again", style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (dontShowAgain) {
                  Provider.of<SettingsProvider>(
                    ctx,
                    listen: false,
                  ).setHidePdfReminder(true);
                }
                Navigator.pop(ctx);
                _applyPdfChoice(originalPath, false);
              },
              child: const Text('Save path'),
            ),
            FilledButton(
              onPressed: () {
                if (dontShowAgain) {
                  Provider.of<SettingsProvider>(
                    ctx,
                    listen: false,
                  ).setHidePdfReminder(true);
                }
                Navigator.pop(ctx);
                _applyPdfChoice(originalPath, true);
              },
              child: const Text('Copy to app'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyPdfChoice(String originalPath, bool copy) async {
    if (copy) {
      final newPath = await _fileService.copyPdfToAppStorage(originalPath);
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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isLocked = _isLocked && widget.task != null;
    final theme = Theme.of(context);
    final subtext = theme.colorScheme.secondary;
    final fmt = settings.isTime24h ? 'MMM d · HH:mm' : 'MMM d · h:mm a';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New task' : 'Edit task'),
        actions: [
          if (widget.task != null && !isLocked)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: const Color(0xFFFF5252),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Task?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<TaskProvider>(
                            context,
                            listen: false,
                          ).deleteTask(widget.task!.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Color(0xFFFF5252)),
                        ),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Delete',
            ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveTask,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Lock notice ───────────────────────────────────
                  if (isLocked) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Locked — only status can be changed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Title ─────────────────────────────────────────
                  TextFormField(
                    controller: _titleController,
                    enabled: !isLocked,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                    decoration: InputDecoration(
                      hintText: 'Task title…',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: subtext.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Title required'
                        : null,
                  ),

                  // ── Description ───────────────────────────────────
                  TextFormField(
                    controller: _descController,
                    enabled: !isLocked,
                    maxLines: null,
                    style: TextStyle(fontSize: 14, color: subtext),
                    decoration: InputDecoration(
                      hintText: 'Add a description…',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: subtext.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 4),

                  // ── Properties ────────────────────────────────────
                  _PropRow(
                    icon: Icons.radio_button_checked_rounded,
                    label: 'Status',
                    child: Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          itemHeight: 56, // Bigger touch target
                          iconSize: 28,
                          onChanged: isLocked
                              ? null
                              : (v) {
                                  if (v != null) {
                                    setState(() => _selectedStatus = v);
                                  }
                                },
                          items: settings.statuses.map((s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: StatusPill(status: s),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  _PropRow(
                    icon: Icons.folder_outlined,
                    label: 'Category',
                    child: Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          itemHeight: 56, // Bigger touch target
                          iconSize: 28,
                          onChanged: isLocked
                              ? null
                              : (v) {
                                  if (v != null) {
                                    setState(() => _selectedCategory = v);
                                  }
                                },
                          items: settings.categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: CategoryTag(category: c),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 4),

                  _PropRow(
                    icon: Icons.calendar_today,
                    label: 'Include Dates',
                    child: Switch(
                      value: _hasDates,
                      onChanged: isLocked
                          ? null
                          : (v) => setState(() => _hasDates = v),
                    ),
                  ),

                  if (_hasDates) ...[
                    const SizedBox(height: 4),
                    // ── Dates ─────────────────────────────────────────
                    _PropRow(
                      icon: Icons.play_arrow_rounded,
                      label: 'Starts',
                      child: GestureDetector(
                        onTap: isLocked ? null : () => _selectDateTime(true),
                        child: Text(
                          DateFormat(fmt).format(_startDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: isLocked
                                ? subtext
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    _PropRow(
                      icon: Icons.stop_rounded,
                      label: 'Ends',
                      child: GestureDetector(
                        onTap: isLocked ? null : () => _selectDateTime(false),
                        child: Text(
                          DateFormat(fmt).format(_endDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: isLocked
                                ? subtext
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 4),

                  // ── Toggles ───────────────────────────────────────
                  _PropRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Lock task',
                    child: Switch(
                      value: _isLocked,
                      onChanged: (v) => setState(() => _isLocked = v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  const SizedBox(height: 2),

                  _PropRow(
                    icon: Icons.alarm_rounded,
                    label: 'Alarm',
                    child: Switch(
                      value: _isAlarm,
                      onChanged: isLocked
                          ? null
                          : (v) => setState(() => _isAlarm = v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_isAlarm) ...[
                    _PropRow(
                      icon: Icons.notifications_active_rounded,
                      label: 'Alarm Trigger',
                      child: GestureDetector(
                        onTap: isLocked
                            ? null
                            : () => _selectAlarmTriggerDateTime(),
                        child: Text(
                          DateFormat(fmt).format(_alarmTriggerDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: isLocked
                                ? subtext
                                : theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PropRow(
                      icon: Icons.repeat_rounded,
                      label: 'Repeat Alarm',
                      child: Switch(
                        value: _enableRingInterval,
                        onChanged: isLocked
                            ? null
                            : (v) => setState(() => _enableRingInterval = v),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    if (_enableRingInterval) ...[
                      const SizedBox(height: 8),
                      _PropRow(
                        icon: Icons.loop_rounded,
                        label: 'Ring every',
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: TextFormField(
                                initialValue: (_ringIntervalValue ?? 1)
                                    .toString(),
                                keyboardType: TextInputType.number,
                                enabled: !isLocked,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onChanged: (val) =>
                                    _ringIntervalValue = int.tryParse(val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _ringIntervalUnit,
                                isExpanded: false,
                                itemHeight: 56,
                                iconSize: 28,
                                onChanged: isLocked
                                    ? null
                                    : (v) {
                                        if (v != null) {
                                          setState(() => _ringIntervalUnit = v);
                                        }
                                      },
                                items:
                                    [
                                      'minutes',
                                      'hours',
                                      'days',
                                      'weeks',
                                      'months',
                                    ].map((unit) {
                                      return DropdownMenuItem<String>(
                                        value: unit,
                                        child: Text(
                                          unit,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: subtext,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  Divider(color: theme.dividerColor),
                  const SizedBox(height: 8),

                  // ── PDF Attachment ────────────────────────────────
                  _pdfPath != null
                      ? _PdfRow(
                          path: _pdfPath!,
                          isCopied: _isPdfCopied,
                          isLocked: isLocked,
                          taskTitle: _titleController.text,
                          onRemove: () => setState(() {
                            _pdfPath = null;
                            _isPdfCopied = false;
                          }),
                        )
                      : isLocked
                      ? const SizedBox.shrink()
                      : OutlinedButton.icon(
                          icon: const Icon(Icons.attach_file_rounded, size: 15),
                          label: const Text(
                            'Attach PDF',
                            style: TextStyle(fontSize: 13),
                          ),
                          onPressed: _pickPdf,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Property row ────────────────────────────────────────────────────
class _PropRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _PropRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final subtext = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Icon(icon, size: 14, color: subtext),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 13, color: subtext)),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ── PDF attachment row ───────────────────────────────────────────────
class _PdfRow extends StatelessWidget {
  final String path;
  final bool isCopied;
  final bool isLocked;
  final String taskTitle;
  final VoidCallback onRemove;

  const _PdfRow({
    required this.path,
    required this.isCopied,
    required this.isLocked,
    required this.taskTitle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filename = p.basename(path);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            size: 18,
            color: Color(0xFFFF5252),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final fileService = PlatformFileService();
                if (fileService.pdfFileExists(path)) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PdfViewScreen(path: path, title: taskTitle),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File no longer exists')),
                    );
                  }
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isCopied ? 'Stored in app' : 'Linked from device',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isLocked)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              color: theme.colorScheme.secondary,
            ),
        ],
      ),
    );
  }
}
