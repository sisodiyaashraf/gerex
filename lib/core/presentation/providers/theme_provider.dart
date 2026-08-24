import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.light;

  void toggleTheme(bool isDarkMode) {}
  void setThemeMode(ThemeMode mode) {}
}
