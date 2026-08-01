import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../workout/presentation/providers/workout_provider.dart';
import '../providers/metrics_provider.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
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
                        return const PastelGradientCard(
                          type: PastelCardType.slate,
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
                                  color: Color(0x9914181F),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (ai.progressSummary != null) {
                        return PastelGradientCard(
                          type: PastelCardType.mint,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.chartSimple,
                                    color: Color(0xFF0D807B),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI Progress Summary',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D807B),
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
                                  color: Color(0xFF14181F),
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

                  // 1. Streaks Dashboard Panel with Flame Medallion
                  PastelGradientCard(
                    type: PastelCardType.indigo,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // Flame Medallion
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFF5722).withValues(alpha: 0.35),
                                    const Color(0xFFFF9800).withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.fire,
                                  color: metricsProvider.workoutDates.contains(
                                    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
                                  ) ? const Color(0xFFFF5722) : const Color(0xFF6B7280),
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(
                                    child: _buildStreakIndicator(
                                      context,
                                      'Current Streak',
                                      '${metricsProvider.currentStreak} Days',
                                      FontAwesomeIcons.fire,
                                      metricsProvider.workoutDates.contains(
                                        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
                                      ) ? const Color(0xFFEA580C) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: const Color(0xFF14181F).withValues(alpha: 0.1),
                                  ),
                                  Expanded(
                                    child: _buildStreakIndicator(
                                      context,
                                      'Longest Streak',
                                      '${metricsProvider.longestStreak} Days',
                                      FontAwesomeIcons.trophy,
                                      const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (metricsProvider.currentStreak > 0 && !metricsProvider.workoutDates.contains(
                          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
                        )) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFD97706), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Streak Paused: Grace Period Active. Complete a workout to resume!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9A3412),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (metricsProvider.workoutDates.contains(
                          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'
                        )) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'You logged a workout today! Active streak is hot!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Consistency Calendar Grid
                  PastelGradientCard(
                    type: PastelCardType.mint,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${_getMonthName(now.month)} ${now.year} - Consistency',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF14181F),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const FaIcon(
                              FontAwesomeIcons.calendarCheck,
                              color: Color(0xFF0D807B),
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
                                    ? const Color(0xFF0D807B).withValues(
                                        alpha: 0.25,
                                      )
                                    : Colors.transparent,
                                border: Border.all(
                                  color: hasWorkout
                                      ? const Color(0xFF0D807B)
                                      : const Color(0xFF14181F).withValues(alpha: 0.1),
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
                                        ? const Color(0xFF0D807B)
                                        : const Color(0xFF14181F),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 4. Sleep Tracker Card
                  PastelGradientCard(
                    type: PastelCardType.violet,
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
                                  color: const Color(0xFF14181F).withValues(
                                    alpha: 0.6,
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
                  PastelGradientCard(
                    type: PastelCardType.sunset,
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
                                  color: const Color(0xFF14181F).withValues(
                                    alpha: 0.6,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, color: color, size: 22.0),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF14181F).withValues(alpha: 0.6),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF14181F),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF14181F),
          ),
        ),
      ),
    );
  }
}