import 'package:flutter_tts/flutter_tts.dart';
import 'package:gerex/core/utils/logger.dart';

abstract class VoiceEngine {
  Future<void> init();
  Future<void> speak(String text, {double? rate, double? pitch, double? volume, String? language});
  Future<void> stop();
  Future<bool> isLanguageAvailable(String langCode);
}

class OnDeviceVoiceEngine implements VoiceEngine {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (e) {
      SecureLogger.logError('OnDeviceVoiceEngine: Init failed', e);
    }
  }

  @override
  Future<void> speak(String text, {double? rate, double? pitch, double? volume, String? language}) async {
    await init();
    try {
      if (language != null) {
        await _flutterTts.setLanguage(language);
      }
      if (rate != null) {
        await _flutterTts.setSpeechRate(rate);
      }
      if (pitch != null) {
        await _flutterTts.setPitch(pitch);
      }
      if (volume != null) {
        await _flutterTts.setVolume(volume);
      }
      await _flutterTts.speak(text);
    } catch (e) {
      SecureLogger.logError('OnDeviceVoiceEngine: Speak failed', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      SecureLogger.logError('OnDeviceVoiceEngine: Stop failed', e);
    }
  }

  @override
  Future<bool> isLanguageAvailable(String langCode) async {
    try {
      final dynamic available = await _flutterTts.isLanguageAvailable(langCode);
      return available == true;
    } catch (_) {
      return false;
    }
  }
}
