import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyTime24h = 'time_24h';
  static const String _keyCategories = 'categories';
  static const String _keyStatuses = 'statuses';
  static const String _keyHidePdfReminder = 'hide_pdf_reminder';
  static const String _keyUseDialTimePicker = 'use_dial_time_picker';

  static const String _keyStatusColors = 'status_colors';
  static const String _keyAlarmSoundPath = 'alarm_sound_path';
  static const String _keyAlarmChannelId = 'alarm_channel_id';

  bool _isDarkMode = false;
  bool _isTime24h = false;
  bool _hidePdfReminder = false;
  bool _useDialTimePicker = false; // Default to numeric input
  String? _alarmSoundPath;
  String _alarmChannelId = 'task_alarms';
  List<String> _categories = ['Work', 'Personal', 'Shopping', 'Health'];
  List<String> _statuses = ['Not Started', 'Ongoing', 'Finished', 'Dropped'];
  Map<String, int> _statusColors = {
    'Not Started': Colors.grey.toARGB32(),
    'Ongoing': Colors.blue.toARGB32(),
    'Finished': Colors.green.toARGB32(),
    'Dropped': Colors.red.toARGB32(),
  };

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isTime24h => _isTime24h;
  bool get hidePdfReminder => _hidePdfReminder;
  bool get useDialTimePicker => _useDialTimePicker;
  List<String> get categories => _categories;
  List<String> get statuses => _statuses;
  Map<String, int> get statusColors => _statusColors;
  String? get alarmSoundPath => _alarmSoundPath;
  String get alarmChannelId => _alarmChannelId;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _isTime24h = prefs.getBool(_keyTime24h) ?? false;
    _hidePdfReminder = prefs.getBool(_keyHidePdfReminder) ?? false;
    _useDialTimePicker = prefs.getBool(_keyUseDialTimePicker) ?? false;
    _categories =
        prefs.getStringList(_keyCategories) ??
        ['Work', 'Personal', 'Shopping', 'Health'];
    _statuses =
        prefs.getStringList(_keyStatuses) ??
        ['Not Started', 'Ongoing', 'Finished', 'Dropped'];

    final colorsJson = prefs.getString(_keyStatusColors);
    if (colorsJson != null) {
      final decoded = jsonDecode(colorsJson) as Map<String, dynamic>;
      _statusColors = decoded.map((k, v) => MapEntry(k, v as int));
    } else {
      _statusColors = {
        'Not Started': Colors.grey.toARGB32(),
        'Ongoing': Colors.blue.toARGB32(),
        'Finished': Colors.green.toARGB32(),
        'Dropped': Colors.red.toARGB32(),
      };
    }

    _alarmSoundPath = prefs.getString(_keyAlarmSoundPath);
    _alarmChannelId = prefs.getString(_keyAlarmChannelId) ?? 'task_alarms';

    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> toggleTime24h(bool value) async {
    _isTime24h = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTime24h, value);
    notifyListeners();
  }

  Future<void> setHidePdfReminder(bool value) async {
    _hidePdfReminder = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHidePdfReminder, value);
    notifyListeners();
  }

  Future<void> toggleUseDialTimePicker(bool value) async {
    _useDialTimePicker = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseDialTimePicker, value);
    notifyListeners();
  }

  Future<void> setAlarmSoundPath(String? path) async {
    _alarmSoundPath = path;
    _alarmChannelId = 'task_alarms_${DateTime.now().millisecondsSinceEpoch}';
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyAlarmSoundPath);
    } else {
      await prefs.setString(_keyAlarmSoundPath, path);
    }
    await prefs.setString(_keyAlarmChannelId, _alarmChannelId);
    notifyListeners();
  }

  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      _categories.add(category);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyCategories, _categories);
      notifyListeners();
    }
  }

  Future<void> removeCategory(String category) async {
    _categories.remove(category);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCategories, _categories);
    notifyListeners();
  }

  Future<void> addStatus(String status) async {
    if (!_statuses.contains(status)) {
      _statuses.add(status);
      _statusColors[status] = Colors.blueGrey
          .toARGB32(); // Default color for new status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyStatuses, _statuses);
      await prefs.setString(_keyStatusColors, jsonEncode(_statusColors));
      notifyListeners();
    }
  }

  Future<void> removeStatus(String status) async {
    _statuses.remove(status);
    _statusColors.remove(status);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyStatuses, _statuses);
    await prefs.setString(_keyStatusColors, jsonEncode(_statusColors));
    notifyListeners();
  }

  Future<void> setStatusColor(String status, int colorValue) async {
    _statusColors[status] = colorValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStatusColors, jsonEncode(_statusColors));
    notifyListeners();
  }

  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isDarkMode = false;
    _isTime24h = false;
    _hidePdfReminder = false;
    _useDialTimePicker = false;
    _categories = ['Work', 'Personal', 'Shopping', 'Health'];
    _statuses = ['Not Started', 'Ongoing', 'Finished', 'Dropped'];
    _statusColors = {
      'Not Started': Colors.grey.toARGB32(),
      'Ongoing': Colors.blue.toARGB32(),
      'Finished': Colors.green.toARGB32(),
      'Dropped': Colors.red.toARGB32(),
    };
    notifyListeners();
  }
}
