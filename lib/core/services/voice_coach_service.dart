import 'package:flutter_tts/flutter_tts.dart';
import 'package:gerex/core/di/injection_container.dart' as di;
import 'package:gerex/features/profile/presentation/providers/profile_provider.dart';
import 'package:gerex/core/utils/logger.dart';

class VoiceCoachService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  VoiceCoachService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Natural speaking rate
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      SecureLogger.logError('VoiceCoachService: Init TTS failed', e);
    }
  }

  Future<void> speak(String text) async {
    try {
      // Lazy load profileProvider to prevent circular dependency
      final profileProvider = di.sl<ProfileProvider>();
      if (!profileProvider.voiceCoachingEnabled) {
        return;
      }
      if (!_isInitialized) {
        await _initTts();
      }
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      SecureLogger.logError('VoiceCoachService: Speak failed', e);
    }
  }
}
