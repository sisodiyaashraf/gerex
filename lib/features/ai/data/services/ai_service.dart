import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';

abstract class AIService {
  Future<Result<String, Failure>> generateResponse({
    required String prompt,
    List<Map<String, String>> chatHistory = const [],
  });
}
