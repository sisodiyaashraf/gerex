import 'package:flutter_test/flutter_test.dart';
import 'package:gerex/features/ai/presentation/providers/ai_provider.dart';
import 'package:gerex/features/ai/domain/repositories/ai_repository.dart';
import 'package:gerex/core/error/failures.dart';
import 'package:gerex/core/error/result.dart';

class MockAIRepository implements AIRepository {
  bool shouldPlanSucceed = true;
  bool shouldCoachSucceed = true;
  int planCallCount = 0;

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
  }) async {
    if (shouldCoachSucceed) {
      return const Success('Coach Gerex: Keep pushing your limits!');
    } else {
      return const FailureResult(ServerFailure('Coach failed to respond'));
    }
  }
}

void main() {
  group('AIProvider Tests', () {
    late MockAIRepository mockRepo;
    late AIProvider aiProvider;

    setUp(() {
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

      expect(aiProvider.generatedWorkoutPlan, 'Generated Weekly Routine Split Plan');
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
      expect(aiProvider.chatMessages[1]['text'], 'Coach Gerex: Keep pushing your limits!');
    });
  });
}
