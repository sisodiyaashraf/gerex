import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

abstract class AIRepository {
  Future<Result<String, Failure>> generateWorkoutPlan({
    required String goal,
    required String equipment,
    required String experienceLevel,
  });

  Future<Result<String, Failure>> getCoachResponse({
    required String prompt,
    required List<Map<String, String>> chatHistory,
  });
}
