import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gerex/core/presentation/widgets/gerex_animated_list_tile.dart';
import 'package:gerex/core/presentation/widgets/gerex_staggered_list_view.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/theme/app_theme.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../../exercise/presentation/widgets/exercise_image_widget.dart';
import 'package:gerex/features/exercise/domain/entities/exercise.dart';
import '../providers/challenge_provider.dart';
import '../../domain/entities/challenge.dart';

class SelectChallengeScreen extends StatefulWidget {
  const SelectChallengeScreen({super.key});

  @override
  State<SelectChallengeScreen> createState() => _SelectChallengeScreenState();
}

class _SelectChallengeScreenState extends State<SelectChallengeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fetch exercise data & challenges data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().fetchExercises();
      context.read<ChallengeProvider>().fetchChallenges();
    });

    _searchController.addListener(() {
      // Update exercise search query in provider
      context.read<ExerciseProvider>().updateSearchQuery(
        _searchController.text,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter by Target Muscle Group',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkHeading,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _muscleGroups.map((group) {
                  return Consumer<ExerciseProvider>(
                    builder: (context, provider, _) {
                      final isSelected = provider.selectedMuscleGroup == group;
                      return ChoiceChip(
                        label: Text(
                          group,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDarkBody,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accentEmeraldDeep,
                        onSelected: (selected) {
                          if (selected) {
                            provider.updateMuscleGroup(group);
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSvgOrFaIcon(
    String badgeName, {
    double size = 24.0,
    Color? color,
  }) {
    String svgPath;
    dynamic fallback = FontAwesomeIcons.award;

    switch (badgeName) {
      case 'person-running':
        svgPath = 'assets/svg icons/running-man-and-fitness-16873.svg';
        fallback = FontAwesomeIcons.personRunning;
        break;
      case 'dumbbell':
        svgPath = 'assets/svg icons/weight-lifting-16884.svg';
        fallback = FontAwesomeIcons.dumbbell;
        break;
      case 'shield-halved':
        svgPath = 'assets/svg icons/blue-yoga-or-pilates-mat-16851.svg';
        fallback = FontAwesomeIcons.shieldHalved;
        break;
      default:
        svgPath = 'assets/svg icons/workout finish.svg';
        fallback = FontAwesomeIcons.award;
    }

    return SvgPicture.asset(
      svgPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      placeholderBuilder: (context) =>
          FaIcon(fallback as FaIconData?, size: size * 0.8, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final exerciseProvider = Provider.of<ExerciseProvider>(context);
    final challengeProvider = Provider.of<ChallengeProvider>(context);

    // Filters exercises for My Workouts (exercises with user_id)
    final myExercises = exerciseProvider.exercises
        .where((e) => e.userId != null)
        .toList();

    // All exercises
    final allExercises = exerciseProvider.exercises;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore & Challenges'),
        centerTitle: true,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Search field & filter button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      borderRadius: 16,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search exercises...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showFilterBottomSheet(context),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 16,
                      child: Icon(
                        Icons.tune_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Tab navigation Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(4),
                borderRadius: 20,
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: GerexGradients.primaryCTA,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.white60
                      : Colors.black54,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'My Workouts'),
                    Tab(text: 'All Workouts'),
                    Tab(text: 'Challenges'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tabs Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: My Workouts
                  _buildExerciseList(
                    context,
                    myExercises,
                    'No custom workouts created yet.',
                  ),
                  // Tab 2: All Workouts
                  _buildExerciseList(
                    context,
                    allExercises,
                    'No exercises found.',
                  ),
                  // Tab 3: Challenges
                  _buildChallengesList(context, challengeProvider),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildExerciseList(
    BuildContext context,
    List<Exercise> list,
    String emptyMessage,
  ) {
    final theme = Theme.of(context);
    final provider = Provider.of<ExerciseProvider>(context);

    if (provider.isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emptyMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GerexStaggeredListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      estimatedItemHeight: 96.0,
      children: list.map((exercise) {
        return GerexAnimatedListTile(
          title: exercise.name,
          subtitle: '${exercise.muscleGroup} • ${exercise.equipment}',
          leadingIcon: _getExerciseIcon(exercise),
          progress: _getExerciseProgress(exercise),
          leadingWidget: ExerciseImageWidget(
            imagePath: exercise.imageUrl,
            size: 44.0,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.chipTealBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.level.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accentEmeraldLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (exercise.instructions.isEmpty)
                const Text(
                  'No instructions registered for this exercise.',
                  style: TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                )
              else
                ...exercise.instructions.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}. ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentEmeraldLight,
                            fontSize: 11,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 11,
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
              extra: {'exercise': exercise, 'isPicker': false},
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildChallengesList(
    BuildContext context,
    ChallengeProvider provider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (provider.isLoading && provider.challenges.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (provider.challenges.isNotEmpty) ...[
          Text(
            'Active Challenges',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...provider.challenges.map((challenge) {
            final isJoined = provider.isJoined(challenge.id);
            final difficultyColor = challenge.getDifficultyColor(context);

            return GestureDetector(
              onTap: () {
                context.push('/challenge-detail', extra: challenge);
              },
              child: GlassContainer(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Circular badge icon container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: _buildSvgOrFaIcon(
                          challenge.badgeIcon,
                          size: 24.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Challenge core details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Difficulty tag badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: difficultyColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: difficultyColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  challenge.difficultyLabel,
                                  style: TextStyle(
                                    color: difficultyColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Daily challenge tag
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.orangeAccent,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    challenge.type,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challenge.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Trailing state indicator
                    Column(
                      children: [
                        if (isJoined)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.done,
                              color: Colors.white,
                              size: 14,
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ] else ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Text('No active challenges found.'),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Badges trophy case header
        Text(
          'Fitness Badges Trophy Case',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Unlock these badges by completing training, hydration, consistency, and active rest cycles.',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 18),

        // Badges grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: _trophyBadges.length,
          itemBuilder: (context, idx) {
            final badge = _trophyBadges[idx];
            return GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    badge.path,
                    width: 34,
                    height: 34,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                    placeholderBuilder: (context) => FaIcon(
                      badge.fallback as FaIconData?,
                      size: 26,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class TrophyBadge {
  final String path;
  final String title;
  final dynamic fallback;

  TrophyBadge({
    required this.path,
    required this.title,
    required this.fallback,
  });
}

final List<TrophyBadge> _trophyBadges = [
  TrophyBadge(
    path: 'assets/svg icons/Ab-Workout 1.svg',
    title: 'Core Shredder',
    fallback: FontAwesomeIcons.dumbbell,
  ),
  TrophyBadge(
    path: 'assets/svg icons/barbel.svg',
    title: 'Iron Master',
    fallback: FontAwesomeIcons.dumbbell,
  ),
  TrophyBadge(
    path: 'assets/svg icons/blue-water-bottle-for-gym-21783.svg',
    title: 'Aqua Fuel',
    fallback: FontAwesomeIcons.glassWater,
  ),
  TrophyBadge(
    path: 'assets/svg icons/blue-yoga-or-pilates-mat-16851.svg',
    title: 'Zen Recovery',
    fallback: FontAwesomeIcons.heart,
  ),
  TrophyBadge(
    path: 'assets/svg icons/boxing-gloves-and-woman-16890.svg',
    title: 'Gloves On',
    fallback: FontAwesomeIcons.handFist,
  ),
  TrophyBadge(
    path: 'assets/svg icons/Card-Goals-2.svg',
    title: 'Target Clear',
    fallback: FontAwesomeIcons.bullseye,
  ),
  TrophyBadge(
    path: 'assets/svg icons/google icon.svg',
    title: 'G-Athlete',
    fallback: FontAwesomeIcons.google,
  ),
  TrophyBadge(
    path: 'assets/svg icons/Icon-Alaarm.svg',
    title: 'Early Riser',
    fallback: FontAwesomeIcons.bell,
  ),
  TrophyBadge(
    path: 'assets/svg icons/Icon-Bed.svg',
    title: 'Rest Protocol',
    fallback: FontAwesomeIcons.bed,
  ),
  TrophyBadge(
    path: 'assets/svg icons/Layer 5.svg',
    title: 'Peak Strength',
    fallback: FontAwesomeIcons.arrowUpRightDots,
  ),
  TrophyBadge(
    path: 'assets/svg icons/lowbody workout.svg',
    title: 'Leg Day Hero',
    fallback: FontAwesomeIcons.personWalking,
  ),
  TrophyBadge(
    path: 'assets/svg icons/man-and-gymnastic-rings-16878.svg',
    title: 'Rings Master',
    fallback: FontAwesomeIcons.circle,
  ),
  TrophyBadge(
    path: 'assets/svg icons/man-back-muscles-16865.svg',
    title: 'Back Builder',
    fallback: FontAwesomeIcons.person,
  ),
  TrophyBadge(
    path: 'assets/svg icons/measuring-tape-fitness-16895.svg',
    title: 'Tape Tracker',
    fallback: FontAwesomeIcons.rulerHorizontal,
  ),
  TrophyBadge(
    path: 'assets/svg icons/onboarding.svg',
    title: 'Rookie Rise',
    fallback: FontAwesomeIcons.graduationCap,
  ),
  TrophyBadge(
    path: 'assets/svg icons/onboarding2.svg',
    title: 'Steady Steps',
    fallback: FontAwesomeIcons.road,
  ),
  TrophyBadge(
    path: 'assets/svg icons/onboarding3.svg',
    title: 'Apex Fit',
    fallback: FontAwesomeIcons.crown,
  ),
  TrophyBadge(
    path: 'assets/svg icons/red-punching-bag-16886.svg',
    title: 'Bag Hitter',
    fallback: FontAwesomeIcons.handFist,
  ),
  TrophyBadge(
    path: 'assets/svg icons/reminder icon.svg',
    title: 'Consistent',
    fallback: FontAwesomeIcons.calendarCheck,
  ),
  TrophyBadge(
    path: 'assets/svg icons/running-man-and-fitness-16873.svg',
    title: 'Cardio King',
    fallback: FontAwesomeIcons.personRunning,
  ),
  TrophyBadge(
    path: 'assets/svg icons/skipping-rope.svg',
    title: 'Jump Rope',
    fallback: FontAwesomeIcons.personRunning,
  ),
  TrophyBadge(
    path: 'assets/svg icons/skipping.svg',
    title: 'Rope Skipper',
    fallback: FontAwesomeIcons.personRunning,
  ),
  TrophyBadge(
    path: 'assets/svg icons/Sleep-Graph.svg',
    title: 'Deep Rest',
    fallback: FontAwesomeIcons.chartSimple,
  ),
  TrophyBadge(
    path: 'assets/svg icons/sleep icon.svg',
    title: 'Quiet Night',
    fallback: FontAwesomeIcons.moon,
  ),
  TrophyBadge(
    path: 'assets/svg icons/stationary-bike-16887.svg',
    title: 'Spin Rider',
    fallback: FontAwesomeIcons.bicycle,
  ),
  TrophyBadge(
    path: 'assets/svg icons/workout finish.svg',
    title: 'Finisher',
    fallback: FontAwesomeIcons.flagCheckered,
  ),
  TrophyBadge(
    path: 'assets/svg icons/weight-lifting-16884.svg',
    title: 'Power Lifter',
    fallback: FontAwesomeIcons.dumbbell,
  ),
  TrophyBadge(
    path: 'assets/svg icons/water-bottle.svg',
    title: 'Hydrated',
    fallback: FontAwesomeIcons.bottleWater,
  ),
  TrophyBadge(
    path: 'assets/svg icons/track progress icon.svg',
    title: 'Tracker',
    fallback: FontAwesomeIcons.chartLine,
  ),
  TrophyBadge(
    path: 'assets/svg icons/stopwatch-chronometer-16882.svg',
    title: 'Speed Star',
    fallback: FontAwesomeIcons.stopwatch,
  ),
];
