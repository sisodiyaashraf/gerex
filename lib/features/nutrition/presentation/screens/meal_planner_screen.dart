import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/meal_provider.dart';
import '../../domain/entities/meal_entities.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/utils/responsive_helper.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  String _selectedFilterType = 'Breakfast';

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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Browse $category Recipes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rec.calories.toInt()} kcal • P: ${rec.protein.toInt()}g • C: ${rec.carbs.toInt()}g',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
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

    // Filter meals for today
    final today = DateTime.now();
    final todayMeals = mealProvider.mealPlan.where((m) =>
        m.date.day == today.day &&
        m.date.month == today.month &&
        m.date.year == today.year &&
        m.mealType == _selectedFilterType).toList();

    return Scaffold(
      body: LiquidBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: () => context.push('/meal-schedule'),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => context.push('/meal-browse'),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Meal Planner',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Analytics section title
                  Text(
                    'Nutrient Trends (Past 7 Days)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Weekly Calorie Trend Chart
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: mealProvider.mealPlan.isEmpty
                              ? const Center(child: Text('No nutrition logs registered.'))
                              : CustomPaint(
                                  painter: _NutrientChartPainter(
                                    theme: theme,
                                    plans: mealProvider.mealPlan,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendItem(theme, Colors.orangeAccent, 'Calories'),
                            _buildLegendItem(theme, Colors.greenAccent, 'Protein'),
                            _buildLegendItem(theme, Colors.blueAccent, 'Carbs'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daily meals schedule selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Meals List',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      DropdownButton<String>(
                        value: _selectedFilterType,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                          DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                          DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                          DropdownMenuItem(value: 'Snack', child: Text('Snacks')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedFilterType = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (todayMeals.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No meals logged for $_selectedFilterType.',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13),
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
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
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

class _NutrientChartPainter extends CustomPainter {
  final ThemeData theme;
  final List<MealPlanEntry> plans;

  _NutrientChartPainter({required this.theme, required this.plans});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    const double paddingTop = 16.0;
    const double paddingBottom = 20.0;

    final double width = size.width - paddingLeft - paddingRight;
    final double height = size.height - paddingTop - paddingBottom;

    if (plans.isEmpty) return;

    // Group logs by weekday date
    final dailyTotals = <String, double>{};
    final dailyProtein = <String, double>{};
    final dailyCarbs = <String, double>{};
    final now = DateTime.now();

    final List<DateTime> last7Days = List.generate(7, (idx) => now.subtract(Duration(days: 6 - idx)));

    for (final day in last7Days) {
      final key = '${day.year}-${day.month}-${day.day}';
      dailyTotals[key] = 0.0;
      dailyProtein[key] = 0.0;
      dailyCarbs[key] = 0.0;

      final matched = plans.where((m) => m.date.day == day.day && m.date.month == day.month && m.date.year == day.year);
      for (final m in matched) {
        dailyTotals[key] = dailyTotals[key]! + m.calories;
        dailyProtein[key] = dailyProtein[key]! + m.protein;
        dailyCarbs[key] = dailyCarbs[key]! + m.carbs;
      }
    }

    final values = dailyTotals.values.toList();
    double maxCal = 1500.0;
    for (final v in values) {
      if (v > maxCal) maxCal = v;
    }
    double minCal = 0.0;

    final double valRange = maxCal - minCal;

    final paintGrid = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      fontSize: 9,
    );

    // Draw horizontal grid lines
    for (int i = 0; i <= 2; i++) {
      final y = paddingTop + height * (i / 2.0);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      final val = maxCal - valRange * (i / 2.0);
      final textSpan = TextSpan(text: '${val.toStringAsFixed(0)} kcal', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    final pointsCal = <Offset>[];
    final pointsProtein = <Offset>[];
    final pointsCarbs = <Offset>[];

    for (int i = 0; i < last7Days.length; i++) {
      final key = '${last7Days[i].year}-${last7Days[i].month}-${last7Days[i].day}';
      final x = paddingLeft + width * (i / 6.0);

      // Calories plot
      final double normCal = (dailyTotals[key]! - minCal) / valRange;
      final yCal = paddingTop + height * (1.0 - normCal.clamp(0.0, 1.0));
      pointsCal.add(Offset(x, yCal));

      // Protein plot (scaled x10 to visually fit on same chart)
      final double normProt = ((dailyProtein[key]! * 10) - minCal) / valRange;
      final yProt = paddingTop + height * (1.0 - normProt.clamp(0.0, 1.0));
      pointsProtein.add(Offset(x, yProt));

      // Carbs plot (scaled x5 to fit on same chart)
      final double normCarbs = ((dailyCarbs[key]! * 5) - minCal) / valRange;
      final yCarb = paddingTop + height * (1.0 - normCarbs.clamp(0.0, 1.0));
      pointsCarbs.add(Offset(x, yCarb));
    }

    // Helper to draw a curve path line
    void drawCurve(List<Offset> pts, Color color) {
      final paintLine = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paintLine);

      // Draw point dots
      final dotPaint = Paint()..color = color;
      final strokePaint = Paint()
        ..color = theme.colorScheme.surface
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      for (final p in pts) {
        canvas.drawCircle(p, 4.0, dotPaint);
        canvas.drawCircle(p, 4.0, strokePaint);
      }
    }

    drawCurve(pointsCal, Colors.orangeAccent);
    drawCurve(pointsProtein, Colors.greenAccent);
    drawCurve(pointsCarbs, Colors.blueAccent);

    // Weekdays names
    final weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (int i = 0; i < last7Days.length; i++) {
      final x = paddingLeft + width * (i / 6.0);
      final name = weekdayNames[(last7Days[i].weekday - 1) % 7];
      final textSpan = TextSpan(text: name, style: textStyle.copyWith(fontWeight: FontWeight.bold));
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - paddingBottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
