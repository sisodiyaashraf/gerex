import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/meal_provider.dart';
import 'package:gerex/core/utils/logger.dart';

import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
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
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: GerexGradients.scaffoldBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Browse $category Recipes',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final rec = filtered[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PastelGradientCard(
                      type: category == 'Breakfast'
                          ? PastelCardType.mint
                          : (category == 'Lunch' ? PastelCardType.sunset : PastelCardType.indigo),
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
                                    color: Color(0xFF14181F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rec.calories.toInt()} kcal • P: ${rec.protein.toInt()}g • C: ${rec.carbs.toInt()}g',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF14181F),
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
          icon: Icon(Icons.add_circle_outline_rounded, color: AppColors.textDarkHeading),
          onPressed: () => _showLogMealDialog(context, mealProvider),
        ),
        IconButton(
          icon: Icon(Icons.calendar_month_rounded, color: AppColors.textDarkHeading),
          onPressed: () => context.push('/meal-schedule'),
        ),
        IconButton(
          icon: Icon(Icons.search_rounded, color: AppColors.textDarkHeading),
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

                const PastelGradientCard(
                  type: PastelCardType.slate,
                  padding: EdgeInsets.all(16),
                  child: GerexLineChart(
                    data: calorieTrendPoints,
                    unit: 'kcal',
                    height: 180,
                  ),
                ),
                const SizedBox(height: 24),

                  // Daily meals schedule selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Meals List',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDarkHeading,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedPillNav(
                        options: _categories,
                        selectedIndex: _selectedFilterIdx,
                        onSelected: (idx) {
                          setState(() => _selectedFilterIdx = idx);
                        },
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
                          style: TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                        ),
                      ),
                    ),
                  ] else
                    ...todayMeals.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Dismissible(
                            key: ValueKey('dismiss_meal_${entry.id}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              mealProvider.deleteMealPlanEntry(entry.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed ${entry.recipeName}'),
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
                            child: PastelGradientCard(
                              type: PastelCardType.sunset,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF14181F).withValues(alpha: 0.08),
                                    child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF14181F), size: 18),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.recipeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF14181F),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${entry.calories.toInt()} kcal • P: ${entry.protein.toInt()}g • C: ${entry.carbs.toInt()}g • F: ${entry.fat.toInt()}g',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      entry.notificationEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                                      color: const Color(0xFF14181F),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      mealProvider.toggleMealNotification(entry.id, !entry.notificationEnabled);
                                    },
                                  ),
                                ],
                              ),
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
        final count = provider.recipes.where((r) => r.category == name).length;

        PastelCardType containerType = PastelCardType.sunset;
        if (name == 'Dinner') containerType = PastelCardType.indigo;
        if (name == 'Snack') containerType = PastelCardType.mint;

        return GestureDetector(
          onTap: () => _openFoodBrowser(context, name, provider),
          child: PastelGradientCard(
            type: containerType,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                name == 'Breakfast'
                    ? Image.asset('assets/images/breakfast_icon.png', color: const Color(0xFFB8860B), width: 32, height: 32)
                    : name == 'Dinner'
                        ? Image.asset('assets/images/dinner_icon.png', color: const Color(0xFF3F51B5), width: 32, height: 32)
                        : name == 'Lunch'
                            ? Image.asset('assets/images/lunch_icon.png', color: const Color(0xFFD84315), width: 32, height: 32)
                            : name == 'Snack'
                                ? Image.asset('assets/images/snack_icon.png', color: const Color(0xFF2E7D32), width: 32, height: 32)
                                : FaIcon(icon, color: const Color(0xFF2E7D32), size: 26),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF14181F),
                  ),
                ),
                Text(
                  '$count options',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF14181F).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _lookupOpenFoodFacts(String barcode) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json');
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body);
        if (data['status'] == 1 && data['product'] != null) {
          final prod = data['product'];
          final nut = prod['nutriments'] ?? {};
          return {
            'name': prod['product_name'] ?? 'Unknown Scanned Food',
            'calories': double.tryParse(nut['energy-kcal_100g']?.toString() ?? '') ?? 0.0,
            'protein': double.tryParse(nut['proteins_100g']?.toString() ?? '') ?? 0.0,
            'carbs': double.tryParse(nut['carbohydrates_100g']?.toString() ?? '') ?? 0.0,
            'fat': double.tryParse(nut['fat_100g']?.toString() ?? '') ?? 0.0,
          };
        }
      }
    } catch (e) {
      SecureLogger.logError('MealPlanner: OpenFoodFacts lookup failed', e);
    }
    return null;
  }

  void _showLogMealDialog(BuildContext context, MealProvider provider) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String selectedMealType = _categories[_selectedFilterIdx];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardDarkGlass,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Log Custom Meal',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.accentEmeraldLight),
                    tooltip: 'Scan Barcode',
                    onPressed: isSearching
                        ? null
                        : () async {
                            final barcode = await context.push('/meal-barcode-scanner');
                            if (barcode != null && barcode is String) {
                              setState(() {
                                isSearching = true;
                              });
                              final product = await _lookupOpenFoodFacts(barcode);
                              setState(() {
                                isSearching = false;
                                if (product != null) {
                                  nameController.text = product['name'];
                                  caloriesController.text = product['calories'].toStringAsFixed(0);
                                  proteinController.text = product['protein'].toStringAsFixed(1);
                                  carbsController.text = product['carbs'].toStringAsFixed(1);
                                  fatController.text = product['fat'].toStringAsFixed(1);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Auto-filled: ${product['name']}'),
                                      backgroundColor: AppColors.accentEmeraldLight,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Product not found. Please log manually.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              });
                            }
                          },
                  ),
                ],
              ),
              content: isSearching
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.accentEmeraldLight),
                            SizedBox(height: 16),
                            Text(
                              'Searching Open Food Facts...',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Meal Name',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedMealType,
                            dropdownColor: AppColors.cardDarkGlass,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Meal Category',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            ),
                            items: _categories.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                selectedMealType = val;
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: caloriesController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Calories (kcal)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: proteinController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Protein (g)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: carbsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Carbs (g)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: fatController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Fat (g)',
                              labelStyle: TextStyle(color: Colors.white70),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                            ),
                          ),
                        ],
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentEmeraldLight,
                    foregroundColor: const Color(0xFF14181F),
                  ),
                  onPressed: isSearching
                      ? null
                      : () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a meal name')),
                            );
                            return;
                          }
                          final calories = double.tryParse(caloriesController.text) ?? 0.0;
                          final protein = double.tryParse(proteinController.text) ?? 0.0;
                          final carbs = double.tryParse(carbsController.text) ?? 0.0;
                          final fat = double.tryParse(fatController.text) ?? 0.0;

                          provider.addCustomMealEntry(
                            name: name,
                            mealType: selectedMealType,
                            calories: calories,
                            protein: protein,
                            carbs: carbs,
                            fat: fat,
                            date: DateTime.now(),
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logged "$name" successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
