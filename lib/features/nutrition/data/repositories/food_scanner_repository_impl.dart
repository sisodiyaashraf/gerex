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
        isFood: true,
      );
    }

    try {
      final bytes = await image.readAsBytes();
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      const prompt = 'Analyze this image. First, determine if the image primarily shows edible food or a meal. '
          'If the image shows a non-food item (such as a laptop, shoe, chair, phone, animal, etc.), you MUST set the "isFood" key to false, '
          'identify the item name under the "foodName" key (e.g. "iPhone" or "Red Sneaker"), and set all nutrition numbers to 0. '
          'If the image shows edible food/meal, set the "isFood" key to true, identify the food name, '
          'and estimate its calories (in kcal), protein (in grams), carbohydrates (in grams), fat (in grams), '
          'along with the estimated portion size (in grams). '
          'You MUST respond ONLY with a raw JSON object containing these keys: '
          '"isFood" (boolean), "foodName" (string), "calories" (number), "protein" (number), '
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
        isFood: jsonMap['isFood'] as bool? ?? true,
        foodName: jsonMap['foodName']?.toString() ?? 'Unknown Item',
        calories: (jsonMap['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (jsonMap['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (jsonMap['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (jsonMap['fat'] as num?)?.toDouble() ?? 0.0,
        portionSize: (jsonMap['portionSize'] as num?)?.toDouble() ?? 100.0,
      );
    } catch (e) {
      rethrow;
    }
  }
}
