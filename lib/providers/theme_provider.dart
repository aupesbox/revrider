import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Load saved theme from prefs
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('themeMode') ?? 'system';
    _mode = ThemeMode.values.firstWhere(
          (m) => m.toString().split('.').last == str,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  /// Toggle between light and dark (or system → light)
  Future<void> toggle() async {
    if (_mode == ThemeMode.light) {
      _mode = ThemeMode.dark;
    } else {
      _mode = ThemeMode.light;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _mode.toString().split('.').last);
    notifyListeners();
  }
}
