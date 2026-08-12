import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/meal_provider.dart';
import '../../domain/entities/meal_entities.dart';
import 'package:gerex/core/theme/app_theme.dart';
import '../../domain/ingredient_icon_map.dart';

class MealDetailsScreen extends StatefulWidget {
  final Recipe recipe;
  const MealDetailsScreen({super.key, required this.recipe});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealProvider = Provider.of<MealProvider>(context);

    // Sync favorite state
    final currentRecipe = mealProvider.recipes.firstWhere(
      (r) => r.id == widget.recipe.id,
      orElse: () => widget.recipe,
    );
    final isFavorite = currentRecipe.isFavorite;

    Color categoryColor = theme.colorScheme.primary;
    if (currentRecipe.category == 'Breakfast') {
      categoryColor = const Color(0xFFB8860B);
    } else if (currentRecipe.category == 'Lunch') {
      categoryColor = const Color(0xFFD84315);
    } else if (currentRecipe.category == 'Dinner') {
      categoryColor = const Color(0xFF3F51B5);
    } else if (currentRecipe.category == 'Snack') {
      categoryColor = const Color(0xFF2E7D32);
    }

    final isDark = theme.brightness == Brightness.dark;
    final categoryGradients = {
      'Breakfast': LinearGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.15),
          isDark ? const Color(0xFF14181F).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'Lunch': LinearGradient(
        colors: [
          const Color(0xFFF97316).withValues(alpha: 0.15),
          isDark ? const Color(0xFF14181F).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'Dinner': LinearGradient(
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.15),
          isDark ? const Color(0xFF14181F).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'Snack': LinearGradient(
        colors: [
          const Color(0xFF22C55E).withValues(alpha: 0.15),
          isDark ? const Color(0xFF14181F).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    };
    final headerGradient = categoryGradients[currentRecipe.category] ?? (isDark ? GerexGradients.scaffoldBackground : const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFEEF2F6)]));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F1319), const Color(0xFF14181F)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEEF2F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Category-specific glow blobs in background
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: isDark ? 0.15 : 0.06),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -150,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: isDark ? 0.1 : 0.04),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      currentRecipe.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: headerGradient,
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                categoryColor.withValues(alpha: 0.3),
                                categoryColor.withValues(alpha: 0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                border: Border.all(
                                  color: categoryColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Image.asset(
                                  currentRecipe.category == 'Breakfast'
                                      ? 'assets/images/breakfast_icon.png'
                                      : currentRecipe.category == 'Lunch'
                                          ? 'assets/images/lunch_icon.png'
                                          : currentRecipe.category == 'Dinner'
                                              ? 'assets/images/dinner_icon.png'
                                              : 'assets/images/snack_icon.png',
                                  width: 44,
                                  height: 44,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: FaIcon(
                        isFavorite
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        color: isFavorite
                            ? Colors.redAccent
                            : theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () {
                        mealProvider.toggleFavoriteRecipe(currentRecipe.id);
                      },
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Author line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'By ${currentRecipe.author}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                           Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: categoryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              currentRecipe.category.toUpperCase(),
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nutritional chips row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildNutrientChip(
                            theme,
                            '${currentRecipe.calories.toInt()} kcal',
                            'Calories',
                            Colors.orangeAccent,
                            FontAwesomeIcons.fire,
                          ),
                          _buildNutrientChip(
                            theme,
                            '${currentRecipe.protein.toInt()}g',
                            'Protein',
                            Colors.greenAccent,
                            FontAwesomeIcons.dumbbell,
                          ),
                          _buildNutrientChip(
                            theme,
                            '${currentRecipe.carbs.toInt()}g',
                            'Carbs',
                            Colors.blueAccent,
                            FontAwesomeIcons.wheatAwn,
                          ),
                          _buildNutrientChip(
                            theme,
                            '${currentRecipe.fat.toInt()}g',
                            'Fats',
                            Colors.pinkAccent,
                            FontAwesomeIcons.droplet,
                          ),
                        ],
                      ),
                      // Ingredient matching icons row
                      Builder(
                        builder: (context) {
                          final matchedIcons = getPrioritizedIcons(currentRecipe.tags);
                          if (matchedIcons.isEmpty) return const SizedBox(height: 24);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KEY INGREDIENTS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: matchedIcons.map((item) => _buildIngredientIconBadge(theme, item)).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Description
                      _buildSectionHeader('Description', categoryColor, theme),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(
                          () =>
                              _isDescriptionExpanded = !_isDescriptionExpanded,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border(
                              left: BorderSide(
                                color: categoryColor,
                                width: 3,
                              ),
                            ),
                            boxShadow: isDark ? null : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentRecipe.description,
                                maxLines: _isDescriptionExpanded ? null : 3,
                                overflow: _isDescriptionExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDescriptionExpanded
                                    ? 'Read Less'
                                    : 'Read More',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: categoryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Ingredients
                      _buildSectionHeader('Ingredients You Will Need', categoryColor, theme),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentRecipe.ingredients.length,
                        itemBuilder: (context, idx) {
                          final ing = currentRecipe.ingredients[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                                  width: 1,
                                ),
                                boxShadow: isDark ? null : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: categoryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      ing,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Step by Step directions
                      _buildSectionHeader('Step by Step Instructions', categoryColor, theme),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentRecipe.steps.length,
                        itemBuilder: (context, idx) {
                          final step = currentRecipe.steps[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: categoryColor.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: categoryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        color: categoryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                                        width: 1,
                                      ),
                                      boxShadow: isDark ? null : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      step,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 100), // Space for sticky button
                    ]),
                  ),
                ),
              ],
            ),

            // Sticky Bottom Add button
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  gradient: GerexGradients.primaryCTA,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    mealProvider.addMealPlanEntry(
                      currentRecipe,
                      currentRecipe.category,
                      DateTime.now(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added ${currentRecipe.name} to today\'s ${currentRecipe.category} meal plan!',
                        ),
                      ),
                    );
                    context.pop();
                  },
                  child: Text(
                    'Add to ${currentRecipe.category} Meal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(
    ThemeData theme,
    String value,
    String label,
    Color color,
    dynamic icon,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.03),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: color,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientIconBadge(
    ThemeData theme,
    IngredientCategoryIcon item,
  ) {
    return Tooltip(
      message: 'Contains ${item.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: item.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              item.faIcon,
              size: 11,
              color: item.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
