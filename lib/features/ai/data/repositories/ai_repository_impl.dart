import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/ai_repository.dart';

class AIRepositoryImpl implements AIRepository {
  final String _apiKey;

  AIRepositoryImpl(this._apiKey);

  @override
  Future<Result<String, Failure>> generateWorkoutPlan({
    required String goal,
    required String equipment,
    required String experienceLevel,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'placeholder-gemini-key') {
      return const FailureResult(
        ServerFailure(
          'Gemini API key is not configured. Please set GEMINI_API_KEY in your .env file.',
        ),
      );
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt =
          'Generate a structured weekly workout plan (Monday to Sunday) for a user with the following details:\n'
          '- Goal: $goal\n'
          '- Available Equipment: $equipment\n'
          '- Experience Level: $experienceLevel\n\n'
          'Format the response cleanly in markdown. Include exercises, sets, reps, and brief coaching tips for each day.';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return const FailureResult(
          ServerFailure('Failed to generate plan. Please try again.'),
        );
      }

      return Success(text);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String, Failure>> getCoachResponse({
    required String prompt,
    required List<Map<String, String>> chatHistory,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'placeholder-gemini-key') {
      return const FailureResult(
        ServerFailure(
          'Gemini API key is not configured. Please set GEMINI_API_KEY in your .env file.',
        ),
      );
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final contents = <Content>[];

      // Add system role instruction
      contents.add(
        Content(
          'user',
          [
            TextPart(
              'You are a supportive, knowledgeable personal fitness coach named Coach Gerex. '
              'Provide concise, safe, and motivating training and nutrition advice. Keep answers under 150 words.',
            ),
          ],
        ),
      );

      for (final msg in chatHistory) {
        final role = msg['role'] == 'user' ? 'user' : 'model';
        final text = msg['text'] ?? '';
        contents.add(Content(role, [TextPart(text)]));
      }

      contents.add(Content.text(prompt));

      final response = await model.generateContent(contents);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return const FailureResult(
          ServerFailure('Failed to get a response. Please try again.'),
        );
      }

      return Success(text);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
