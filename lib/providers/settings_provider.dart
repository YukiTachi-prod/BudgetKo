import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyTime24h = 'time_24h';
  static const String _keyCategories = 'categories';
  static const String _keyStatuses = 'statuses';
  static const String _keyHidePdfReminder = 'hide_pdf_reminder';

  bool _isDarkMode = false;
  bool _isTime24h = false;
  bool _hidePdfReminder = false;
  List<String> _categories = ['Work', 'Personal', 'Shopping', 'Health'];
  List<String> _statuses = ['Not Started', 'Ongoing', 'Finished', 'Dropped'];

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  bool get isTime24h => _isTime24h;
  bool get hidePdfReminder => _hidePdfReminder;
  List<String> get categories => _categories;
  List<String> get statuses => _statuses;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _isTime24h = prefs.getBool(_keyTime24h) ?? false;
    _hidePdfReminder = prefs.getBool(_keyHidePdfReminder) ?? false;
    _categories =
        prefs.getStringList(_keyCategories) ??
        ['Work', 'Personal', 'Shopping', 'Health'];
    _statuses =
        prefs.getStringList(_keyStatuses) ??
        ['Not Started', 'Ongoing', 'Finished', 'Dropped'];
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyStatuses, _statuses);
      notifyListeners();
    }
  }

  Future<void> removeStatus(String status) async {
    _statuses.remove(status);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyStatuses, _statuses);
    notifyListeners();
  }

  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isDarkMode = false;
    _isTime24h = false;
    _hidePdfReminder = false;
    _categories = ['Work', 'Personal', 'Shopping', 'Health'];
    _statuses = ['Not Started', 'Ongoing', 'Finished', 'Dropped'];
    notifyListeners();
  }
}
