import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gerex/features/nutrition/presentation/providers/meal_provider.dart';

void main() {
  group('MealProvider Tests', () {
    late SharedPreferences prefs;
    late MealProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      provider = MealProvider(prefs);
    });

    test('Initial recipes list is seeded correctly', () {
      expect(provider.recipes.length, 6);
      expect(provider.recipes.first.name, 'Avocado Toast & Eggs');
    });

    test('Initial meal plan is populated with seed defaults', () {
      expect(provider.mealPlan.isNotEmpty, true);
    });

    test('addMealPlanEntry inserts entry successfully', () {
      final initialCount = provider.mealPlan.length;
      final recipe = provider.recipes.first;
      provider.addMealPlanEntry(recipe, 'Snack', DateTime.now());

      expect(provider.mealPlan.length, initialCount + 1);
      expect(provider.mealPlan.last.recipeName, 'Avocado Toast & Eggs');
    });

    test('deleteMealPlanEntry deletes entry successfully', () {
      final entryId = provider.mealPlan.first.id;
      final initialCount = provider.mealPlan.length;
      provider.deleteMealPlanEntry(entryId);

      expect(provider.mealPlan.length, initialCount - 1);
      expect(provider.mealPlan.any((m) => m.id == entryId), false);
    });

    test('toggleFavoriteRecipe updates favorite state', () {
      final recipeId = provider.recipes.first.id;
      expect(provider.recipes.first.isFavorite, false);

      provider.toggleFavoriteRecipe(recipeId);
      expect(provider.recipes.first.isFavorite, true);

      provider.toggleFavoriteRecipe(recipeId);
      expect(provider.recipes.first.isFavorite, false);
    });
  });
}
