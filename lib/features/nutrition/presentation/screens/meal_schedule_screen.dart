import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/meal_provider.dart';
import '../../domain/entities/meal_entities.dart';
import '../widgets/concentric_macro_rings.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/theme/app_theme.dart';

class MealScheduleScreen extends StatefulWidget {
  const MealScheduleScreen({super.key});

  @override
  State<MealScheduleScreen> createState() => _MealScheduleScreenState();
}

class _MealScheduleScreenState extends State<MealScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
        _selectedDate.day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealProvider = Provider.of<MealProvider>(context);

    // Filter meals for the selected date
    final dateMeals = mealProvider.mealPlan.where((m) =>
        m.date.day == _selectedDate.day &&
        m.date.month == _selectedDate.month &&
        m.date.year == _selectedDate.year).toList();

    // Grouping helper
    Map<String, List<MealPlanEntry>> groupedMeals = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snack': [],
    };

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final entry in dateMeals) {
      if (groupedMeals.containsKey(entry.mealType)) {
        groupedMeals[entry.mealType]!.add(entry);
      } else {
        groupedMeals['Snack']!.add(entry);
      }
      totalCalories += entry.calories;
      totalProtein += entry.protein;
      totalCarbs += entry.carbs;
      totalFat += entry.fat;
    }

    return Scaffold(
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: GerexGradients.primaryCTA,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => context.push('/meal-browse'),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Custom Month Header Toolbar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Day Selector Bar
            _buildDaySelectorBar(theme),

            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Meal groups
                        ...groupedMeals.entries.map((group) {
                          final typeName = group.key;
                          final list = group.value;
                          final totalGroupCals = list.fold<double>(0.0, (val, item) => val + item.calories);

                          dynamic iconData = FontAwesomeIcons.bowlFood;
                          if (typeName == 'Breakfast') {
                            iconData = FontAwesomeIcons.mugSaucer;
                          } else if (typeName == 'Lunch') {
                            iconData = FontAwesomeIcons.utensils;
                          } else if (typeName == 'Dinner') {
                            iconData = FontAwesomeIcons.bowlFood;
                          } else {
                            iconData = FontAwesomeIcons.cookie;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        typeName,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${list.length} logged • ${totalGroupCals.toInt()} kcal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (list.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: PastelGradientCard(
                                    type: PastelCardType.slate,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'No meals scheduled for $typeName.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...list.map((meal) {
                                  // Look up recipe object in provider recipes list
                                  final recipe = mealProvider.recipes.firstWhere(
                                    (r) => r.id == meal.recipeId,
                                    orElse: () => Recipe(
                                      id: meal.recipeId,
                                      name: meal.recipeName,
                                      author: 'Gerex',
                                      category: meal.mealType,
                                      description: '',
                                      calories: meal.calories,
                                      protein: meal.protein,
                                      carbs: meal.carbs,
                                      fat: meal.fat,
                                      ingredients: const [],
                                      steps: const [],
                                    ),
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Dismissible(
                                      key: ValueKey('dismiss_schedule_meal_${meal.id}'),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (direction) {
                                        mealProvider.deleteMealPlanEntry(meal.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Removed ${meal.recipeName}'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      background: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFDC2626),
                                              Color(0xFFEF4444),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'DELETE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              margin: const EdgeInsets.only(right: 20),
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.3),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.delete_forever_rounded,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => context.push('/meal-details', extra: recipe),
                                        child: PastelGradientCard(
                                          type: typeName == 'Dinner'
                                              ? PastelCardType.indigo
                                              : (typeName == 'Snack' ? PastelCardType.mint : PastelCardType.sunset),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: const Color(0xFF14181F).withValues(alpha: 0.08),
                                                backgroundImage: meal.imagePath != null ? FileImage(File(meal.imagePath!)) : null,
                                                child: meal.imagePath != null ? null : (typeName == 'Breakfast'
                                                    ? Image.asset('assets/images/breakfast_icon.png', color: const Color(0xFF14181F), width: 22, height: 22)
                                                    : typeName == 'Dinner'
                                                        ? Image.asset('assets/images/dinner_icon.png', color: const Color(0xFF14181F), width: 22, height: 22)
                                                        : typeName == 'Lunch'
                                                            ? Image.asset('assets/images/lunch_icon.png', color: const Color(0xFF14181F), width: 22, height: 22)
                                                            : typeName == 'Snack'
                                                                ? Image.asset('assets/images/snack_icon.png', color: const Color(0xFF14181F), width: 22, height: 22)
                                                                : FaIcon(iconData as FaIconData, color: const Color(0xFF14181F), size: 16)),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      meal.recipeName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: Color(0xFF14181F),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${meal.calories.toInt()} kcal • P: ${meal.protein.toInt()}g • C: ${meal.carbs.toInt()}g',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 12,
                                                color: Color(0xFF14181F),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),

                        const SizedBox(height: 24),

                        // Bottom daily progress nutrient targets
                        Text(
                          'Daily Macro Nutrient Tracker',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ConcentricMacroRings(
                                calories: totalCalories,
                                caloriesGoal: 2500.0,
                                protein: totalProtein,
                                proteinGoal: 150.0,
                                carbs: totalCarbs,
                                carbsGoal: 300.0,
                                fat: totalFat,
                                fatGoal: 80.0,
                              ),
                              const SizedBox(height: 20),
                              Divider(color: theme.colorScheme.onSurface.withOpacity(0.1)),
                              const SizedBox(height: 12),
                              _buildNutrientProgressBar(theme, 'Calories', totalCalories, 2500, 'kcal', Colors.orangeAccent),
                              const SizedBox(height: 12),
                              _buildNutrientProgressBar(theme, 'Protein', totalProtein, 150, 'g', Colors.greenAccent),
                              const SizedBox(height: 12),
                              _buildNutrientProgressBar(theme, 'Carbs', totalCarbs, 300, 'g', Colors.blueAccent),
                              const SizedBox(height: 12),
                              _buildNutrientProgressBar(theme, 'Fats', totalFat, 80, 'g', Colors.pinkAccent),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientProgressBar(ThemeData theme, String label, double current, double target, String unit, Color progressColor) {
    final double fraction = (target > 0 ? (current / target) : 0.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(
              '${current.toInt()} / ${target.toInt()} $unit',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelectorBar(ThemeData theme) {
    // Generate week array surrounding selected date
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final days = List.generate(7, (idx) => weekStart.add(Duration(days: idx)));
    final weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = days[index];
          final isSelected = day.day == _selectedDate.day &&
              day.month == _selectedDate.month &&
              day.year == _selectedDate.year;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected ? GerexGradients.primaryCTA : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayNames[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
