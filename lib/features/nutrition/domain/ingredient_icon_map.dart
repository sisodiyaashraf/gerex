import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IngredientCategoryIcon {
  final String label;         // e.g. "Egg"
  final FaIconData faIcon;
  final String? svgPath;      // in case we have local svg icons later
  final Color accentColor;

  const IngredientCategoryIcon({
    required this.label,
    required this.faIcon,
    this.svgPath,
    required this.accentColor,
  });
}

// Data-driven map matching ingredient category keywords to custom icon definitions
const Map<String, IngredientCategoryIcon> ingredientIconMap = {
  'egg': IngredientCategoryIcon(
    label: 'Egg',
    faIcon: FontAwesomeIcons.egg,
    accentColor: Colors.amberAccent,
  ),
  'meat': IngredientCategoryIcon(
    label: 'Meat/Protein',
    faIcon: FontAwesomeIcons.drumstickBite,
    accentColor: Colors.redAccent,
  ),
  'fish': IngredientCategoryIcon(
    label: 'Fish/Salmon',
    faIcon: FontAwesomeIcons.fish,
    accentColor: Colors.cyanAccent,
  ),
  'rice': IngredientCategoryIcon(
    label: 'Grain/Rice',
    faIcon: FontAwesomeIcons.bowlRice,
    accentColor: Colors.orangeAccent,
  ),
  'bread': IngredientCategoryIcon(
    label: 'Bread/Toast',
    faIcon: FontAwesomeIcons.breadSlice,
    accentColor: Colors.brown,
  ),
  'dairy': IngredientCategoryIcon(
    label: 'Dairy',
    faIcon: FontAwesomeIcons.cheese,
    accentColor: Colors.blueAccent,
  ),
  'fruit': IngredientCategoryIcon(
    label: 'Fruit',
    faIcon: FontAwesomeIcons.appleWhole,
    accentColor: Colors.pinkAccent,
  ),
  'vegetable': IngredientCategoryIcon(
    label: 'Vegetables',
    faIcon: FontAwesomeIcons.carrot,
    accentColor: Colors.greenAccent,
  ),
  'greens': IngredientCategoryIcon(
    label: 'Salad/Greens',
    faIcon: FontAwesomeIcons.seedling,
    accentColor: Colors.lightGreenAccent,
  ),
  'nuts': IngredientCategoryIcon(
    label: 'Nuts/Seeds',
    faIcon: FontAwesomeIcons.cubes,
    accentColor: Colors.yellowAccent,
  ),
  'oats': IngredientCategoryIcon(
    label: 'Oats/Grains',
    faIcon: FontAwesomeIcons.bowlFood,
    accentColor: Colors.tealAccent,
  ),
};

// Prioritizes and caps ingredient categories (max 4, protein first, then carbs, then others)
List<IngredientCategoryIcon> getPrioritizedIcons(List<String>? tags) {
  if (tags == null) return const [];
  const priority = {
    'meat': 1,
    'fish': 2,
    'egg': 3,
    'rice': 4,
    'bread': 5,
    'oats': 6,
    'dairy': 7,
    'greens': 8,
    'vegetable': 9,
    'fruit': 10,
    'nuts': 11,
  };

  final List<String> matchedTags = tags
      .where((tag) => ingredientIconMap.containsKey(tag))
      .toList();

  matchedTags.sort((a, b) {
    final pA = priority[a] ?? 99;
    final pB = priority[b] ?? 99;
    return pA.compareTo(pB);
  });

  return matchedTags
      .take(4)
      .map((tag) => ingredientIconMap[tag]!)
      .toList();
}
