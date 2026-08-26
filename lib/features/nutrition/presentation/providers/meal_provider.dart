import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/meal_entities.dart';
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
    // Premium starter seeds
    _recipes = [
      Recipe(
        id: 'rec_1',
        name: 'Avocado Toast & Eggs',
        description: 'Crispy whole wheat bread with fresh mashed avocado, topped with poached eggs and red chili flakes.',
        author: 'Chef Ryan',
        category: 'Breakfast',
        ingredients: [
          '2 Eggs',
          '1 slice Whole wheat bread',
          '1/2 Fresh Avocado',
          '1 tsp Red chili flakes',
          'Pinch of Salt & Pepper'
        ],
        steps: [
          'Toast the whole wheat bread slice until golden brown and crispy.',
          'Peel and mash the avocado in a bowl with salt, pepper, and lemon juice if desired.',
          'Spread the mashed avocado evenly onto the toasted bread slice.',
          'Poach or fry the eggs to your preference, then place them on top of the avocado.',
          'Garnish with red chili flakes and extra black pepper.'
        ],
        calories: 380.0,
        protein: 18.0,
        carbs: 24.0,
        fat: 14.0,
        tags: ['egg', 'bread', 'fruit'],
      ),
      Recipe(
        id: 'rec_2',
        name: 'Protein Oatmeal Bowl',
        description: 'Warm rolled oats mixed with premium whey protein powder, topped with fresh blueberries, sliced almonds, and a splash of honey.',
        author: 'FitChef Lily',
        category: 'Breakfast',
        ingredients: [
          '1/2 cup Rolled oats',
          '1 scoop Whey protein powder (vanilla)',
          '1/2 cup Blueberries',
          '1 tbsp Sliced almonds',
          '1 tsp Honey'
        ],
        steps: [
          'Cook rolled oats with water or almond milk in a saucepan or microwave.',
          'Stir in the protein powder until fully blended. Add a splash of water if it becomes too thick.',
          'Top with blueberries, almonds, and honey.',
          'Enjoy hot!'
        ],
        calories: 420.0,
        protein: 28.0,
        carbs: 48.0,
        fat: 8.0,
        tags: ['oats', 'dairy', 'fruit', 'nuts'],
      ),
      Recipe(
        id: 'rec_3',
        name: 'Grilled Chicken Quinoa',
        description: 'Lean chicken breast seasoned with lemon and herbs, served over a bed of fluffy quinoa and roasted broccoli.',
        author: 'Coach Marcus',
        category: 'Lunch',
        ingredients: [
          '150g Chicken breast',
          '1/2 cup Quinoa (dry measure)',
          '1 cup Broccoli florets',
          '1 tbsp Olive oil',
          'Lemon juice & oregano'
        ],
        steps: [
          'Cook quinoa according to instructions on package.',
          'Season chicken breast with oregano, salt, pepper, and lemon juice.',
          'Heat olive oil in a skillet and grill chicken for 6-7 minutes on each side until fully cooked.',
          'Steam or roast broccoli florets.',
          'Assemble the bowl by putting down the quinoa, sliced chicken, and broccoli.'
        ],
        calories: 580.0,
        protein: 42.0,
        carbs: 52.0,
        fat: 12.0,
        tags: ['meat', 'rice', 'vegetable'],
      ),
      Recipe(
        id: 'rec_4',
        name: 'Teriyaki Salmon Rice',
        description: 'Pan-seared salmon fillet glazed with light teriyaki sauce, served with jasmine rice and steamed green beans.',
        author: 'Chef Kenji',
        category: 'Dinner',
        ingredients: [
          '120g Salmon fillet',
          '2 tbsp Teriyaki sauce (low sodium)',
          '1/2 cup Jasmine rice',
          '1 cup Green beans'
        ],
        steps: [
          'Cook jasmine rice in a rice cooker.',
          'Pan-sear salmon in a hot skillet for 4 minutes skin-side down, then flip.',
          'Add teriyaki sauce to the skillet and glaze the salmon for 1-2 minutes.',
          'Steam green beans.',
          'Serve salmon over a bowl of jasmine rice alongside the green beans.'
        ],
        calories: 680.0,
        protein: 46.0,
        carbs: 64.0,
        fat: 18.0,
        tags: ['fish', 'rice', 'vegetable'],
      ),
      Recipe(
        id: 'rec_5',
        name: 'Greek Yogurt & Berries',
        description: 'High-protein non-fat Greek yogurt layered with organic strawberries, raspberries, and chia seeds.',
        author: 'Dietitian Clara',
        category: 'Snack',
        ingredients: [
          '200g Greek yogurt (plain/non-fat)',
          '1/2 cup Mixed berries',
          '1 tsp Chia seeds'
        ],
        steps: [
          'Spoon the Greek yogurt into a glass or bowl.',
          'Wash and slice the berries.',
          'Layer berries on top of the yogurt and sprinkle with chia seeds.'
        ],
        calories: 210.0,
        protein: 17.0,
        carbs: 18.0,
        fat: 3.0,
        tags: ['dairy', 'fruit', 'nuts'],
      ),
      Recipe(
        id: 'rec_6',
        name: 'Peanut Butter Rice Cakes',
        description: 'Whole grain brown rice cakes spread with organic creamy peanut butter, sprinkled with chia seeds.',
        author: 'Gerex Fit',
        category: 'Snack',
        ingredients: [
          '2 Brown rice cakes',
          '1.5 tbsp Creamy peanut butter',
          '1/2 tsp Chia seeds'
        ],
        steps: [
          'Place rice cakes on a plate.',
          'Spread peanut butter evenly over each cake.',
          'Sprinkle chia seeds on top.'
        ],
        calories: 190.0,
        protein: 8.0,
        carbs: 22.0,
        fat: 7.0,
        tags: ['rice', 'nuts'],
      ),
    ];
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
