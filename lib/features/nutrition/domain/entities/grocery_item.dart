import 'package:flutter/material.dart';

enum GroceryCategory {
  produce,
  dairy,
  protein,
  spices,
  bakery,
  pantry,
  other;

  String get displayName {
    switch (this) {
      case GroceryCategory.produce:
        return 'Produce';
      case GroceryCategory.dairy:
        return 'Dairy & Eggs';
      case GroceryCategory.protein:
        return 'Meat & Seafood';
      case GroceryCategory.spices:
        return 'Spices & Condiments';
      case GroceryCategory.bakery:
        return 'Bakery & Grains';
      case GroceryCategory.pantry:
        return 'Pantry Items';
      case GroceryCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case GroceryCategory.produce:
        return Icons.eco_rounded;
      case GroceryCategory.dairy:
        return Icons.egg_alt_rounded;
      case GroceryCategory.protein:
        return Icons.set_meal_rounded;
      case GroceryCategory.spices:
        return Icons.local_fire_department_rounded;
      case GroceryCategory.bakery:
        return Icons.bakery_dining_rounded;
      case GroceryCategory.pantry:
        return Icons.kitchen_rounded;
      case GroceryCategory.other:
        return Icons.shopping_bag_rounded;
    }
  }

  Color get categoryColor {
    switch (this) {
      case GroceryCategory.produce:
        return const Color(0xFF10B981); // Emerald
      case GroceryCategory.dairy:
        return const Color(0xFF3B82F6); // Blue
      case GroceryCategory.protein:
        return const Color(0xFFEF4444); // Red/Rose
      case GroceryCategory.spices:
        return const Color(0xFFF59E0B); // Amber
      case GroceryCategory.bakery:
        return const Color(0xFFD97706); // Warm Amber
      case GroceryCategory.pantry:
        return const Color(0xFF8B5CF6); // Purple
      case GroceryCategory.other:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

class GroceryItem {
  final String id;
  final String name;
  final GroceryCategory category;
  final String quantity;
  bool isChecked;
  final String? sourceRecipe;
  final DateTime dateAdded;

  GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = '1',
    this.isChecked = false,
    this.sourceRecipe,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  GroceryItem copyWith({
    String? id,
    String? name,
    GroceryCategory? category,
    String? quantity,
    bool? isChecked,
    String? sourceRecipe,
    DateTime? dateAdded,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      sourceRecipe: sourceRecipe ?? this.sourceRecipe,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'quantity': quantity,
      'is_checked': isChecked,
      'source_recipe': sourceRecipe,
      'date_added': dateAdded.toIso8601String(),
    };
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: GroceryCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GroceryCategory.other,
      ),
      quantity: json['quantity'] as String? ?? '1',
      isChecked: json['is_checked'] as bool? ?? false,
      sourceRecipe: json['source_recipe'] as String?,
      dateAdded: json['date_added'] != null
          ? DateTime.parse(json['date_added'] as String)
          : DateTime.now(),
    );
  }

  String toStorageString() {
    return '$id:::$name:::${category.name}:::$quantity:::${isChecked ? "1" : "0"}:::${sourceRecipe ?? ""}:::${dateAdded.toIso8601String()}';
  }

  factory GroceryItem.fromStorageString(String str) {
    final parts = str.split(':::');
    return GroceryItem(
      id: parts[0],
      name: parts[1],
      category: GroceryCategory.values.firstWhere(
        (e) => e.name == parts[2],
        orElse: () => GroceryCategory.other,
      ),
      quantity: parts.length > 3 ? parts[3] : '1',
      isChecked: parts.length > 4 ? parts[4] == '1' : false,
      sourceRecipe: (parts.length > 5 && parts[5].isNotEmpty) ? parts[5] : null,
      dateAdded: parts.length > 6 ? DateTime.parse(parts[6]) : DateTime.now(),
    );
  }
}
