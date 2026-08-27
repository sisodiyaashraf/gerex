import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/meal_provider.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';

class MealBrowseScreen extends StatefulWidget {
  const MealBrowseScreen({super.key});

  @override
  State<MealBrowseScreen> createState() => _MealBrowseScreenState();
}

class _MealBrowseScreenState extends State<MealBrowseScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDietTag = 'All';
  String _selectedCuisine = 'All';
  String _sortBy = 'Alphabetical';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mealProvider = Provider.of<MealProvider>(context);

    // Categories derived dynamically from recipes list + 'All'
    final categories = [
      'All',
      ...mealProvider.recipes.map((r) => r.category).toSet(),
    ];

    // Filtering recipes
    final filteredRecipes = mealProvider.recipes.where((recipe) {
      final matchesSearch = recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recipe.ingredients.any((ing) => ing.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      final matchesCategory = _selectedCategory == 'All' || recipe.category == _selectedCategory;
      
      final matchesTag = _selectedDietTag == 'All' ||
          (_selectedDietTag == 'Vegetarian' && !(recipe.tags ?? []).contains('meat') && !(recipe.tags ?? []).contains('fish')) ||
          (_selectedDietTag == 'High Protein' && recipe.protein >= 25.0) ||
          (_selectedDietTag == 'Low Carb' && recipe.carbs <= 20.0) ||
          (_selectedDietTag == 'Favorites' && recipe.isFavorite);

      final matchesCuisine = _selectedCuisine == 'All' ||
          (recipe.tags ?? []).contains(_selectedCuisine.toLowerCase());

      return matchesSearch && matchesCategory && matchesTag && matchesCuisine;
    }).toList();

    // Sorting
    if (_sortBy == 'Calories: Low to High') {
      filteredRecipes.sort((a, b) => a.calories.compareTo(b.calories));
    } else if (_sortBy == 'Calories: High to Low') {
      filteredRecipes.sort((a, b) => b.calories.compareTo(a.calories));
    } else if (_sortBy == 'Protein: High to Low') {
      filteredRecipes.sort((a, b) => b.protein.compareTo(a.protein));
    } else if (_sortBy == 'Alphabetical') {
      filteredRecipes.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    // Recommendations (let's show high-protein category items or first 3)
    final recommended = mealProvider.recipes
        .where((r) => r.protein >= 25.0)
        .toList();

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Browse Recipes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
          children: [
            // Glass Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PastelGradientCard(
                type: PastelCardType.slate,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: 16,
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF14181F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Color(0xFF14181F)),
                        decoration: InputDecoration(
                          hintText: 'Search Recipes (e.g. Avocado)...',
                          hintStyle: TextStyle(
                            color: const Color(
                              0xFF14181F,
                            ).withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const IconButton(
                      icon: Icon(Icons.tune_rounded, color: Color(0xFF14181F)),
                      onPressed: null,
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Categories Scroll chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? GerexGradients.primaryCTA
                              : null,
                          color: isSelected
                              ? null
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.05,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Diet Tags Scroll chips
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: const ['All', 'Favorites', 'Vegetarian', 'High Protein', 'Low Carb'].length,
                itemBuilder: (context, index) {
                  final tags = const ['All', 'Favorites', 'Vegetarian', 'High Protein', 'Low Carb'];
                  final tag = tags[index];
                  final isSelected = tag == _selectedDietTag;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDietTag = tag;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.15)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tag == 'Favorites') ...[
                              Icon(
                                isSelected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 12,
                                color: isSelected ? Colors.redAccent : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Dropdowns Row (Cuisine & Sort By)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // Cuisine Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCuisine,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          dropdownColor: theme.cardColor,
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          items: const [
                            'All', 'American', 'British', 'Canadian', 'Chinese', 'French', 'Indian', 'Italian', 'Mexican', 'Jamaican', 'Japanese'
                          ].map((c) => DropdownMenuItem(value: c, child: Text('$c Cuisine'))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCuisine = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          dropdownColor: theme.cardColor,
                          icon: const Icon(Icons.sort_rounded),
                          items: const [
                            'Alphabetical', 'Calories: Low to High', 'Calories: High to Low', 'Protein: High to Low'
                          ].map((s) => DropdownMenuItem(value: s, child: Text('Sort: $s'))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _sortBy = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Recommendation Row
                        if (_selectedCategory == 'All' &&
                            _searchQuery.isEmpty &&
                            _selectedDietTag == 'All' &&
                            _selectedCuisine == 'All' &&
                            recommended.isNotEmpty) ...[
                          Text(
                            'Recommendations for Diet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 155,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: recommended.length,
                              itemBuilder: (context, idx) {
                                final recipe = recommended[idx];
                                return Container(
                                  width: 210,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: PastelGradientCard(
                                    type: PastelCardType.mint,
                                    padding: const EdgeInsets.all(12),
                                    borderRadius: 16,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: const Color(0xFF14181F).withValues(alpha: 0.08),
                                              backgroundImage: recipe.imageUrl != null
                                                  ? CachedNetworkImageProvider(recipe.imageUrl!)
                                                  : null,
                                              child: recipe.imageUrl == null
                                                  ? const Icon(Icons.restaurant_menu_rounded, size: 8, color: Color(0xFF14181F))
                                                  : null,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                recipe.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF14181F),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.star_rounded,
                                              color: Colors.amberAccent[400],
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${recipe.calories.toInt()} kcal • P: ${recipe.protein.toInt()}g',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: const Color(
                                              0xFF14181F,
                                            ).withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF0D807B,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                recipe.category,
                                                style: const TextStyle(
                                                  color: Color(0xFF0D807B),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  visualDensity: VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: Icon(
                                                    recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                    color: recipe.isFavorite ? Colors.redAccent : const Color(0xFF14181F).withValues(alpha: 0.5),
                                                    size: 16,
                                                  ),
                                                  onPressed: () {
                                                    mealProvider.toggleFavoriteRecipe(recipe.id);
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                  ),
                                                  onPressed: () => context.push(
                                                    '/meal-details',
                                                    extra: recipe,
                                                  ),
                                                  child: const Text(
                                                    'View',
                                                    style: TextStyle(fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Main list results section
                        Text(
                          'Popular Recipes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),

                  // Virtualized list of recipe cards
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: filteredRecipes.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No recipes match search criteria.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final recipe = filteredRecipes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: PastelGradientCard(
                                    type: PastelCardType.sunset,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: const Color(0xFF14181F).withValues(alpha: 0.08),
                                          backgroundImage: recipe.imageUrl != null
                                              ? CachedNetworkImageProvider(recipe.imageUrl!)
                                              : null,
                                          child: recipe.imageUrl == null
                                              ? const Icon(
                                                  Icons.restaurant_menu_rounded,
                                                  color: Color(0xFF14181F),
                                                  size: 16,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF14181F),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${recipe.calories.toInt()} kcal • P: ${recipe.protein.toInt()}g • F: ${recipe.fat.toInt()}g',
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
                                            recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: recipe.isFavorite ? Colors.redAccent : const Color(0xFF14181F).withValues(alpha: 0.4),
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            mealProvider.toggleFavoriteRecipe(recipe.id);
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: () => context.push(
                                            '/meal-details',
                                            extra: recipe,
                                          ),
                                          child: const Text(
                                            'View',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: filteredRecipes.length,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
