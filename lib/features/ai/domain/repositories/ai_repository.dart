import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

abstract class AIRepository {
  bool get lastCallWasOffline;

  Future<Result<String, Failure>> generateWorkoutPlan({
    required String goal,
    required String equipment,
    required String experienceLevel,
  });

  Future<Result<String, Failure>> getCoachResponse({
    required String prompt,
    required List<Map<String, String>> chatHistory,
    bool forceEscalate = false,
  });

  Future<Result<String, Failure>> getDailyInsight({
    required List<String> recentWorkoutsSummary,
  });

  Future<Result<List<String>, Failure>> getExerciseSwap({
    required String exerciseName,
    required String muscleGroup,
  });

  Future<Result<String, Failure>> getProgressSummary({
    required List<String> sessionsSummary,
  });

  Future<Result<String, Failure>> getWeeklyTrainingStory({
    required List<String> sessionsSummary,
  });
}
