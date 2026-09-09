import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyCurrency = 'currency';
  static const String _keyThemeColor = 'theme_color';

  bool _isDarkMode = false;
  String _currency = '₱';
  int? _themeColor;

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  int? get themeColor => _themeColor;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _currency = prefs.getString(_keyCurrency) ?? '₱';
    _themeColor = prefs.containsKey(_keyThemeColor)
        ? prefs.getInt(_keyThemeColor)
        : null;

    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, value);
    notifyListeners();
  }

  Future<void> setThemeColor(int? colorVal) async {
    _themeColor = colorVal;
    final prefs = await SharedPreferences.getInstance();
    if (colorVal == null) {
      await prefs.remove(_keyThemeColor);
    } else {
      await prefs.setInt(_keyThemeColor, colorVal);
    }
    notifyListeners();
  }

  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isDarkMode = false;
    _currency = '₱';
    _themeColor = null;
    notifyListeners();
  }
}
