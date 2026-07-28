import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../../../core/ai/context_builder.dart';
import '../../../../core/utils/logger.dart';
import 'offline_ai_service.dart';
import 'gemini_ai_service.dart';

class AIRoutingResult {
  final String text;
  final bool isOffline;

  AIRoutingResult({
    required this.text,
    required this.isOffline,
  });
}

class AIRouter {
  final OfflineAIService _offlineService;
  final GeminiAIService _geminiService;

  bool _lastCallWasOffline = false;
  bool get lastCallWasOffline => _lastCallWasOffline;

  AIRouter(this._offlineService, this._geminiService);

  Future<bool> _checkAndRecordCloudCall() async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final now = DateTime.now();
      const windowDuration = Duration(hours: 1); // 1 hour window

      final List<String> history = prefs.getStringList('ai_calls_history') ?? [];
      final List<DateTime> validCalls = history
          .map((t) => DateTime.tryParse(t))
          .whereType<DateTime>()
          .where((dt) => now.difference(dt).compareTo(windowDuration) <= 0)
          .toList();

      // aiMaxCallsPerHour = 10
      if (validCalls.length >= 10) {
        return false;
      }

      validCalls.add(now);
      final newHistory = validCalls.map((dt) => dt.toIso8601String()).toList();
      await prefs.setStringList('ai_calls_history', newHistory);
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<Result<AIRoutingResult, Failure>> routeQuery({
    required String prompt,
    List<Map<String, String>> chatHistory = const [],
    bool forceEscalate = false,
  }) async {
    final result = await _routeQueryInternal(
      prompt: prompt,
      chatHistory: chatHistory,
      forceEscalate: forceEscalate,
    );
    result.fold(
      onSuccess: (res) => _lastCallWasOffline = res.isOffline,
      onFailure: (_) => _lastCallWasOffline = false,
    );
    return result;
  }

  Future<Result<AIRoutingResult, Failure>> _routeQueryInternal({
    required String prompt,
    required List<Map<String, String>> chatHistory,
    required bool forceEscalate,
  }) async {
    // Topic-Scope Guardrail Check
    if (!_isQueryInScope(prompt)) {
      return Success(AIRoutingResult(
        text: "I'm Gerex's fitness coach, so I can help with workouts, meals, sleep, and your progress — for other questions you'll want a general assistant.",
        isOffline: true,
      ));
    }

    final prefs = di.sl<SharedPreferences>();
    final isOfflineOnly = prefs.getBool('offline_only_ai_assistant') ?? false;
    SecureLogger.logInfo('AIRouter: Read offline_only_ai_assistant: $isOfflineOnly');

    // 1. If user explicitly requests cloud escalation
    if (forceEscalate) {
      if (isOfflineOnly) {
        return Success(AIRoutingResult(
          text: 'Cannot check online because Offline-Only mode is enabled in settings.',
          isOffline: true,
        ));
      }
      final allowed = await _checkAndRecordCloudCall();
      if (!allowed) {
        return const FailureResult(
          ServerFailure('CLOUD_LIMIT_REACHED: Cloud call limit reached. Please try again later.'),
        );
      }
      final onlineRes = await _geminiService.generateResponse(
        prompt: prompt,
        chatHistory: chatHistory,
      );
      return onlineRes.fold(
        onSuccess: (text) => Success(AIRoutingResult(text: text, isOffline: false)),
        onFailure: (fail) => FailureResult(fail),
      );
    }

    // 2. Build local app context & user stats context
    final compiledContext = ContextBuilder.buildContext();
    final contextPrompt = 'Context:\n$compiledContext\n\nPrompt: $prompt';

    // 3. Check offline model download status
    final isDownloaded = await _offlineService.isModelDownloaded();

    // 4. Offline evaluation logic
    if (isDownloaded) {
      final offlineRes = await _offlineService.generateResponse(
        prompt: contextPrompt,
        chatHistory: chatHistory,
      );

      return await offlineRes.fold(
        onSuccess: (text) async {
          // Handled fully offline!
          return Success(AIRoutingResult(text: text, isOffline: true));
        },
        onFailure: (fail) async {
          // If offline fails due to low confidence (query out of scope)
          if (fail.message.contains('OFFLINE_LOW_CONFIDENCE')) {
            if (isOfflineOnly) {
              return Success(AIRoutingResult(
                text: 'I\'m not sure how to answer that offline. Enable cloud access in Settings to search online.',
                isOffline: true,
              ));
            }
            // Check quota before escalating
            final allowed = await _checkAndRecordCloudCall();
            if (!allowed) {
              return const FailureResult(
                ServerFailure('CLOUD_LIMIT_REACHED: Cloud call limit reached. Please try again later.'),
              );
            }
            // Escalating to Gemini Cloud
            final cloudRes = await _geminiService.generateResponse(
              prompt: prompt,
              chatHistory: chatHistory,
            );
            return cloudRes.fold(
              onSuccess: (text) => Success(AIRoutingResult(text: text, isOffline: false)),
              onFailure: (cloudFail) => FailureResult(cloudFail),
            );
          }

          // Other unexpected offline errors (e.g. out of memory, crash)
          if (isOfflineOnly) {
            return FailureResult(fail);
          }
          
          // Check quota before escalating
          final allowed = await _checkAndRecordCloudCall();
          if (!allowed) {
            return const FailureResult(
              ServerFailure('CLOUD_LIMIT_REACHED: Cloud call limit reached. Please try again later.'),
            );
          }
          // Escalation fallback
          final cloudRes = await _geminiService.generateResponse(
            prompt: prompt,
            chatHistory: chatHistory,
          );
          return cloudRes.fold(
            onSuccess: (text) => Success(AIRoutingResult(text: text, isOffline: false)),
            onFailure: (cloudFail) => FailureResult(cloudFail),
          );
        },
      );
    } else {
      // Offline model is not downloaded.
      if (isOfflineOnly) {
        return const FailureResult(
          ServerFailure('Offline model is not downloaded. Go to AI Coach to set up local AI.'),
        );
      }

      // Check quota before escalating
      final allowed = await _checkAndRecordCloudCall();
      if (!allowed) {
        return const FailureResult(
          ServerFailure('CLOUD_LIMIT_REACHED: Cloud call limit reached. Please try again later.'),
        );
      }
      // Automatically fallback to cloud Gemini
      final cloudRes = await _geminiService.generateResponse(
        prompt: prompt,
        chatHistory: chatHistory,
      );
      return cloudRes.fold(
        onSuccess: (text) => Success(AIRoutingResult(text: text, isOffline: false)),
        onFailure: (cloudFail) => FailureResult(cloudFail),
      );
    }
  }

  bool _isQueryInScope(String query) {
    final q = query.toLowerCase().trim();

    // 1. Explicitly out-of-scope markers (coding, unrelated trivia, politics, etc.)
    final outOfScopeIndicators = [
      'python', 'javascript', 'html', 'css', 'java', 'programming', 'code', 'coding',
      'c++', 'c#', 'rust', 'swift', 'kotlin', 'sql', 'weather', 'news', 'president',
      'movie', 'song', 'music', 'crypto', 'bitcoin', 'stock market', 'finance', 'history',
      'science', 'math', 'geography', 'capital of', 'joke', 'write a function', 'write a script',
      'unrelated', 'politics', 'election', 'who is the prime minister', 'prime minister',
      'who is the president', 'first president', 'war', 'current events'
    ];

    for (final kw in outOfScopeIndicators) {
      if (q.contains(kw)) {
        return false;
      }
    }

    // 2. Explicitly in-scope markers (workouts, exercise, meal, nutrition, sleep, progress, app usage)
    final inScopeIndicators = [
      // Greetings & Identity
      'hi', 'hello', 'hey', 'who are you', 'help', 'gerex', 'ai coach', 'personal trainer',
      
      // Exercise & Workouts
      'workout', 'exercise', 'bench press', 'squat', 'pushup', 'pullup', 'dumbbell', 
      'barbell', 'gym', 'reps', 'sets', 'rest', 'chest', 'back', 'shoulders', 'biceps', 
      'triceps', 'legs', 'abs', 'cardio', 'training', 'routine', 'program', 'schedule', 
      'deadlift', 'muscle', 'lift', 'strength', 'fitness', 'crunches', 'warm up',
      
      // Meals & Nutrition
      'meal', 'recipe', 'food', 'breakfast', 'lunch', 'dinner', 'calorie', 'macro', 
      'protein', 'carb', 'fat', 'nutrition', 'diet', 'eat', 'chicken', 'avocado', 
      'salmon', 'weight gain', 'weight loss', 'cut', 'bulk', 'cooking', 'kcal', 'nutrient',
      
      // Sleep
      'sleep', 'alarm', 'bedtime', 'wake', 'night', 'recovery',
      
      // Progress & Activity
      'progress', 'streak', 'steps', 'water', 'hydration', 'drink', 'photo', 'gallery', 
      'picture', 'active', 'log', 'track', 'join', 'find', 'history', 'badge',
      
      // BMI & Metrics
      'bmi', 'weight', 'height', 'body fat', 'metrics', 'muscle mass', 'kg', 'lbs',
      
      // App Navigation & Usage
      'app', 'navigat', 'feature', 'screen', 'how do i', 'how to use', 'tabs', 'tab'
    ];

    for (final kw in inScopeIndicators) {
      if (q.contains(kw)) {
        return true;
      }
    }

    // Default to out-of-scope if no indicator matches
    return false;
  }
}
