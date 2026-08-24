import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/food_scanner_repository.dart';

class FoodScannerRepositoryImpl implements FoodScannerRepository {
  @override
  Future<ScanResult> analyzeFoodImage(File image) async {
    final apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');
    if (apiKey.isEmpty || apiKey == 'placeholder-gemini-key') {
      await Future.delayed(const Duration(seconds: 2));
      return const ScanResult(
        foodName: 'Grilled Salmon Salad (Mock)',
        calories: 420.0,
        protein: 32.0,
        carbs: 20.0,
        fat: 18.0,
        portionSize: 250.0,
      );
    }

    try {
      final bytes = await image.readAsBytes();
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      const prompt = 'Analyze the food in this image. Identify the meal/food name, '
          'estimate its calories (in kcal), protein (in grams), carbohydrates (in grams), '
          'and fat (in grams), along with the estimated portion size (in grams). '
          'You MUST respond ONLY with a raw JSON object containing these keys: '
          '"foodName" (string), "calories" (number), "protein" (number), '
          '"carbs" (number), "fat" (number), "portionSize" (number). '
          'Do not include markdown tags, code block wrappers like ```json, or any extra text.';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception('Empty response from AI model');
      }

      String cleanedText = text.trim();
      if (cleanedText.startsWith('```')) {
        final lines = cleanedText.split('\n');
        if (lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        cleanedText = lines.join('\n').trim();
      }

      final Map<String, dynamic> jsonMap = json.decode(cleanedText) as Map<String, dynamic>;

      return ScanResult(
        foodName: jsonMap['foodName']?.toString() ?? 'Unknown Dish',
        calories: (jsonMap['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (jsonMap['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (jsonMap['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (jsonMap['fat'] as num?)?.toDouble() ?? 0.0,
        portionSize: (jsonMap['portionSize'] as num?)?.toDouble() ?? 100.0,
      );
    } catch (e) {
      return const ScanResult(
        foodName: 'Analysis Failed (Using Fallback)',
        calories: 380.0,
        protein: 28.0,
        carbs: 42.0,
        fat: 12.0,
        portionSize: 200.0,
      );
    }
  }
}
