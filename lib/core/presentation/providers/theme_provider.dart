import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../di/injection_container.dart' as di;

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadTheme() {
    try {
      final prefs = di.sl<SharedPreferences>();
      final savedMode = prefs.getString('theme_mode') ?? 'system';
      _themeMode = savedMode == 'dark'
          ? ThemeMode.dark
          : savedMode == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
  }

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
