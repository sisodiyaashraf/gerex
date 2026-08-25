class DraftMealItem {
  final String name;
  final double portionGrams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const DraftMealItem({
    required this.name,
    required this.portionGrams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  double get calories => (caloriesPer100g * portionGrams) / 100.0;
  double get protein => (proteinPer100g * portionGrams) / 100.0;
  double get carbs => (carbsPer100g * portionGrams) / 100.0;
  double get fat => (fatPer100g * portionGrams) / 100.0;

  DraftMealItem copyWith({
    String? name,
    double? portionGrams,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
  }) {
    return DraftMealItem(
      name: name ?? this.name,
      portionGrams: portionGrams ?? this.portionGrams,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
    );
  }
}
