import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../providers/metrics_provider.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/big_stat_number.dart';
import 'package:gerex/core/presentation/widgets/gerex_avatar.dart';
import 'package:gerex/core/theme/app_theme.dart';

class MetricsDashboardScreen extends StatefulWidget {
  const MetricsDashboardScreen({super.key});

  @override
  State<MetricsDashboardScreen> createState() => _MetricsDashboardScreenState();
}

class _MetricsDashboardScreenState extends State<MetricsDashboardScreen> {
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData({bool forceRefresh = false}) {
    context.read<MetricsProvider>().fetchWeightLogs();
    final workouts = context.read<WorkoutProvider>();
    workouts.fetchSessions().then((_) {
      if (mounted) {
        context.read<MetricsProvider>().computeStreaks(workouts.sessions);
        context.read<AIProvider>().loadProgressSummary(
          workouts.sessions,
          forceRefresh: forceRefresh,
        );
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metricsProvider = Provider.of<MetricsProvider>(context);

    // Get current month info
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;

    return GerexScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData(forceRefresh: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Analytics & Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkHeading,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GerexAvatar(
                    size: 38,
                    hasNotification: true,
                    onTap: () => context.push('/notifications'),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Signature Light Hero Mint Header Card
                  HeroMintCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLightBody.withValues(
                                  alpha: 0.7,
                                ),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.badgeDarkNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Pro Athlete',
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
                          number: '234',
                          label: 'Calories Burned Today',
                          unit: 'KCAL',
                          isDarkCard: false,
                        ),
                      ],
                    ),
                  ),

                  // AI Progress Summary Card
                  Consumer<AIProvider>(
                    builder: (context, ai, _) {
                      if (ai.isSummaryLoading) {
                        return const GlassContainer(
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentEmeraldLight,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Analyzing your logs recap...',
                                style: TextStyle(
                                  color: AppColors.textDarkMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (ai.progressSummary != null) {
                        return GlassContainer(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.chartSimple,
                                    color: AppColors.accentEmeraldLight,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI Progress Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentEmeraldLight,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                ai.progressSummary!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDarkBody,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),

                  // 1. Streaks Dashboard Panel
                  GlassContainer(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStreakIndicator(
                          context,
                          'Current Streak',
                          '${metricsProvider.currentStreak} Days',
                          FontAwesomeIcons.fire,
                          AppColors.accentEmeraldLight,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.cardDarkGlassAlt,
                        ),
                        _buildStreakIndicator(
                          context,
                          'Longest Streak',
                          '${metricsProvider.longestStreak} Days',
                          FontAwesomeIcons.trophy,
                          AppColors.badgeGoldAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Consistency Calendar Grid
                  GlassContainer(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_getMonthName(now.month)} ${now.year} - Consistency',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDarkHeading,
                              ),
                            ),
                            const FaIcon(
                              FontAwesomeIcons.calendarCheck,
                              color: AppColors.accentEmeraldLight,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            _CalendarDayHeader(label: 'M'),
                            _CalendarDayHeader(label: 'T'),
                            _CalendarDayHeader(label: 'W'),
                            _CalendarDayHeader(label: 'T'),
                            _CalendarDayHeader(label: 'F'),
                            _CalendarDayHeader(label: 'S'),
                            _CalendarDayHeader(label: 'S'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                              ),
                          itemCount: daysInMonth + startWeekday - 1,
                          itemBuilder: (context, index) {
                            if (index < startWeekday - 1) {
                              return const SizedBox.shrink();
                            }
                            final day = index - startWeekday + 2;
                            final dateStr =
                                '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                            final hasWorkout = metricsProvider.workoutDates
                                .contains(dateStr);

                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasWorkout
                                    ? AppColors.accentEmeraldLight.withValues(
                                        alpha: 0.25,
                                      )
                                    : Colors.transparent,
                                border: Border.all(
                                  color: hasWorkout
                                      ? AppColors.accentEmeraldLight
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontWeight: hasWorkout
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: hasWorkout
                                        ? AppColors.accentEmeraldLight
                                        : AppColors.textDarkHeading,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // 4. Sleep Tracker Card
                  GlassContainer(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.bed,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sleep Tracker',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Monitor sleep schedules & recovery goals',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                          onPressed: () => context.push('/sleep-tracker'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Meal Planner Card
                  GlassContainer(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orangeAccent.withValues(
                            alpha: 0.15,
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.utensils,
                            color: Colors.orangeAccent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Meal Planner',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plan high-protein sports nutrition diets',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                          onPressed: () => context.push('/meal-planner'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIndicator(
    BuildContext context,
    String title,
    String value,
    dynamic icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        FaIcon(icon, color: color, size: 30.0),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _CalendarDayHeader extends StatelessWidget {
  final String label;
  const _CalendarDayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
