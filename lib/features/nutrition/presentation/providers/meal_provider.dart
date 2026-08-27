import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/meal_entities.dart';
import '../../data/recipes_seed.dart';
import 'package:gerex/core/utils/logger.dart';
import 'package:gerex/core/di/injection_container.dart' as di;
import 'package:gerex/core/providers/notification_provider.dart';

class MealProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  MealProvider(this._prefs) {
    _loadRecipes();
    _loadMealPlan();
  }

  List<Recipe> _recipes = [];
  List<Recipe> get recipes => _recipes;

  List<MealPlanEntry> _mealPlan = [];
  List<MealPlanEntry> get mealPlan => _mealPlan;

  void _loadRecipes() {
    _recipes = List.from(seededRecipes);
    final favIds = _prefs.getStringList('favorite_recipe_ids') ?? [];
    for (var r in _recipes) {
      if (favIds.contains(r.id)) {
        r.isFavorite = true;
      }
    }
  }

  void _saveFavorites() {
    final favIds = _recipes.where((r) => r.isFavorite).map((r) => r.id).toList();
    _prefs.setStringList('favorite_recipe_ids', favIds);
  }

  void _loadMealPlan() {
    final list = _prefs.getStringList('cached_meal_plan') ?? [];
    if (list.isEmpty) {
      // Seed plans for past week to build a beautiful nutrition trend chart!
      final now = DateTime.now();
      _mealPlan = [];
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        // Add breakfast & lunch logs
        _mealPlan.add(MealPlanEntry(
          id: 'seed_breakfast_$i',
          recipeId: 'rec_1',
          recipeName: 'Avocado Toast & Eggs',
          date: date,
          mealType: 'Breakfast',
          calories: 380.0,
          protein: 18.0,
          carbs: 24.0,
          fat: 14.0,
        ));
        _mealPlan.add(MealPlanEntry(
          id: 'seed_lunch_$i',
          recipeId: 'rec_3',
          recipeName: 'Grilled Chicken Quinoa',
          date: date,
          mealType: 'Lunch',
          calories: 580.0,
          protein: 42.0,
          carbs: 52.0,
          fat: 12.0,
        ));
      }
      _saveMealPlan();
    } else {
      try {
        _mealPlan = list.map((item) {
          final parts = item.split(':::');
          return MealPlanEntry(
            id: parts[0],
            recipeId: parts[1],
            recipeName: parts[2],
            date: DateTime.parse(parts[3]),
            mealType: parts[4],
            calories: double.parse(parts[5]),
            protein: double.parse(parts[6]),
            carbs: double.parse(parts[7]),
            fat: double.parse(parts[8]),
            notificationEnabled: parts.length > 9 ? parts[9] == '1' : true,
            imagePath: (parts.length > 10 && parts[10].isNotEmpty) ? parts[10] : null,
          );
        }).toList();
      } catch (e) {
        SecureLogger.logError('Failed to parse meal plan logs', e);
      }
    }
    notifyListeners();
  }

  Future<void> _saveMealPlan() async {
    final list = _mealPlan.map((m) => '${m.id}:::${m.recipeId}:::${m.recipeName}:::${m.date.toIso8601String()}:::${m.mealType}:::${m.calories}:::${m.protein}:::${m.carbs}:::${m.fat}:::${m.notificationEnabled ? '1' : '0'}:::${m.imagePath ?? ''}').toList();
    await _prefs.setStringList('cached_meal_plan', list);
  }

  void addMealPlanEntry(Recipe recipe, String mealType, DateTime date) {
    final newEntry = MealPlanEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipeId: recipe.id,
      recipeName: recipe.name,
      date: date,
      mealType: mealType,
      calories: recipe.calories,
      protein: recipe.protein,
      carbs: recipe.carbs,
      fat: recipe.fat,
    );
    _mealPlan.add(newEntry);
    _saveMealPlan();
    if (newEntry.notificationEnabled) {
      di.sl<NotificationProvider>().scheduleMealReminder(
        entryId: newEntry.id,
        recipeId: newEntry.recipeId,
        mealName: newEntry.recipeName,
        mealType: newEntry.mealType,
        day: newEntry.date,
        calories: newEntry.calories,
      );
    }
    notifyListeners();
  }

  void addCustomMealEntry({
    required String name,
    required String mealType,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required DateTime date,
    String? imagePath,
  }) {
    final newEntry = MealPlanEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      recipeId: 'custom',
      recipeName: name,
      date: date,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      imagePath: imagePath,
    );
    _mealPlan.add(newEntry);
    _saveMealPlan();
    if (newEntry.notificationEnabled) {
      di.sl<NotificationProvider>().scheduleMealReminder(
        entryId: newEntry.id,
        recipeId: newEntry.recipeId,
        mealName: newEntry.recipeName,
        mealType: newEntry.mealType,
        day: newEntry.date,
        calories: newEntry.calories,
      );
    }
    notifyListeners();
  }

  void deleteMealPlanEntry(String id) {
    _mealPlan.removeWhere((m) => m.id == id);
    _saveMealPlan();
    notifyListeners();
  }

  void toggleMealNotification(String id, bool enabled) {
    final idx = _mealPlan.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _mealPlan[idx].notificationEnabled = enabled;
      _saveMealPlan();
      if (enabled) {
        final entry = _mealPlan[idx];
        di.sl<NotificationProvider>().scheduleMealReminder(
          entryId: entry.id,
          recipeId: entry.recipeId,
          mealName: entry.recipeName,
          mealType: entry.mealType,
          day: entry.date,
          calories: entry.calories,
        );
      } else {
        di.sl<NotificationProvider>().cancelNotification('meal-$id');
      }
      notifyListeners();
    }
  }

  void toggleFavoriteRecipe(String id) {
    final idx = _recipes.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _recipes[idx].isFavorite = !_recipes[idx].isFavorite;
      _saveFavorites();
      notifyListeners();
    }
  }

  List<MealPlanEntry> get recentCustomMeals {
    final Set<String> seen = {};
    final List<MealPlanEntry> list = [];
    for (final entry in _mealPlan.reversed) {
      final nameLower = entry.recipeName.toLowerCase().trim();
      if (entry.recipeId == 'custom' &&
          nameLower.isNotEmpty &&
          !nameLower.contains('fallback') &&
          !nameLower.contains('mock') &&
          !seen.contains(nameLower)) {
        seen.add(nameLower);
        list.add(entry);
      }
      if (list.length >= 5) break;
    }
    return list;
  }
}
