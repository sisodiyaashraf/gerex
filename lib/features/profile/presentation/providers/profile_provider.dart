import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  ProfileProvider(this._prefs) {
    _loadPreferences();
  }

  String _units = 'kg';
  bool _notificationsEnabled = true;
  String _themeMode = 'system';

  String get units => _units;
  bool get notificationsEnabled => _notificationsEnabled;
  String get themeMode => _themeMode;

  void _loadPreferences() {
    _units = _prefs.getString('units_preference') ?? 'kg';
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _themeMode = _prefs.getString('theme_mode') ?? 'system';
    notifyListeners();
  }

  Future<void> setUnits(String value) async {
    _units = value;
    await _prefs.setString('units_preference', value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    _themeMode = value;
    await _prefs.setString('theme_mode', value);
    notifyListeners();
  }
}
