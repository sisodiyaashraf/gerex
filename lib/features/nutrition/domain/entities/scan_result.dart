class ScanResult {
  final String foodName;
  final double calories;
  final double protein; // in grams
  final double carbs;   // in grams
  final double fat;     // in grams
  final double portionSize; // in grams
  final bool isFood;

  const ScanResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.portionSize = 100.0,
    this.isFood = true,
  });

  ScanResult copyWith({
    String? foodName,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? portionSize,
    bool? isFood,
  }) {
    return ScanResult(
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      portionSize: portionSize ?? this.portionSize,
      isFood: isFood ?? this.isFood,
    );
  }
}
