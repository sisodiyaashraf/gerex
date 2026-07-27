import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import 'ai_service.dart';

class GeminiAIService implements AIService {
  final String _apiKey;

  GeminiAIService(this._apiKey);

  @override
  Future<Result<String, Failure>> generateResponse({
    required String prompt,
    List<Map<String, String>> chatHistory = const [],
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
        model: 'gemini-2.5-flash',
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
          ServerFailure('Failed to get a response from Gemini.'),
        );
      }

      return Success(text);
    } catch (e) {
      return FailureResult(ServerFailure(e.toString()));
    }
  }
}
