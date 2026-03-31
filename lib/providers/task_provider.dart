import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  static const String _keyTasks = 'tasks';
  List<Task> _tasks = [];
  DateTime? _filterDate;
  String? _filterStatus;
  String? _filterCategory;
  final NotificationService _notificationService = NotificationService();

  TaskProvider() {
    _loadTasks();
  }

  List<Task> get tasks {
    List<Task> filtered = _tasks.where((t) => !t.isRoutine).toList();
    if (_filterDate != null) {
      filtered = filtered
          .where(
            (t) =>
                t.endDate.year == _filterDate!.year &&
                t.endDate.month == _filterDate!.month &&
                t.endDate.day == _filterDate!.day,
          )
          .toList();
    }
    if (_filterStatus != null && _filterStatus != 'All') {
      filtered = filtered.where((t) => t.status == _filterStatus).toList();
    }
    if (_filterCategory != null && _filterCategory != 'All') {
      filtered = filtered.where((t) => t.category == _filterCategory).toList();
    }
    return filtered;
  }

  List<Task> get routines {
    List<Task> filtered = _tasks.where((t) => t.isRoutine).toList();
    // Maybe apply same filters to routines? Usually routines are less about dates.
    // The user said "exactly like dashboard", so let's apply filters.
    if (_filterDate != null) {
      filtered = filtered
          .where(
            (t) =>
                t.endDate.year == _filterDate!.year &&
                t.endDate.month == _filterDate!.month &&
                t.endDate.day == _filterDate!.day,
          )
          .toList();
    }
    if (_filterStatus != null && _filterStatus != 'All') {
      filtered = filtered.where((t) => t.status == _filterStatus).toList();
    }
    if (_filterCategory != null && _filterCategory != 'All') {
      filtered = filtered.where((t) => t.category == _filterCategory).toList();
    }
    return filtered;
  }

  DateTime? get filterDate => _filterDate;
  String? get filterStatus => _filterStatus;
  String? get filterCategory => _filterCategory;
  List<Task> get allTasks => _tasks;

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_keyTasks);
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((item) => Task.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTasks, encoded);
  }

  bool isTitleUnique(String title, {String? excludeTaskId}) {
    return _tasks.every(
      (task) =>
          task.title.toLowerCase() != title.toLowerCase() ||
          task.id == excludeTaskId,
    );
  }

  void deleteTasks(List<String> ids) {
    for (final id in ids) {
      final taskToDelete = _tasks.firstWhere(
        (task) => task.id == id,
        orElse: () => throw Exception('Task not found for deletion'),
      );
      _notificationService.cancelTaskNotifications(taskToDelete.id);
      if (taskToDelete.pdfPath != null && taskToDelete.isPdfCopied) {
        final file = File(taskToDelete.pdfPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }
    _tasks.removeWhere((task) => ids.contains(task.id));
    _saveTasks();
    notifyListeners();
  }

  void addTask(Task task) {
    if (!isTitleUnique(task.title)) {
      throw ArgumentError(
        'Task with this title already exists.',
      ); 
    }
    // Ensure status consistency
    if (task.status == 'Finished' && !task.isFinished) {
      task = task.copyWith(isFinished: true);
    } else if (task.isFinished && task.status != 'Finished') {
      task = task.copyWith(status: 'Finished');
    }

    _tasks.add(task);
    _saveTasks();
    _notificationService.scheduleTaskReminders(task);
    notifyListeners();
  }

  void importTasks(List<Task> newTasks) {
    for (var i = 0; i < newTasks.length; i++) {
      if (newTasks[i].status == 'Finished' && !newTasks[i].isFinished) {
        newTasks[i] = newTasks[i].copyWith(isFinished: true);
      } else if (newTasks[i].isFinished && newTasks[i].status != 'Finished') {
        newTasks[i] = newTasks[i].copyWith(status: 'Finished');
      }
    }
    _tasks.addAll(newTasks);
    _saveTasks();
    for (final task in newTasks) {
      _notificationService.scheduleTaskReminders(task);
    }
    notifyListeners();
  }

  void updateTask(Task task) {
    if (!isTitleUnique(task.title, excludeTaskId: task.id)) {
      throw ArgumentError(
        'Task with this title already exists.',
      );
    }
    // Ensure status consistency
    if (task.status == 'Finished' && !task.isFinished) {
      task = task.copyWith(isFinished: true);
    } else if (task.isFinished && task.status != 'Finished') {
      task = task.copyWith(status: 'Finished');
    }

    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveTasks();
      _notificationService.scheduleTaskReminders(task);
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    if (task.pdfPath != null && task.isPdfCopied) {
      final file = File(task.pdfPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    _tasks.removeWhere((t) => t.id == id);
    _saveTasks();
    _notificationService.cancelTaskNotifications(id);
    notifyListeners();
  }

  void toggleTaskFinished(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final newFinished = !task.isFinished;
      _tasks[index] = task.copyWith(
        isFinished: newFinished,
        status: newFinished
            ? 'Finished'
            : (task.status == 'Finished' ? 'Ongoing' : task.status),
      );
      _saveTasks();
      _notificationService.scheduleTaskReminders(_tasks[index]);
      notifyListeners();
    }
  }

  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void setFilterStatus(String? status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _filterDate = null;
    _filterStatus = null;
    _filterCategory = null;
    notifyListeners();
  }

  Future<void> clearAllTasks() async {
    for (final task in _tasks) {
      _notificationService.cancelTaskNotifications(task.id);
      if (task.pdfPath != null && task.isPdfCopied) {
        final file = File(task.pdfPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    }
    _tasks.clear();
    await _saveTasks();
    notifyListeners();
  }
}
