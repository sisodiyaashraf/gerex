import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerex/core/di/injection_container.dart' as di;
import 'package:gerex/features/ai/presentation/providers/ai_provider.dart';
import 'package:gerex/features/ai/domain/repositories/ai_repository.dart';
import 'package:gerex/core/error/failures.dart';
import 'package:gerex/core/error/result.dart';

class MockAIRepository implements AIRepository {
  bool shouldPlanSucceed = true;
  bool shouldCoachSucceed = true;
  int planCallCount = 0;

  @override
  bool get lastCallWasOffline => false;

  @override
  Future<Result<String, Failure>> generateWorkoutPlan({
    required String goal,
    required String equipment,
    required String experienceLevel,
  }) async {
    planCallCount++;
    if (shouldPlanSucceed) {
      return const Success('Generated Weekly Routine Split Plan');
    } else {
      return const FailureResult(ServerFailure('Gemini API error'));
    }
  }

  @override
  Future<Result<String, Failure>> getCoachResponse({
    required String prompt,
    required List<Map<String, String>> chatHistory,
    bool forceEscalate = false,
  }) async {
    if (shouldCoachSucceed) {
      return const Success('Coach Gerex: Keep pushing your limits!');
    } else {
      return const FailureResult(ServerFailure('Coach failed to respond'));
    }
  }

  @override
  Future<Result<String, Failure>> getDailyInsight({
    required List<String> recentWorkoutsSummary,
  }) async {
    return const Success('Insight: Consistency builds progress.');
  }

  @override
  Future<Result<List<String>, Failure>> getExerciseSwap({
    required String exerciseName,
    required String muscleGroup,
  }) async {
    return const Success(['Swap A', 'Swap B', 'Swap C']);
  }

  @override
  Future<Result<String, Failure>> getProgressSummary({
    required List<String> sessionsSummary,
  }) async {
    return const Success(
      'Progress Summary: You are performing exceptionally well.',
    );
  }
}

void main() {
  group('AIProvider Tests', () {
    late MockAIRepository mockRepo;
    late AIProvider aiProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      if (!di.sl.isRegistered<SharedPreferences>()) {
        di.sl.registerLazySingleton<SharedPreferences>(() => prefs);
      }
      mockRepo = MockAIRepository();
      aiProvider = AIProvider(mockRepo);
    });

    test('Initial states are empty', () {
      expect(aiProvider.generatedWorkoutPlan, null);
      expect(aiProvider.isPlanLoading, false);
      expect(aiProvider.planError, null);
      expect(aiProvider.chatMessages.isEmpty, true);
    });

    test('generatePlan success sets plan and uses cache', () async {
      await aiProvider.generatePlan(
        goal: 'Muscle Gain',
        equipment: 'Full Gym',
        experienceLevel: 'Intermediate',
      );

      expect(
        aiProvider.generatedWorkoutPlan,
        'Generated Weekly Routine Split Plan',
      );
      expect(aiProvider.isPlanLoading, false);
      expect(aiProvider.planError, null);
      expect(mockRepo.planCallCount, 1);

      // Call again to verify caching - should NOT increment planCallCount!
      await aiProvider.generatePlan(
        goal: 'Muscle Gain',
        equipment: 'Full Gym',
        experienceLevel: 'Intermediate',
      );

      expect(mockRepo.planCallCount, 1);
    });

    test('generatePlan failure sets error', () async {
      mockRepo.shouldPlanSucceed = false;

      await aiProvider.generatePlan(
        goal: 'Fat Loss',
        equipment: 'Dumbbells',
        experienceLevel: 'Beginner',
      );

      expect(aiProvider.generatedWorkoutPlan, null);
      expect(aiProvider.planError, 'Gemini API error');
    });

    test('sendMessageToCoach success appends user & coach replies', () async {
      await aiProvider.sendMessageToCoach('Should I eat bananas?');

      expect(aiProvider.chatMessages.length, 2);
      expect(aiProvider.chatMessages[0]['role'], 'user');
      expect(aiProvider.chatMessages[0]['text'], 'Should I eat bananas?');
      expect(aiProvider.chatMessages[1]['role'], 'model');
      expect(
        aiProvider.chatMessages[1]['text'],
        'Coach Gerex: Keep pushing your limits!',
      );
    });

    test('loadDailyInsight success sets dailyInsight text', () async {
      await aiProvider.loadDailyInsight([]);
      expect(aiProvider.dailyInsight, 'Insight: Consistency builds progress.');
      expect(aiProvider.isInsightLoading, false);
    });

    test('loadProgressSummary success sets progressSummary text', () async {
      await aiProvider.loadProgressSummary([]);
      expect(
        aiProvider.progressSummary,
        'Progress Summary: You are performing exceptionally well.',
      );
      expect(aiProvider.isSummaryLoading, false);
    });

    test('getExerciseAlternatives returns list of swap alternatives', () async {
      final list = await aiProvider.getExerciseAlternatives('Squat', 'Legs');
      expect(list.length, 3);
      expect(list[0], 'Swap A');
    });
  });
}
