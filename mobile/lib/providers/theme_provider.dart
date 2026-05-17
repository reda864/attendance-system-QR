import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _initialized;

  // ─── Init ─────────────────────────────────────────────────────────────────

  /// Loads the persisted theme preference from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.themeKey);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    _initialized = true;
    notifyListeners();
  }

  // ─── Toggle ───────────────────────────────────────────────────────────────

  /// Toggles between light and dark mode.
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _persist();
  }

  // ─── Set explicitly ───────────────────────────────────────────────────────

  /// Sets the theme to [mode] and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> setDark() => setThemeMode(ThemeMode.dark);
  Future<void> setLight() => setThemeMode(ThemeMode.light);
  Future<void> setSystem() => setThemeMode(ThemeMode.system);

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (_themeMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    };
    await prefs.setString(AppConstants.themeKey, value);
  }
}
