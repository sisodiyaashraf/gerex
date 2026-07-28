import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/meal_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/big_stat_number.dart';
import 'package:gerex/core/presentation/widgets/gerex_line_chart.dart';
import 'package:gerex/core/presentation/widgets/segmented_pill_nav.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/presentation/utils/responsive_helper.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  int _selectedFilterIdx = 0;
  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  void _openFoodBrowser(BuildContext context, String category, MealProvider provider) {
    final filtered = provider.recipes.where((r) => r.category == category).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textDarkMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Browse $category Recipes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDarkHeading,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final rec = filtered[idx];
                  return Card(
                    color: Colors.transparent,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textDarkHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rec.calories.toInt()} kcal • P: ${rec.protein.toInt()}g • C: ${rec.carbs.toInt()}g',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textDarkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentEmeraldLight,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/meal-details', extra: rec);
                            },
                            child: const Text('View', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealProvider = Provider.of<MealProvider>(context);

    final selectedCategory = _categories[_selectedFilterIdx];

    final today = DateTime.now();
    final todayMeals = mealProvider.mealPlan.where((m) =>
        m.date.day == today.day &&
        m.date.month == today.month &&
        m.date.year == today.year &&
        m.mealType == selectedCategory).toList();

    const List<GerexLineChartPoint> calorieTrendPoints = [
      GerexLineChartPoint(label: 'Mon', value: 1850),
      GerexLineChartPoint(label: 'Tue', value: 2100),
      GerexLineChartPoint(label: 'Wed', value: 1750),
      GerexLineChartPoint(label: 'Thu', value: 1980),
      GerexLineChartPoint(label: 'Fri', value: 2200),
      GerexLineChartPoint(label: 'Sat', value: 1900),
      GerexLineChartPoint(label: 'Sun', value: 1820),
    ];

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Meal Planner',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.textDarkHeading),
            onPressed: () => context.push('/meal-schedule'),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textDarkHeading),
            onPressed: () => context.push('/meal-browse'),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Signature Hero Mint Header Card
                HeroMintCard(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Calorie Target',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLightBody.withValues(alpha: 0.7),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.badgeDarkNavy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Target: 2,200 kcal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentEmeraldLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const BigStatNumber(
                        number: '1,850',
                        label: 'Calories Consumed Today',
                        unit: 'KCAL',
                        isDarkCard: false,
                      ),
                    ],
                  ),
                ),

                Text(
                  'Nutrient Trends (Past 7 Days)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkHeading,
                  ),
                ),
                const SizedBox(height: 12),

                const GlassContainer(
                  padding: EdgeInsets.all(16),
                  child: GerexLineChart(
                    data: calorieTrendPoints,
                    unit: 'kcal',
                    height: 180,
                  ),
                ),
                const SizedBox(height: 24),

                  // Daily meals schedule selection
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Today\'s Meals List',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDarkHeading),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedPillNav(
                          options: _categories,
                          selectedIndex: _selectedFilterIdx,
                          onSelected: (idx) {
                            setState(() => _selectedFilterIdx = idx);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (todayMeals.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No meals logged for $selectedCategory.',
                          style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else
                    ...todayMeals.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.restaurant_menu_rounded, color: theme.colorScheme.primary, size: 18),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.recipeName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${entry.calories.toInt()} kcal • P: ${entry.protein.toInt()}g • C: ${entry.carbs.toInt()}g • F: ${entry.fat.toInt()}g',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        entry.notificationEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                                        color: entry.notificationEnabled ? theme.colorScheme.primary : Colors.grey,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        mealProvider.toggleMealNotification(entry.id, !entry.notificationEnabled);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      onPressed: () {
                                        mealProvider.deleteMealPlanEntry(entry.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Find something to eat categories
                  Text(
                    'Find Something to Eat',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryRow(context, mealProvider),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, MealProvider provider) {
    final categories = [
      {'name': 'Breakfast', 'icon': FontAwesomeIcons.mugSaucer, 'color': Colors.amberAccent},
      {'name': 'Lunch', 'icon': FontAwesomeIcons.utensils, 'color': Colors.orangeAccent},
      {'name': 'Dinner', 'icon': FontAwesomeIcons.bowlFood, 'color': Colors.indigoAccent},
      {'name': 'Snack', 'icon': FontAwesomeIcons.cookie, 'color': Colors.lightGreenAccent},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isTablet ? 4 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, idx) {
        final cat = categories[idx];
        final name = cat['name'] as String;
        final icon = cat['icon'] as FaIconData;
        final color = cat['color'] as Color;
        final count = provider.recipes.where((r) => r.category == name).length;

        return GestureDetector(
          onTap: () => _openFoodBrowser(context, name, provider),
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, color: color, size: 20),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  '$count options',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


