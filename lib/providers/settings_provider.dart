import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyCurrency = 'currency';
  static const String _keyThemeColor = 'theme_color';
  static const String _keyFontSize = 'font_size';
  static const String _keyHideTotalAmount = 'hide_total_amount';

  bool _isDarkMode = false;
  String _currency = '₱';
  int? _themeColor;
  String _fontSize = 'Small';
  bool _hideTotalAmount = true;
  Future<void>? _loadFuture;

  SettingsProvider() {
    preload();
  }

  Future<void> preload() {
    return _loadFuture ??= _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  int? get themeColor => _themeColor;
  String get fontSize => _fontSize;
  bool get hideTotalAmount => _hideTotalAmount;

  double get textScaleFactor {
    switch (_fontSize) {
      case 'Medium':
        return 1.15;
      case 'Large':
        return 1.30;
      case 'Small':
      default:
        return 1.0;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _currency = prefs.getString(_keyCurrency) ?? '₱';
    _themeColor = prefs.containsKey(_keyThemeColor)
        ? prefs.getInt(_keyThemeColor)
        : null;
    _fontSize = prefs.getString(_keyFontSize) ?? 'Small';
    _hideTotalAmount = prefs.getBool(_keyHideTotalAmount) ?? true;

    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> toggleHideTotalAmount() async {
    _hideTotalAmount = !_hideTotalAmount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHideTotalAmount, _hideTotalAmount);
    notifyListeners();
  }

  Future<void> setHideTotalAmount(bool value) async {
    _hideTotalAmount = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHideTotalAmount, value);
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

  Future<void> setFontSize(String value) async {
    _fontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontSize, value);
    notifyListeners();
  }

  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isDarkMode = false;
    _currency = '₱';
    _themeColor = null;
    _fontSize = 'Small';
    _hideTotalAmount = true;
    notifyListeners();
  }
}
