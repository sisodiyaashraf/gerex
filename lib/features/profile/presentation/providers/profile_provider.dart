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
  bool _hapticsEnabled = true;
  bool _streakFlameEnabled = true;
  bool _confettiEnabled = true;
  bool _ghostTrainerEnabled = false;

  String _voiceCoachLanguage = 'english';
  String _voiceCoachPersona = 'motivator';
  double _voiceCoachRate = 0.5;
  double _voiceCoachPitch = 1.0;
  bool _voiceCoachHinglishClean = true;

  String get units => _units;
  bool get notificationsEnabled => _notificationsEnabled;
  String get themeMode => _themeMode;
  bool get voiceCoachingEnabled => _voiceCoachingEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get streakFlameEnabled => _streakFlameEnabled;
  bool get confettiEnabled => _confettiEnabled;
  bool get ghostTrainerEnabled => _ghostTrainerEnabled;

  String get voiceCoachLanguage => _voiceCoachLanguage;
  String get voiceCoachPersona => _voiceCoachPersona;
  double get voiceCoachRate => _voiceCoachRate;
  double get voiceCoachPitch => _voiceCoachPitch;
  bool get voiceCoachHinglishClean => _voiceCoachHinglishClean;

  void _loadPreferences() {
    _units = _prefs.getString('units_preference') ?? 'kg';
    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    _themeMode = _prefs.getString('theme_mode') ?? 'system';
    _voiceCoachingEnabled = _prefs.getBool('voice_coaching_enabled') ?? true;
    _hapticsEnabled = _prefs.getBool('haptics_enabled') ?? true;
    _streakFlameEnabled = _prefs.getBool('streak_flame_enabled') ?? true;
    _confettiEnabled = _prefs.getBool('confetti_enabled') ?? true;
    _ghostTrainerEnabled = _prefs.getBool('ghost_trainer_enabled') ?? false;

    _voiceCoachLanguage = _prefs.getString('voice_coach_language') ?? 'english';
    _voiceCoachPersona = _prefs.getString('voice_coach_persona') ?? 'motivator';
    _voiceCoachRate = _prefs.getDouble('voice_coach_rate') ?? 0.5;
    _voiceCoachPitch = _prefs.getDouble('voice_coach_pitch') ?? 1.0;
    _voiceCoachHinglishClean = _prefs.getBool('voice_coach_hinglish_clean') ?? true;
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

  Future<void> toggleHaptics(bool value) async {
    _hapticsEnabled = value;
    await _prefs.setBool('haptics_enabled', value);
    notifyListeners();
  }

  Future<void> toggleStreakFlame(bool value) async {
    _streakFlameEnabled = value;
    await _prefs.setBool('streak_flame_enabled', value);
    notifyListeners();
  }

  Future<void> toggleConfetti(bool value) async {
    _confettiEnabled = value;
    await _prefs.setBool('confetti_enabled', value);
    notifyListeners();
  }

  Future<void> toggleGhostTrainer(bool value) async {
    _ghostTrainerEnabled = value;
    await _prefs.setBool('ghost_trainer_enabled', value);
    notifyListeners();
  }

  Future<void> setVoiceCoachLanguage(String value) async {
    _voiceCoachLanguage = value;
    await _prefs.setString('voice_coach_language', value);
    notifyListeners();
  }

  Future<void> setVoiceCoachPersona(String value) async {
    _voiceCoachPersona = value;
    await _prefs.setString('voice_coach_persona', value);
    if (value == 'motivator') {
      _voiceCoachRate = 0.5;
      _voiceCoachPitch = 1.0;
    } else if (value == 'drill_sergeant') {
      _voiceCoachRate = 0.58;
      _voiceCoachPitch = 0.9;
    } else if (value == 'chill') {
      _voiceCoachRate = 0.42;
      _voiceCoachPitch = 0.95;
    } else if (value == 'playful') {
      _voiceCoachRate = 0.52;
      _voiceCoachPitch = 1.1;
    }
    await _prefs.setDouble('voice_coach_rate', _voiceCoachRate);
    await _prefs.setDouble('voice_coach_pitch', _voiceCoachPitch);
    notifyListeners();
  }

  Future<void> setVoiceCoachRate(double value) async {
    _voiceCoachRate = value;
    await _prefs.setDouble('voice_coach_rate', value);
    notifyListeners();
  }

  Future<void> setVoiceCoachPitch(double value) async {
    _voiceCoachPitch = value;
    await _prefs.setDouble('voice_coach_pitch', value);
    notifyListeners();
  }

  Future<void> toggleVoiceCoachHinglishClean(bool value) async {
    _voiceCoachHinglishClean = value;
    await _prefs.setBool('voice_coach_hinglish_clean', value);
    notifyListeners();
  }
}
