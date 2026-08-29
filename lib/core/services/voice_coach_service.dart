import 'package:gerex/core/di/injection_container.dart' as di;
import 'package:gerex/features/profile/presentation/providers/profile_provider.dart';
import 'package:gerex/core/utils/logger.dart';
import 'voice_engine.dart';

class VoiceCoachService {
  final VoiceEngine _voiceEngine;
  DateTime _lastCorrectionSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);

  VoiceCoachService(this._voiceEngine);

  static const Map<String, Map<String, Map<String, String>>> _templates = {
    'motivator': {
      'english': {
        'start': "Let's get started and have a great workout today!",
        'milestone': "Fantastic work! That is {rep} reps down. Keep it up!",
        'set_complete': "Awesome job, that set is complete. Take a breather!",
        'rest_countdown': "Rest time. {seconds} seconds left. Stay focused.",
        'rest_complete': "Rest complete. Ready for the next set? Let's go!",
        'form_correction': "Focus on your posture and control the movement. You've got this!",
        'finish': "Workout complete! You did amazing today. Proud of you!",
      },
      'hindi': {
        'start': "चलिए शुरू करते हैं! आज का वर्कआउट बहुत बढ़िया होगा।",
        'milestone': "बहुत अच्छे! {rep} रेप्स पूरे हो गए। ऐसे ही करते रहें!",
        'set_complete': "बहुत बढ़िया! यह सेट पूरा हुआ। थोड़ी सांस लें।",
        'rest_countdown': "आराम का समय। {seconds} सेकंड बचे हैं। ध्यान रखें।",
        'rest_complete': "आराम का समय समाप्त। अगले सेट के लिए तैयार हो जाएं!",
        'form_correction': "अपने पोस्चर पर ध्यान दें और नियंत्रण बनाए रखें। आप कर सकते हैं!",
        'finish': "वर्कआउट पूरा हुआ! आपने आज बहुत शानदार काम किया।",
      },
      'hinglish': {
        'start': "Let's start! Aaj ka workout bahut badhiya hone wala hai.",
        'milestone': "Great job! {rep} reps ho gaye. Aise hi carry on rakho!",
        'set_complete': "Awesome! Set complete ho gaya. Ab relax karo.",
        'rest_countdown': "Rest time! Sirf {seconds} seconds bache hain. Focus rakho.",
        'rest_complete': "Rest over! Next set ke liye ready ho jao.",
        'form_correction': "Form checking! Posture thik rakho aur body control karo.",
        'finish': "Perfect! Workout khatam ho gaya. Aaj aapne kamaal kar diya!",
      }
    },
    'drill_sergeant': {
      'english': {
        'start': "Workout starts now! No excuses, give me everything you've got!",
        'milestone': "Keep pushing! {rep} reps done! Don't you dare stop now!",
        'set_complete': "Set done. Move! Drop and breathe, but stay sharp!",
        'rest_countdown': "Resting! {seconds} seconds left. Stay in the zone!",
        'rest_complete': "Time's up! Back to work, let's go!",
        'form_correction': "Check your form! Keep your core tight and push through!",
        'finish': "Workout complete! Mission accomplished. Outstanding effort!",
      },
      'hindi': {
        'start': "वर्कआउट शुरू! कोई बहाना नहीं चलेगा, अपना सब कुछ झोंक दें!",
        'milestone': "रुको मत! {rep} रेप्स हो गए! हिम्मत मत हारो!",
        'set_complete': "सेट पूरा हुआ। सांस लो लेकिन ध्यान भटको मत!",
        'rest_countdown': "आराम का समय! {seconds} सेकंड बचे हैं। तैयार रहो!",
        'rest_complete': "समय समाप्त! वापस काम पर लगें, शुरू करें!",
        'form_correction': "पोस्चर सही रखें! कोर को मजबूत रखें और पूरी ताकत लगाएं!",
        'finish': "वर्कआउट खत्म! मिशन पूरा हुआ। बहुत बढ़िया!",
      },
      'hinglish': {
        'start': "Workout shuru! No excuses, aaj apna best dena hai!",
        'milestone': "Rukna mat! {rep} reps complete! Keep pushing hard!",
        'set_complete': "Set complete. Saans lo aur focus wapas lao!",
        'rest_countdown': "Resting! Bas {seconds} seconds baaki hain. Alerto raho!",
        'rest_complete': "Time up! Chalo wapas kaam pe lago, ready!",
        'form_correction': "Form check! Core tight rakho aur posture control karo!",
        'finish': "Workout khatam! Mission success. Aaj aapne phad diya!",
      }
    },
    'chill': {
      'english': {
        'start': "Welcome. Let's begin our session today with mindfulness and calm.",
        'milestone': "Beautiful. That's {rep} reps. Gently continuing.",
        'set_complete': "Very nice. The set is complete. Breathe in and let go.",
        'rest_countdown': "Rest period. {seconds} seconds remaining. Enjoy this moment of pause.",
        'rest_complete': "Rest is complete. Slowly prepare for your next set.",
        'form_correction': "Feel the muscle connection. Move with control and breathe.",
        'finish': "Workout complete. Thank you for showing up for yourself today.",
      },
      'hindi': {
        'start': "नमस्ते। आइए आज का सत्र शांति और सचेत होकर शुरू करें।",
        'milestone': "बहुत सुंदर। {rep} रेप्स पूरे। धीरे-धीरे आगे बढ़ें।",
        'set_complete': "बहुत अच्छा। सेट पूरा हुआ। गहरी सांस लें और छोड़ें।",
        'rest_countdown': "विश्राम काल। {seconds} सेकंड शेष हैं। इस ठहराव का आनंद लें।",
        'rest_complete': "विश्राम समाप्त। अगले सेट के लिए धीरे-धीरे तैयार हो जाएं।",
        'form_correction': "मांसपेशियों के जुड़ाव को महसूस करें। नियंत्रण के साथ सांस लें।",
        'finish': "वर्कआउट पूरा हुआ। आज खुद के लिए समय निकालने के लिए धन्यवाद।",
      },
      'hinglish': {
        'start': "Welcome. Aao aaj ka session thoda peaceful tarike se start karein.",
        'milestone': "Very nice. {rep} reps pure ho gaye. Softly continue karein.",
        'set_complete': "Achha laga. Set khatam hua. Deep breath in, aur relax.",
        'rest_countdown': "Rest time. {seconds} seconds remaining. Pause ko feel karein.",
        'rest_complete': "Rest over. Agle set ke liye dheere se ready ho jao.",
        'form_correction': "Muscle connect karo. Slow move karo aur normal breath rakho.",
        'finish': "Workout complete. Apni body ko thank you boleun aaj session ke liye.",
      }
    },
    'playful': {
      'english': {
        'start': "Oh look who's here! Let's get moving, superstar!",
        'milestone': "Look at you go! {rep} reps done. Showing off today, are we?",
        'set_complete': "Set completed! You made that look way too easy.",
        'rest_countdown': "Break time! {seconds} seconds to chill. Check your phone if you must!",
        'rest_complete': "Busted! Break is over. Let's make it count!",
        'form_correction': "Whoa, watch that pose! We want muscles, not injuries, honey!",
        'finish': "Woohoo! All done! Go get a high-five or a big smoothie!",
      },
      'hindi': {
        'start': "अरे वाह, आप आ गए! चलिए शुरू करते हैं, आज कमाल करना है!",
        'milestone': "क्या बात है! {rep} रेप्स पूरे। आज तो आप छा गए!",
        'set_complete': "सेट खत्म! आपने तो इसे बहुत ही आसान बना दिया।",
        'rest_countdown': "ब्रेक टाइम! {seconds} सेकंड आराम के। थोड़ा घूम-फिर लें!",
        'rest_complete': "पकड़े गए! ब्रेक खत्म। चलिए वापस शुरू करते हैं!",
        'form_correction': "अरे, पोस्चर संभालो! चोट नहीं खानी है, ध्यान से करो!",
        'finish': "बल्ले बल्ले! सब खत्म! आज तो आपने कमाल ही कर दिया!",
      },
      'hinglish': {
        'start': "Look who's back! Aao chalo superstar, start karte hain!",
        'milestone': "Kya baat hai! {rep} reps ho gaye. Aaj to full energy lag rahi hai!",
        'set_complete': "Set done! You made it look very easy, haan!",
        'rest_countdown': "Break time! {seconds} seconds chill karne ke liye, phone mat chalana!",
        'rest_complete': "Break over! Chalo lazy bones, back to work!",
        'form_correction': "Ouch, watch your form! Galat pose nahi, safety first, dost!",
        'finish': "Yay! Sab khatam! Ab jaakar party karo ya shake piyo!",
      }
    }
  };

  Future<void> speakTrigger(String trigger, {Map<String, String>? params}) async {
    try {
      final profileProvider = di.sl<ProfileProvider>();
      if (!profileProvider.voiceCoachingEnabled) return;

      final now = DateTime.now();
      if (now.difference(_lastCorrectionSpokenAt).inSeconds < 3.5) {
        return; // Suppress template prompts if a safety/form correction was just spoken
      }

      final lang = profileProvider.voiceCoachLanguage;
      final persona = profileProvider.voiceCoachPersona;
      final rate = profileProvider.voiceCoachRate;
      final pitch = profileProvider.voiceCoachPitch;
      final volume = persona == 'chill' ? 0.8 : 1.0;

      final personaMap = _templates[persona] ?? _templates['motivator']!;
      String template = '';

      if (lang == 'hinglish' && profileProvider.voiceCoachHinglishClean) {
        final eng = personaMap['english']?[trigger] ?? '';
        final hin = personaMap['hindi']?[trigger] ?? '';
        template = '$eng. $hin';
      } else {
        template = personaMap[lang]?[trigger] ?? personaMap['english']?[trigger] ?? '';
      }

      if (template.isEmpty) return;

      String spokenText = template;
      if (params != null) {
        params.forEach((key, value) {
          spokenText = spokenText.replaceAll('{$key}', value);
        });
      }

      final sentences = spokenText.split(RegExp(r'(?<=[.!?])\s+'));

      for (final sentence in sentences) {
        if (sentence.trim().isEmpty) continue;
        
        final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(sentence);
        final sentenceLanguage = hasDevanagari ? 'hi-IN' : (lang == 'english' ? 'en-US' : 'en-IN');
        
        await _voiceEngine.speak(
          sentence,
          rate: rate,
          pitch: pitch,
          volume: volume,
          language: sentenceLanguage,
        );
      }
    } catch (e) {
      SecureLogger.logError('VoiceCoachService: speakTrigger failed', e);
    }
  }

  Future<void> speakPreview({
    required String language,
    required String persona,
    required double rate,
    required double pitch,
  }) async {
    try {
      final personaMap = _templates[persona] ?? _templates['motivator']!;
      String template = '';

      if (language == 'hinglish') {
        final eng = personaMap['english']?['start'] ?? '';
        final hin = personaMap['hindi']?['start'] ?? '';
        template = '$eng. $hin';
      } else {
        template = personaMap[language]?['start'] ?? personaMap['english']?['start'] ?? '';
      }

      final sentences = template.split(RegExp(r'(?<=[.!?])\s+'));
      final volume = persona == 'chill' ? 0.8 : 1.0;

      for (final sentence in sentences) {
        if (sentence.trim().isEmpty) continue;
        final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(sentence);
        final sentenceLanguage = hasDevanagari ? 'hi-IN' : (language == 'english' ? 'en-US' : 'en-IN');

        await _voiceEngine.speak(
          sentence,
          rate: rate,
          pitch: pitch,
          volume: volume,
          language: sentenceLanguage,
        );
      }
    } catch (e) {
      SecureLogger.logError('VoiceCoachService: speakPreview failed', e);
    }
  }

  Future<void> speak(String text) async {
    try {
      final profileProvider = di.sl<ProfileProvider>();
      if (!profileProvider.voiceCoachingEnabled) return;

      final lang = profileProvider.voiceCoachLanguage;
      final persona = profileProvider.voiceCoachPersona;
      final rate = profileProvider.voiceCoachRate;
      final pitch = profileProvider.voiceCoachPitch;
      final volume = persona == 'chill' ? 0.8 : 1.0;

      final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
      for (final sentence in sentences) {
        if (sentence.trim().isEmpty) continue;
        final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(sentence);
        final sentenceLanguage = hasDevanagari ? 'hi-IN' : (lang == 'english' ? 'en-US' : 'en-IN');

        await _voiceEngine.speak(
          sentence,
          rate: rate,
          pitch: pitch,
          volume: volume,
          language: sentenceLanguage,
        );
      }
    } catch (e) {
      SecureLogger.logError('VoiceCoachService: speak failed', e);
    }
  }

  Future<void> speakCorrection(String text) async {
    _lastCorrectionSpokenAt = DateTime.now();
    await speak(text);
  }

  Future<bool> checkLanguageVoicePack(String language) async {
    String code = 'en-US';
    if (language == 'hindi' || language == 'hinglish') {
      code = 'hi-IN';
    }
    return await _voiceEngine.isLanguageAvailable(code);
  }
}
