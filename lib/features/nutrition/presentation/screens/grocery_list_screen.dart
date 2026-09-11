import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/grocery_item.dart';
import '../providers/grocery_provider.dart';
import '../providers/meal_provider.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final TextEditingController _addItemController = TextEditingController();
  GroceryCategory _selectedAddCategory = GroceryCategory.produce;
  GroceryCategory? _selectedFilterCategory;

  static const Color accentMint = Color(0xFF10B981);

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  void _onAddItem(GroceryProvider provider) {
    final text = _addItemController.text.trim();
    if (text.isEmpty) return;

    provider.addItem(
      name: text,
      category: _selectedAddCategory,
    );
    _addItemController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$text" to shopping list'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onGenerateFromMealPlan(GroceryProvider groceryProvider, MealProvider mealProvider) {
    final added = groceryProvider.generateFromMealPlan(
      mealProvider.mealPlan,
      mealProvider.recipes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? 'Added $added new ingredients from your active meal plan!'
              : 'All ingredients from your meal plan are already in your list.',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onShareList(GroceryProvider provider) {
    final text = provider.buildShareableText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shopping list copied to clipboard! ready to share 📋'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    final items = _selectedFilterCategory == null
        ? groceryProvider.items
        : groceryProvider.items.where((i) => i.category == _selectedFilterCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDarkPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Shopping List',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: accentMint),
            tooltip: 'Share / Copy List',
            onPressed: () => _onShareList(groceryProvider),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: const Color(0xFF1E293B),
            onSelected: (val) {
              if (val == 'clear_checked') {
                groceryProvider.clearChecked();
              } else if (val == 'clear_all') {
                groceryProvider.clearAll();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clear_checked',
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services_rounded, color: accentMint, size: 20),
                    const SizedBox(width: 12),
                    Text('Clear Purchased Items', style: GoogleFonts.inter(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text('Clear All Items', style: GoogleFonts.inter(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: HeroMintCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pantry & Groceries',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${groceryProvider.checkedCount} of ${groceryProvider.totalCount} items completed',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentMint.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentMint.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${(groceryProvider.progressRatio * 100).toInt()}% Done',
                            style: GoogleFonts.outfit(
                              color: accentMint,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: groceryProvider.progressRatio,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(accentMint),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _onGenerateFromMealPlan(groceryProvider, mealProvider),
                        icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 16, color: Colors.black87),
                        label: Text(
                          'Generate from Meal Plan',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentMint,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter Pills
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildFilterChip(
                    label: 'All Items',
                    icon: Icons.all_inclusive_rounded,
                    isSelected: _selectedFilterCategory == null,
                    onTap: () => setState(() => _selectedFilterCategory = null),
                  ),
                  ...GroceryCategory.values.map(
                    (cat) => _buildFilterChip(
                      label: cat.displayName,
                      icon: cat.icon,
                      isSelected: _selectedFilterCategory == cat,
                      color: cat.categoryColor,
                      onTap: () => setState(() => _selectedFilterCategory = cat),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Items List View
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState(groceryProvider)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildGroceryTile(item, groceryProvider);
                      },
                    ),
            ),

            // Add Item Input Bar
            _buildQuickAddBar(groceryProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? accentMint;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? chipColor.withValues(alpha: 0.25) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? chipColor : Colors.white10,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? chipColor : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroceryTile(GroceryItem item, GroceryProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isChecked
              ? Colors.white10
              : item.category.categoryColor.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: () => provider.toggleItem(item.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.isChecked
                  ? accentMint
                  : Colors.transparent,
              border: Border.all(
                color: item.isChecked ? accentMint : Colors.white38,
                width: 2,
              ),
            ),
            child: item.isChecked
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.black)
                : null,
          ),
        ),
        title: Text(
          item.name,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: item.isChecked ? Colors.white38 : Colors.white,
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            decorationColor: accentMint,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.category.categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.category.icon, size: 12, color: item.category.categoryColor),
                  const SizedBox(width: 4),
                  Text(
                    item.category.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: item.category.categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (item.sourceRecipe != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• ${item.sourceRecipe}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ),
            ]
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 20),
          onPressed: () => provider.removeItem(item.id),
        ),
      ),
    );
  }

  Widget _buildEmptyState(GroceryProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentMint.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 64,
                color: accentMint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Shopping List is Clear!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items manually below or automatically generate ingredients from your active meal plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddBar(GroceryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Category Selector Button
              PopupMenuButton<GroceryCategory>(
                initialValue: _selectedAddCategory,
                tooltip: 'Select Category',
                onSelected: (cat) => setState(() => _selectedAddCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedAddCategory.categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedAddCategory.categoryColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(_selectedAddCategory.icon, size: 18, color: _selectedAddCategory.categoryColor),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => GroceryCategory.values.map((cat) {
                  return PopupMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.categoryColor, size: 18),
                        const SizedBox(width: 10),
                        Text(cat.displayName, style: GoogleFonts.inter(color: Colors.white)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 10),
              // Input Field
              Expanded(
                child: TextField(
                  controller: _addItemController,
                  onSubmitted: (_) => _onAddItem(provider),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Add grocery item (e.g. Almond Milk)...',
                    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Add Button
              IconButton.filled(
                onPressed: () => _onAddItem(provider),
                icon: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: accentMint,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
