import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/exercise_provider.dart';
import '../../domain/entities/exercise.dart';
import '../widgets/exercise_image_widget.dart';
import 'package:gerex/core/presentation/widgets/gerex_animated_list_tile.dart';
import 'package:gerex/core/presentation/widgets/gerex_staggered_list_view.dart';
import 'package:gerex/core/presentation/widgets/difficulty_tag.dart';
import 'package:gerex/core/theme/app_theme.dart';

class ExerciseBrowseScreen extends StatefulWidget {
  const ExerciseBrowseScreen({super.key});

  @override
  State<ExerciseBrowseScreen> createState() => _ExerciseBrowseScreenState();
}

class _ExerciseBrowseScreenState extends State<ExerciseBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _muscles = [
    'All',
    'Abdominals',
    'Chest',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Forearms',
    'Lats',
    'Middle Back',
    'Lower Back',
    'Quadriceps',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Trapezius',
  ];

  final List<String> _equipments = [
    'All',
    'Body only',
    'Dumbbell',
    'Barbell',
    'Cable',
    'Kettlebell',
    'Machine',
    'Bands',
    'Medicine Ball',
    'Exercise Ball',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExerciseProvider>();
      provider.loadExercises();
      _searchController.text = provider.searchQuery;
    });

    _searchController.addListener(() {
      context.read<ExerciseProvider>().search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ExerciseProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    const accentColor = Color(0xFF10B981); // Emerald Green

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Exercise Database',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface),
            onPressed: () => provider.loadExercises(),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
            // Decorative glow blobs
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
                      color: accentColor.withValues(alpha: isDark ? 0.15 : 0.06),
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
                      color: accentColor.withValues(alpha: isDark ? 0.1 : 0.04),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Search Input inside modern Translucent/Glass Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                          width: 1.5,
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Find your next challenge',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.05),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search 800+ exercises...',
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchController.clear();
                                          provider.search('');
                                        },
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          size: 18,
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Muscle Filters Row
                  _buildFilterLabel('Target Muscle Group'),
                  const SizedBox(height: 8),
                  _buildFilterRow(
                    items: _muscles,
                    selectedItem: provider.selectedMuscle ?? 'All',
                    onSelected: (val) => provider.filterByMuscle(val),
                    theme: theme,
                  ),
                  const SizedBox(height: 16),

                  // Equipment Filters Row
                  _buildFilterLabel('Equipment Type'),
                  const SizedBox(height: 8),
                  _buildFilterRow(
                    items: _equipments,
                    selectedItem: provider.selectedEquipment ?? 'All',
                    onSelected: (val) => provider.filterByEquipment(val),
                    theme: theme,
                  ),
                  const SizedBox(height: 16),

                  // Results List
                  Expanded(
                    child: provider.isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : provider.exercises.isEmpty
                            ? _buildEmptyState(theme)
                            : GerexStaggeredListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                estimatedItemHeight: 96.0,
                                children: provider.exercises.map((exercise) {
                                  return _buildExerciseCard(context, exercise, theme);
                                }).toList(),
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

  Widget _buildFilterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDarkMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow({
    required List<String> items,
    required String selectedItem,
    required Function(String) onSelected,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItem.toLowerCase() == item.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected ? GerexGradients.primaryCTA : null,
                  color: isSelected
                      ? null
                      : isDark
                          ? theme.colorScheme.surface.withValues(alpha: 0.3)
                          : theme.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.5)
                        : theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getExerciseIcon(Exercise ex) {
    final cat = ex.category.toLowerCase();
    if (cat.contains('stretch') || cat.contains('flexibility')) {
      return Icons.accessibility_new_rounded;
    }
    if (cat.contains('cardio') || cat.contains('aerobic')) {
      return Icons.favorite_rounded;
    }
    if (cat.contains('powerlifting') || cat.contains('strength')) {
      return Icons.fitness_center_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  double _getExerciseProgress(Exercise ex) {
    final lvl = ex.level.toLowerCase();
    if (lvl == 'beginner') return 0.35;
    if (lvl == 'intermediate') return 0.70;
    return 1.0;
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise, ThemeData theme) {
    return GerexAnimatedListTile(
      title: exercise.name,
      subtitle: '${exercise.equipment} • ${exercise.muscleGroup}',
      leadingIcon: _getExerciseIcon(exercise),
      progress: _getExerciseProgress(exercise),
      leadingWidget: Hero(
        tag: 'exercise_img_${exercise.id}',
        child: ExerciseImageWidget(
          imagePath: exercise.imageUrl,
          size: 44.0,
        ),
      ),
      actions: [
        GerexListTileAction(
          icon: Icons.bookmark_rounded,
          color: AppColors.accentEmeraldDeep,
          label: 'Save',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved ${exercise.name} to bookmarks!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        GerexListTileAction(
          icon: Icons.delete_outline_rounded,
          color: AppColors.destructiveRed,
          label: 'Remove',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed ${exercise.name} from bookmarks!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
      expandedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Instructions Guide',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.accentEmeraldLight,
                ),
              ),
              DifficultyTag.fromText(exercise.level),
            ],
          ),
          const SizedBox(height: 10),
          if (exercise.instructions.isEmpty)
            Text(
              'No instructions registered for this exercise.',
              style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
            )
          else
            ...exercise.instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmeraldLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentEmeraldLight,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.textDarkBody
                              : AppColors.textLightBody,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentEmeraldDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: const Icon(Icons.info_outline_rounded, size: 14),
            label: const Text('View Full Guide & Log Reps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              context.push(
                '/exercise-detail',
                extra: {
                  'exercise': exercise,
                  'isPicker': false,
                },
              );
            },
          ),
        ],
      ),
      onTap: () {
        context.push(
          '/exercise-detail',
          extra: {
            'exercise': exercise,
            'isPicker': false,
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardDarkGlass.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(
              FontAwesomeIcons.circleExclamation,
              size: 40,
              color: AppColors.destructiveRed,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Exercises Found',
            style: GoogleFonts.outfit(
              color: AppColors.textDarkHeading,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try widening your search or active filters.',
            style: TextStyle(
              color: AppColors.textDarkMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.read<ExerciseProvider>().clearFilters();
              _searchController.clear();
            },
            child: const Text(
              'Reset Filters',
              style: TextStyle(
                color: AppColors.accentEmeraldLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}