import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/grocery_item.dart';
import '../../domain/entities/meal_entities.dart';
import 'package:gerex/core/utils/logger.dart';

class GroceryProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  GroceryProvider(this._prefs) {
    _loadGroceryItems();
  }

  List<GroceryItem> _items = [];
  List<GroceryItem> get items => List.unmodifiable(_items);

  int get totalCount => _items.length;
  int get checkedCount => _items.where((i) => i.isChecked).length;
  double get progressRatio => totalCount == 0 ? 0.0 : checkedCount / totalCount;

  void _loadGroceryItems() {
    final rawList = _prefs.getStringList('cached_grocery_list') ?? [];
    if (rawList.isEmpty) {
      // Seed default items for immediate rich visual state
      _items = [
        GroceryItem(
          id: 'seed_1',
          name: 'Avocados',
          category: GroceryCategory.produce,
          quantity: '2 whole',
          sourceRecipe: 'Avocado Toast & Eggs',
        ),
        GroceryItem(
          id: 'seed_2',
          name: 'Eggs (Large)',
          category: GroceryCategory.dairy,
          quantity: '1 dozen',
          sourceRecipe: 'Avocado Toast & Eggs',
        ),
        GroceryItem(
          id: 'seed_3',
          name: 'Whole Wheat Bread',
          category: GroceryCategory.bakery,
          quantity: '1 loaf',
          sourceRecipe: 'Avocado Toast & Eggs',
        ),
        GroceryItem(
          id: 'seed_4',
          name: 'Chicken Breast',
          category: GroceryCategory.protein,
          quantity: '1.5 lbs',
          sourceRecipe: 'Grilled Chicken Quinoa',
        ),
        GroceryItem(
          id: 'seed_5',
          name: 'Olive Oil',
          category: GroceryCategory.spices,
          quantity: '1 bottle',
          sourceRecipe: 'Air Fryer Egg Rolls',
          isChecked: true,
        ),
        GroceryItem(
          id: 'seed_6',
          name: 'Organic Quinoa',
          category: GroceryCategory.bakery,
          quantity: '1 bag (500g)',
          sourceRecipe: 'Grilled Chicken Quinoa',
        ),
      ];
      _saveGroceryItems();
    } else {
      try {
        _items = rawList.map((str) => GroceryItem.fromStorageString(str)).toList();
      } catch (e) {
        SecureLogger.logError('GroceryProvider: failed to load stored list', e);
      }
    }
    notifyListeners();
  }

  Future<void> _saveGroceryItems() async {
    final list = _items.map((i) => i.toStorageString()).toList();
    await _prefs.setStringList('cached_grocery_list', list);
  }

  GroceryCategory detectCategory(String ingredientName) {
    final lower = ingredientName.toLowerCase();
    if (lower.contains('apple') ||
        lower.contains('banana') ||
        lower.contains('spinach') ||
        lower.contains('carrot') ||
        lower.contains('cabbage') ||
        lower.contains('garlic') ||
        lower.contains('onion') ||
        lower.contains('ginger') ||
        lower.contains('tomato') ||
        lower.contains('avocado') ||
        lower.contains('lemon') ||
        lower.contains('lime') ||
        lower.contains('lettuce') ||
        lower.contains('cucumber') ||
        lower.contains('pepper') ||
        lower.contains('mushroom') ||
        lower.contains('broccoli') ||
        lower.contains('herb') ||
        lower.contains('scallion') ||
        lower.contains('fruit') ||
        lower.contains('berry') ||
        lower.contains('kale') ||
        lower.contains('celery')) {
      return GroceryCategory.produce;
    }

    if (lower.contains('pork') ||
        lower.contains('chicken') ||
        lower.contains('beef') ||
        lower.contains('turkey') ||
        lower.contains('fish') ||
        lower.contains('salmon') ||
        lower.contains('tuna') ||
        lower.contains('shrimp') ||
        lower.contains('bacon') ||
        lower.contains('steak') ||
        lower.contains('lamb') ||
        lower.contains('meat') ||
        lower.contains('poultry')) {
      return GroceryCategory.protein;
    }

    if (lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('butter') ||
        lower.contains('cream') ||
        lower.contains('yogurt') ||
        lower.contains('egg')) {
      return GroceryCategory.dairy;
    }

    if (lower.contains('sauce') ||
        lower.contains('vinegar') ||
        lower.contains('oil') ||
        lower.contains('salt') ||
        lower.contains('pepper') ||
        lower.contains('sugar') ||
        lower.contains('mustard') ||
        lower.contains('ketchup') ||
        lower.contains('spice') ||
        lower.contains('chili') ||
        lower.contains('honey') ||
        lower.contains('mayo') ||
        lower.contains('dressing') ||
        lower.contains('seasoning') ||
        lower.contains('cinnamon') ||
        lower.contains('vanilla')) {
      return GroceryCategory.spices;
    }

    if (lower.contains('bread') ||
        lower.contains('toast') ||
        lower.contains('wrapper') ||
        lower.contains('bun') ||
        lower.contains('rice') ||
        lower.contains('flour') ||
        lower.contains('oat') ||
        lower.contains('tortilla') ||
        lower.contains('pasta') ||
        lower.contains('noodle') ||
        lower.contains('quinoa') ||
        lower.contains('cereal') ||
        lower.contains('grain')) {
      return GroceryCategory.bakery;
    }

    if (lower.contains('bean') ||
        lower.contains('nut') ||
        lower.contains('seed') ||
        lower.contains('can') ||
        lower.contains('chip') ||
        lower.contains('almond') ||
        lower.contains('walnut') ||
        lower.contains('peanut') ||
        lower.contains('snack')) {
      return GroceryCategory.pantry;
    }

    return GroceryCategory.other;
  }

  void addItem({
    required String name,
    GroceryCategory? category,
    String quantity = '1',
    String? sourceRecipe,
  }) {
    final cat = category ?? detectCategory(name);
    final newItem = GroceryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      category: cat,
      quantity: quantity.trim().isEmpty ? '1' : quantity.trim(),
      sourceRecipe: sourceRecipe,
    );
    _items.insert(0, newItem);
    _saveGroceryItems();
    notifyListeners();
  }

  void toggleItem(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].isChecked = !_items[idx].isChecked;
      _saveGroceryItems();
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _saveGroceryItems();
    notifyListeners();
  }

  void clearChecked() {
    _items.removeWhere((i) => i.isChecked);
    _saveGroceryItems();
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _saveGroceryItems();
    notifyListeners();
  }

  int generateFromMealPlan(List<MealPlanEntry> mealPlan, List<Recipe> recipes) {
    int addedCount = 0;
    final Set<String> existingNames = _items.map((i) => i.name.toLowerCase()).toSet();

    for (var entry in mealPlan) {
      // Find matching recipe or use entry info
      final recipe = recipes.firstWhere(
        (r) => r.id == entry.recipeId || r.name == entry.recipeName,
        orElse: () => Recipe(
          id: entry.recipeId,
          name: entry.recipeName,
          description: '',
          author: '',
          category: entry.mealType,
          ingredients: [entry.recipeName],
          steps: [],
          calories: entry.calories,
          protein: entry.protein,
          carbs: entry.carbs,
          fat: entry.fat,
        ),
      );

      for (var ing in recipe.ingredients) {
        final cleanName = ing.replaceAll(RegExp(r'^\d+\s*(\w+\s*)?'), '').trim();
        final nameToUse = cleanName.isEmpty ? ing : ing;

        if (!existingNames.contains(nameToUse.toLowerCase())) {
          final cat = detectCategory(nameToUse);
          _items.add(GroceryItem(
            id: 'mp_${DateTime.now().millisecondsSinceEpoch}_$addedCount',
            name: nameToUse,
            category: cat,
            quantity: '1 recipe portion',
            sourceRecipe: recipe.name,
          ));
          existingNames.add(nameToUse.toLowerCase());
          addedCount++;
        }
      }
    }

    if (addedCount > 0) {
      _saveGroceryItems();
      notifyListeners();
    }
    return addedCount;
  }

  String buildShareableText() {
    if (_items.isEmpty) return 'My Gerex Shopping List is empty!';

    final sb = StringBuffer();
    sb.writeln('🛒 *Gerex Shopping List* (${_items.length} items)');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━');

    for (var cat in GroceryCategory.values) {
      final catItems = _items.where((i) => i.category == cat).toList();
      if (catItems.isNotEmpty) {
        sb.writeln('\n📌 *${cat.displayName}*');
        for (var item in catItems) {
          final mark = item.isChecked ? '✅' : '☐';
          final qty = item.quantity.isNotEmpty ? ' (${item.quantity})' : '';
          sb.writeln(' $mark ${item.name}$qty');
        }
      }
    }

    sb.writeln('\nGenerated with Gerex Fitness App');
    return sb.toString();
  }
}
