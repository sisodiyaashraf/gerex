import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/ai_repository.dart';
import '../services/ai_router.dart';

class AIRepositoryImpl implements AIRepository {
  final AIRouter _aiRouter;

  AIRepositoryImpl(this._aiRouter);

  @override
  bool get lastCallWasOffline => _aiRouter.lastCallWasOffline;

  @override
  Future<Result<String, Failure>> generateWorkoutPlan({
    required String goal,
    required String equipment,
    required String experienceLevel,
  }) async {
    final prompt =
        'Generate a structured weekly workout plan (Monday to Sunday) for a user with the following details:\n'
        '- Goal: $goal\n'
        '- Available Equipment: $equipment\n'
        '- Experience Level: $experienceLevel\n\n'
        'Format the response cleanly in markdown. Include exercises, sets, reps, and brief coaching tips for each day.';

    final res = await _aiRouter.routeQuery(prompt: prompt);
    return res.fold(
      onSuccess: (result) => Success(result.text),
      onFailure: (fail) => FailureResult(fail),
    );
  }

  @override
  Future<Result<String, Failure>> getCoachResponse({
    required String prompt,
    required List<Map<String, String>> chatHistory,
    bool forceEscalate = false,
  }) async {
    final res = await _aiRouter.routeQuery(
      prompt: prompt,
      chatHistory: chatHistory,
      forceEscalate: forceEscalate,
    );
    return res.fold(
      onSuccess: (result) => Success(result.text),
      onFailure: (fail) => FailureResult(fail),
    );
  }

  @override
  Future<Result<String, Failure>> getDailyInsight({
    required List<String> recentWorkoutsSummary,
  }) async {
    final prompt =
        'Based on the user\'s recent workout sessions: $recentWorkoutsSummary, generate one short, highly personalized fitness insight, recovery tip, or motivational line (maximum 2 sentences). Avoid generic suggestions; be direct, actionable, and encouraging.';

    final res = await _aiRouter.routeQuery(prompt: prompt);
    return res.fold(
      onSuccess: (result) => Success(result.text.trim()),
      onFailure: (fail) => FailureResult(fail),
    );
  }

  @override
  Future<Result<List<String>, Failure>> getExerciseSwap({
    required String exerciseName,
    required String muscleGroup,
  }) async {
    final prompt =
        'Provide exactly 3 exercise alternatives to replace \'$exerciseName\' that target the same muscle group \'$muscleGroup\'. '
        'Return ONLY a comma-separated list of the exercise names (e.g. \'Push Up, Chest Fly, Dumbbell Press\'). '
        'Do not return any other text, explanations, or numbers.';

    final res = await _aiRouter.routeQuery(prompt: prompt);
    return res.fold(
      onSuccess: (result) {
        final list = result.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return Success(list);
      },
      onFailure: (fail) => FailureResult(fail),
    );
  }

  @override
  Future<Result<String, Failure>> getProgressSummary({
    required List<String> sessionsSummary,
  }) async {
    final prompt =
        'Based on the user\'s workout history: $sessionsSummary, generate a natural-language fitness progress recap for the week/month (maximum 3 sentences) summarizing how many times they trained, their primary muscle focus, and their volume/consistency progression. Make it sound professional, motivating, and clean.';

    final res = await _aiRouter.routeQuery(prompt: prompt);
    return res.fold(
      onSuccess: (result) => Success(result.text.trim()),
      onFailure: (fail) => FailureResult(fail),
    );
  }
}
