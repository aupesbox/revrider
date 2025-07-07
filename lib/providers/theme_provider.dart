// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Load saved theme from disk (called from main)
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _mode = ThemeMode.values.firstWhere(
            (m) => m.toString() == stored,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  /// Set a new theme (light/dark) and persist it
  Future<void> setTheme(ThemeMode newMode) async {
    _mode = newMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newMode.toString());
  }

  /// Convenience for a boolean toggle (true = dark)
  Future<void> toggleTheme(bool isDark) async {
    await setTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
