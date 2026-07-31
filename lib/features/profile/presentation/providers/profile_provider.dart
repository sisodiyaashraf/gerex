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
  bool _voiceCoachingEnabled = true;

  String get units => _units;
  bool get notificationsEnabled => _notificationsEnabled;
  String get themeMode => _themeMode;
  bool get voiceCoachingEnabled => _voiceCoachingEnabled;

  void _loadPreferences() {
    _units = _prefs.getString('units_preference') ?? 'kg';
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _themeMode = _prefs.getString('theme_mode') ?? 'system';
    _voiceCoachingEnabled = _prefs.getBool('voice_coaching_enabled') ?? true;
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

  Future<void> toggleVoiceCoaching(bool value) async {
    _voiceCoachingEnabled = value;
    await _prefs.setBool('voice_coaching_enabled', value);
    notifyListeners();
  }
}
