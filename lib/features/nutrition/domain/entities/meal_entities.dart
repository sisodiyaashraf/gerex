class Recipe {
  final String id;
  final String name;
  final String description;
  final String author;
  final String category; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final List<String> ingredients; // e.g. ["2 Eggs", "1 Slice Whole Wheat Bread"]
  final List<String> steps; // instructions list
  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.category,
    required this.ingredients,
    required this.steps,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isFavorite = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'Gerex Chef',
      category: json['category'] as String? ?? 'Breakfast',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
      calories: (json['calories'] as num? ?? 0.0).toDouble(),
      protein: (json['protein'] as num? ?? 0.0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0.0).toDouble(),
      fat: (json['fat'] as num? ?? 0.0).toDouble(),
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'category': category,
      'ingredients': ingredients,
      'steps': steps,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'is_favorite': isFavorite,
    };
  }
}

class MealPlanEntry {
  final String id;
  final String recipeId;
  final String recipeName;
  final DateTime date;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  bool notificationEnabled;

  MealPlanEntry({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.date,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.notificationEnabled = true,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) {
    return MealPlanEntry(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      recipeName: json['recipe_name'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: json['meal_type'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'recipe_name': recipeName,
      'date': date.toIso8601String(),
      'meal_type': mealType,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'notification_enabled': notificationEnabled,
    };
  }
}
