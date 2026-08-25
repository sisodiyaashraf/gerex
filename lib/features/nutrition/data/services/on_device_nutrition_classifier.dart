import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../../domain/entities/draft_meal.dart';

class OnDeviceNutritionClassifier {
  ImageLabeler? _labeler;

  OnDeviceNutritionClassifier() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.45),
      );
    }
  }

  static const Map<String, Map<String, dynamic>> _foodDb = {
    'chicken': {
      'name': 'Grilled Chicken Breast',
      'portion': 150.0,
      'caloriesPer100g': 165.0,
      'proteinPer100g': 31.0,
      'carbsPer100g': 0.0,
      'fatPer100g': 3.6,
    },
    'rice': {
      'name': 'Jasmine Rice',
      'portion': 150.0,
      'caloriesPer100g': 130.0,
      'proteinPer100g': 2.7,
      'carbsPer100g': 28.0,
      'fatPer100g': 0.3,
    },
    'salad': {
      'name': 'Mixed Salad Greens',
      'portion': 100.0,
      'caloriesPer100g': 15.0,
      'proteinPer100g': 1.4,
      'carbsPer100g': 2.9,
      'fatPer100g': 0.2,
    },
    'broccoli': {
      'name': 'Steamed Broccoli',
      'portion': 100.0,
      'caloriesPer100g': 34.0,
      'proteinPer100g': 2.8,
      'carbsPer100g': 7.0,
      'fatPer100g': 0.4,
    },
    'vegetable': {
      'name': 'Mixed Vegetables',
      'portion': 100.0,
      'caloriesPer100g': 45.0,
      'proteinPer100g': 2.0,
      'carbsPer100g': 9.0,
      'fatPer100g': 0.2,
    },
    'egg': {
      'name': 'Boiled Eggs',
      'portion': 100.0,
      'caloriesPer100g': 143.0,
      'proteinPer100g': 13.0,
      'carbsPer100g': 0.7,
      'fatPer100g': 9.5,
    },
    'bread': {
      'name': 'Whole Wheat Toast',
      'portion': 50.0,
      'caloriesPer100g': 247.0,
      'proteinPer100g': 13.0,
      'carbsPer100g': 41.0,
      'fatPer100g': 3.4,
    },
    'salmon': {
      'name': 'Grilled Salmon',
      'portion': 120.0,
      'caloriesPer100g': 208.0,
      'proteinPer100g': 20.0,
      'carbsPer100g': 0.0,
      'fatPer100g': 13.0,
    },
    'fish': {
      'name': 'Grilled Fish',
      'portion': 120.0,
      'caloriesPer100g': 150.0,
      'proteinPer100g': 20.0,
      'carbsPer100g': 0.0,
      'fatPer100g': 5.0,
    },
    'yogurt': {
      'name': 'Plain Greek Yogurt',
      'portion': 200.0,
      'caloriesPer100g': 59.0,
      'proteinPer100g': 10.0,
      'carbsPer100g': 3.6,
      'fatPer100g': 0.4,
    },
    'oatmeal': {
      'name': 'Protein Oatmeal',
      'portion': 150.0,
      'caloriesPer100g': 100.0,
      'proteinPer100g': 5.0,
      'carbsPer100g': 15.0,
      'fatPer100g': 2.0,
    },
    'oats': {
      'name': 'Oats',
      'portion': 50.0,
      'caloriesPer100g': 389.0,
      'proteinPer100g': 16.9,
      'carbsPer100g': 66.0,
      'fatPer100g': 6.9,
    },
    'banana': {
      'name': 'Fresh Banana',
      'portion': 120.0,
      'caloriesPer100g': 89.0,
      'proteinPer100g': 1.1,
      'carbsPer100g': 23.0,
      'fatPer100g': 0.3,
    },
    'apple': {
      'name': 'Fresh Apple',
      'portion': 150.0,
      'caloriesPer100g': 52.0,
      'proteinPer100g': 0.3,
      'carbsPer100g': 14.0,
      'fatPer100g': 0.2,
    },
    'avocado': {
      'name': 'Mashed Avocado',
      'portion': 80.0,
      'caloriesPer100g': 160.0,
      'proteinPer100g': 2.0,
      'carbsPer100g': 9.0,
      'fatPer100g': 15.0,
    },
    'peanut': {
      'name': 'Peanut Butter',
      'portion': 32.0,
      'caloriesPer100g': 588.0,
      'proteinPer100g': 25.0,
      'carbsPer100g': 20.0,
      'fatPer100g': 50.0,
    },
  };

  Future<List<DraftMealItem>> classifyImage(File image) async {
    if (_labeler == null) {
      // Offline/Desktop platform fallback simulation
      await Future.delayed(const Duration(milliseconds: 1500));
      final pathLower = image.path.toLowerCase();
      // Try to give a smart mock response based on filename
      if (pathLower.contains('breakfast') || pathLower.contains('egg')) {
        return [
          _createDraftItem('egg'),
          _createDraftItem('bread'),
          _createDraftItem('avocado'),
        ];
      } else if (pathLower.contains('salmon') || pathLower.contains('fish')) {
        return [
          _createDraftItem('salmon'),
          _createDraftItem('rice'),
          _createDraftItem('broccoli'),
        ];
      } else if (pathLower.contains('yogurt') || pathLower.contains('berry')) {
        return [
          _createDraftItem('yogurt'),
          _createDraftItem('apple'),
        ];
      }
      // General dinner/lunch default simulation
      return [
        _createDraftItem('chicken'),
        _createDraftItem('rice'),
        _createDraftItem('salad'),
      ];
    }

    try {
      final inputImage = InputImage.fromFile(image);
      final List<ImageLabel> labels = await _labeler!.processImage(inputImage);
      
      final List<DraftMealItem> matchedItems = [];
      final Set<String> matchedKeys = {};

      for (final label in labels) {
        final text = label.label.toLowerCase();
        for (final entry in _foodDb.entries) {
          if (text.contains(entry.key) || entry.key.contains(text)) {
            if (!matchedKeys.contains(entry.key)) {
              matchedKeys.add(entry.key);
              matchedItems.add(_createDraftItem(entry.key));
            }
          }
        }
      }

      return matchedItems;
    } catch (e) {
      // Graceful fallback to empty draft on classification errors
      return [];
    }
  }

  DraftMealItem _createDraftItem(String dbKey) {
    final food = _foodDb[dbKey]!;
    return DraftMealItem(
      name: food['name'] as String,
      portionGrams: food['portion'] as double,
      caloriesPer100g: food['caloriesPer100g'] as double,
      proteinPer100g: food['proteinPer100g'] as double,
      carbsPer100g: food['carbsPer100g'] as double,
      fatPer100g: food['fatPer100g'] as double,
    );
  }

  void dispose() {
    _labeler?.close();
  }
}
