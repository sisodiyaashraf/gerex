import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/workout_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import '../../../metrics/presentation/providers/metrics_provider.dart';
import '../../../metrics/presentation/providers/heart_rate_provider.dart';
import 'package:gerex/core/providers/activity_provider.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/presentation/widgets/hero_mint_card.dart';
import 'package:gerex/core/presentation/widgets/big_stat_number.dart';
import 'package:gerex/core/presentation/widgets/gerex_avatar.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';
import 'package:gerex/core/theme/app_theme.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wp = context.read<WorkoutProvider>();
      final mp = context.read<MetricsProvider>();
      await wp.fetchWorkouts();
      await wp.fetchSessions();
      await mp.fetchWeightLogs();
      if (mounted) {
        final ai = context.read<AIProvider>();
        ai.loadDailyInsight(wp.sessions);
        ai.loadWeeklyTrainingStory(wp.sessions);
      }
    });
  }

  double _calculateBmi(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  String _getBmiStatus(double bmi) {
    if (bmi <= 0) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal Weight';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double bmi, ThemeData theme) {
    if (bmi < 18.5) return AppColors.accentEmeraldLight;
    if (bmi < 25.0) return AppColors.accentEmeraldLight;
    if (bmi < 30.0) return const Color(0xFFF59E0B);
    return AppColors.destructiveRed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final metricsProvider = Provider.of<MetricsProvider>(context);
    final activity = Provider.of<ActivityProvider>(context);
    final notifications = Provider.of<NotificationProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final hrProvider = Provider.of<HeartRateProvider>(context);

    final displayName = auth.user?.userMetadata?['full_name'] ??
        auth.user?.userMetadata?['name'] ??
        auth.user?.email?.split('@').first ??
        'Aesthetic Athlete';

    final photoUrl = auth.user?.userMetadata?['avatar_url'] ??
        auth.user?.userMetadata?['picture'];

    final double latestWeight = metricsProvider.weightLogs.isNotEmpty
        ? metricsProvider.weightLogs.last.value
        : 72.0;
    final double userHeight = activity.userHeight;
    final double bmiValue = _calculateBmi(latestWeight, userHeight);
    final String bmiStatus = _getBmiStatus(bmiValue);
    final Color bmiColor = _getBmiColor(bmiValue, theme);

    final now = DateTime.now();
    final bool completedToday = workoutProvider.sessions.any((s) {
      final compDate = s.completedAt ?? s.startedAt;
      return compDate.year == now.year &&
          compDate.month == now.month &&
          compDate.day == now.day;
    });

    String formatDuration(int totalSeconds) {
      final mins = totalSeconds ~/ 60;
      return '$mins min';
    }

    return GerexScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final ai = context.read<AIProvider>();
          await workoutProvider.fetchWorkouts();
          await workoutProvider.fetchSessions();
          await metricsProvider.fetchWeightLogs();
          await ai.loadDailyInsight(workoutProvider.sessions, forceRefresh: true);
          await ai.loadWeeklyTrainingStory(workoutProvider.sessions, forceRefresh: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(
                'Gerex Dashboard',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkHeading,
                ),
              ),
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Center(
                  child: GerexAvatar(
                    imageUrl: photoUrl,
                    initials: displayName.isNotEmpty ? displayName[0] : 'G',
                    size: 36,
                    hasNotification: notifications.unreadCount > 0,
                    onTap: () => context.push('/profile'),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.solidBell, size: 18, color: AppColors.textDarkHeading),
                  onPressed: () => context.push('/notifications'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (workoutProvider.isSessionActive) ...[
                    PastelGradientCard(
                      type: PastelCardType.rose,
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const FaIcon(
                          FontAwesomeIcons.dumbbell,
                          color: Color(0xFF14181F),
                        ),
                        title: const Text(
                          'Workout in Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14181F),
                          ),
                        ),
                        subtitle: Text(
                          'Active Session: ${workoutProvider.activeSessionName}',
                          style: const TextStyle(
                            color: Color(0xFF14181F),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF14181F),
                          size: 16,
                        ),
                        onTap: () {
                          context.push('/session');
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Signature Hero Mint Card Overview
                  HeroMintCard(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Welcome back, $displayName',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLightBody.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.badgeDarkNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                completedToday ? 'Target Done' : 'Daily Goal',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentEmeraldLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BigStatNumber(
                          number: '${workoutProvider.sessions.length}',
                          label: 'Total Completed Workouts',
                          unit: 'SESSIONS',
                          isDarkCard: false,
                        ),
                      ],
                    ),
                  ),

                    // 2. BMI Summary Glass Card
                    PastelGradientCard(
                      type: PastelCardType.mint,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Left: Dial Progress Ring
                          SizedBox(
                            height: 64,
                            width: 64,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: (bmiValue / 40.0).clamp(0.0, 1.0),
                                  strokeWidth: 6,
                                  color: bmiColor,
                                  backgroundColor: Colors.black.withValues(alpha: 0.05),
                                ),
                                 Text(
                                  bmiValue.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Body Mass Index (BMI)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Status: $bmiStatus',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: bmiColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => context.push('/activity-tracker'),
                                  child: const Row(
                                    children: [
                                      Text(
                                        'View more metrics',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF047857),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: Color(0xFF047857),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Today's Target glass row
                    PastelGradientCard(
                      type: PastelCardType.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            completedToday ? Icons.check_circle : Icons.circle_outlined,
                            color: completedToday ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\'s Routine Target',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  completedToday 
                                      ? 'Daily Target achieved!' 
                                      : 'Complete at least 1 workout session today.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Three Compact Glass Stat Cards (Water, Sleep, Calories)
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          theme,
                          title: 'Water Intake',
                          value: '${activity.waterIntake} ml',
                          iconPath: 'assets/svg icons/water-bottle.svg',
                          fallbackIcon: FontAwesomeIcons.glassWater,
                          type: PastelCardType.sky,
                          iconColor: const Color(0xFF0284C7),
                          textColor: AppColors.textLightBody,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          context,
                          theme,
                          title: 'Sleep Tracker',
                          value: '${activity.sleepHours} hrs',
                          iconPath: 'assets/svg icons/sleep icon.svg',
                          fallbackIcon: FontAwesomeIcons.bed,
                          type: PastelCardType.violet,
                          iconColor: const Color(0xFF6D28D9),
                          textColor: AppColors.textLightBody,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          context,
                          theme,
                          title: 'Burned',
                          value: '${activity.calories} kcal',
                          iconPath: '',
                          fallbackIcon: FontAwesomeIcons.fire,
                          type: PastelCardType.sunset,
                          iconColor: const Color(0xFFD97706),
                          textColor: AppColors.textLightBody,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 5. Activity Status (heart-rate sparkline placeholder)
                    AnimatedTappable(
                      onTap: () => context.push('/heart-rate-connect'),
                      child: PastelGradientCard(
                        type: PastelCardType.rose,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Details: Status, BPM, Badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Heart Rate Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        hrProvider.connectionState == HeartRateConnectionState.live && hrProvider.currentBpm != null
                                            ? '${hrProvider.currentBpm}'
                                            : '--',
                                        style: theme.textTheme.displaySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'BPM',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4B5563),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Connection Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hrProvider.connectionState == HeartRateConnectionState.live
                                          ? (hrProvider.activeSource == HeartRateSource.manual
                                              ? Colors.purple.shade100
                                              : const Color(0xFFA7F3D0))
                                          : (hrProvider.connectionState == HeartRateConnectionState.disconnected
                                              ? const Color(0xFFFCA5A5)
                                              : const Color(0xFFFDA4AF)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hrProvider.connectionState == HeartRateConnectionState.live
                                          ? (hrProvider.activeSource == HeartRateSource.manual ? 'Manual Log' : 'Live')
                                          : (hrProvider.connectionState == HeartRateConnectionState.disconnected
                                              ? 'Disconnected'
                                              : 'Connect Device'),
                                      style: TextStyle(
                                        color: hrProvider.connectionState == HeartRateConnectionState.live
                                            ? (hrProvider.activeSource == HeartRateSource.manual
                                                ? Colors.purple.shade900
                                                : const Color(0xFF065F46))
                                            : (hrProvider.connectionState == HeartRateConnectionState.disconnected
                                                ? const Color(0xFF991B1B)
                                                : const Color(0xFF9F1239)),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right Details: Sparkline + Smartwatch Image
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Smartwatch Image
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/gerex smartwatch.png',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Custom sparkline layout
                                SizedBox(
                                  width: 90,
                                  height: 24,
                                  child: CustomPaint(
                                    painter: _HeartSparklinePainter(
                                      theme: theme,
                                      color: const Color(0xFFE11D48),
                                      history: hrProvider.recentHistory,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 6. Workout Progress Weekly completion summary
                    PastelGradientCard(
                      type: PastelCardType.slate,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                             'Workout Consistency Progress',
                             style: TextStyle(
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                             ),
                           ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (index) {
                              final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              // Find if completed workout on this day
                              final dayOffset = 6 - index;
                              final checkDate = now.subtract(Duration(days: dayOffset));
                              final isCompleted = workoutProvider.sessions.any((s) {
                                final compDate = s.completedAt ?? s.startedAt;
                                return compDate.year == checkDate.year &&
                                    compDate.month == checkDate.month &&
                                    compDate.day == checkDate.day;
                              });

                              return Column(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isCompleted
                                        ? const Color(0xFF0D807B)
                                        : Colors.black.withValues(alpha: 0.05),
                                    child: isCompleted
                                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    weekdays[index],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 7. Latest Workouts
                    if (workoutProvider.sessions.isNotEmpty) ...[
                      Text(
                        'Latest Completed Workouts',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...workoutProvider.sessions.take(2).map((session) {
                        final compDate = session.completedAt ?? session.startedAt;
                        return PastelGradientCard(
                          type: PastelCardType.indigo,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  color: theme.colorScheme.primary,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'Completed on ${compDate.day}/${compDate.month} at ${compDate.hour}:${compDate.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // AI Daily Insight & Weekly Story Card
                    Consumer<AIProvider>(
                      builder: (context, ai, _) {
                        final List<Widget> cards = [];

                        if (ai.isInsightLoading) {
                          cards.add(
                            PastelGradientCard(
                              type: PastelCardType.mint,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Generating coach insight...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (ai.dailyInsight != null) {
                          cards.add(
                            PastelGradientCard(
                              type: PastelCardType.mint,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.wandMagicSparkles,
                                        color: Color(0xFF0D807B),
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Daily Coach Insight',
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
                                    ai.dailyInsight!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(0xFF14181F).withValues(alpha: 0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (ai.isStoryLoading) {
                          cards.add(
                            PastelGradientCard(
                              type: PastelCardType.sunset,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Generating weekly training story...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (ai.weeklyTrainingStory != null) {
                          cards.add(
                            PastelGradientCard(
                              type: PastelCardType.sunset,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.bookOpen,
                                        color: Color(0xFFC2410C),
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Weekly Training Story',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC2410C),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TypewriterText(
                                    text: ai.weeklyTrainingStory!,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (cards.isEmpty) return const SizedBox.shrink();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: cards,
                        );
                      },
                    ),

                    // Quick Actions Rows
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () {
                              context.push('/quick-workout');
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: GerexGradients.primaryCTA,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(FontAwesomeIcons.bolt, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Quick Start',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: FaIcon(FontAwesomeIcons.circlePlus, color: theme.colorScheme.primary, size: 14),
                            label: const Text('New'),
                            onPressed: () {
                              context.push('/builder');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              foregroundColor: theme.colorScheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const FaIcon(FontAwesomeIcons.chartLine, size: 14),
                            label: const Text('Workout Tracker'),
                            onPressed: () {
                              context.push('/workout-tracker');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                              foregroundColor: theme.colorScheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const FaIcon(FontAwesomeIcons.bookOpen, size: 14),
                            label: const Text('Exercise DB'),
                            onPressed: () {
                              context.push('/exercise-library');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'AI Training Assistant',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedTappable(
                            onTap: () => context.push('/coach'),
                            child: const PastelGradientCard(
                              type: PastelCardType.violet,
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.solidCommentDots,
                                    size: 20,
                                    color: Color(0xFF14181F),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'AI Coach',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF14181F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedTappable(
                            onTap: () => context.push('/ai-plan'),
                            child: const PastelGradientCard(
                              type: PastelCardType.mint,
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.wandMagicSparkles,
                                    size: 20,
                                    color: Color(0xFF14181F),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Plan Gen',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF14181F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedTappable(
                            onTap: () => context.push('/pose-feedback'),
                            child: const PastelGradientCard(
                              type: PastelCardType.sky,
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.video,
                                    size: 20,
                                    color: Color(0xFF14181F),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Form Check',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF14181F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Templates Section
                    Text(
                      'My Templates',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (workoutProvider.isLoading && workoutProvider.workouts.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (workoutProvider.workouts.isEmpty)
                      PastelGradientCard(
                        type: PastelCardType.slate,
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No templates saved. Create one to standardise your routines!',
                          style: TextStyle(
                            color: const Color(0xFF14181F).withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: workoutProvider.workouts.length,
                        itemBuilder: (context, index) {
                          final workout = workoutProvider.workouts[index];
                          return AnimatedTappable(
                            onTap: () {
                              context.push('/workout-details', extra: workout);
                            },
                            child: PastelGradientCard(
                              type: PastelCardType.sky,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workout.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF14181F),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${workout.exercises.length} exercises',
                                          style: TextStyle(
                                            color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF0D807B),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // Sessions History Log Section
                    Text(
                      'Workout History Log',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (workoutProvider.isLoading && workoutProvider.sessions.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (workoutProvider.sessions.isEmpty)
                      PastelGradientCard(
                        type: PastelCardType.slate,
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No completed workouts in history yet.',
                          style: TextStyle(
                            color: const Color(0xFF14181F).withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: workoutProvider.sessions.length,
                        itemBuilder: (context, index) {
                          final session = workoutProvider.sessions[index];
                          final date = session.completedAt ?? session.startedAt;
                          return PastelGradientCard(
                            type: PastelCardType.violet,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.zero,
                            child: Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                iconColor: const Color(0xFF14181F),
                                collapsedIconColor: const Color(0xFF14181F).withValues(alpha: 0.6),
                                title: Text(
                                  session.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF14181F),
                                  ),
                                ),
                                subtitle: Text(
                                  '${date.day}/${date.month}/${date.year} • ${formatDuration(session.durationSeconds)}',
                                  style: TextStyle(
                                    color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (session.loggedSets.isEmpty)
                                          const Text(
                                            'No logged sets.',
                                            style: TextStyle(color: Color(0xFF14181F)),
                                          )
                                        else
                                          ...session.loggedSets.map((setLog) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      setLog.exercise?.name ?? 'Exercise',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: Color(0xFF14181F),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Set ${setLog.setNumber}: ${setLog.weight} kg x ${setLog.reps}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF14181F),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String value,
    required String iconPath,
    required dynamic fallbackIcon,
    required PastelCardType type,
    required Color iconColor,
    required Color textColor,
  }) {
    return Expanded(
      child: AnimatedTappable(
        onTap: () => context.push('/activity-tracker'),
        child: PastelGradientCard(
          type: type,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconPath.isNotEmpty
                  ? SvgPicture.asset(
                      iconPath,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        iconColor,
                        BlendMode.srcIn,
                      ),
                      errorBuilder: (c, e, s) => FaIcon(
                        fallbackIcon as FaIconData,
                        color: iconColor,
                        size: 14,
                      ),
                    )
                  : FaIcon(
                      fallbackIcon as FaIconData,
                      color: iconColor,
                      size: 16,
                    ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF14181F).withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartSparklinePainter extends CustomPainter {
  final ThemeData theme;
  final Color color;
  final List<int> history;

  _HeartSparklinePainter({
    required this.theme,
    required this.color,
    required this.history,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (history.isEmpty || history.length < 2) {
      path.moveTo(0, size.height * 0.5);
      path.lineTo(size.width * 0.25, size.height * 0.5);
      path.lineTo(size.width * 0.35, size.height * 0.2);
      path.lineTo(size.width * 0.45, size.height * 0.8);
      path.lineTo(size.width * 0.55, size.height * 0.1);
      path.lineTo(size.width * 0.65, size.height * 0.6);
      path.lineTo(size.width * 0.75, size.height * 0.5);
      path.lineTo(size.width, size.height * 0.5);
    } else {
      final double dx = size.width / (history.length - 1);
      int minVal = 200;
      int maxVal = 40;
      for (var val in history) {
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }
      final double range = (maxVal - minVal).toDouble();
      final double heightRange = size.height * 0.6;

      for (int i = 0; i < history.length; i++) {
        final double x = i * dx;
        final double normalized = range > 0 ? (history[i] - minVal) / range : 0.5;
        final double y = size.height * 0.8 - (normalized * heightRange);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartSparklinePainter oldDelegate) {
    return oldDelegate.history != history;
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration duration;

  const TypewriterText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 35),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayedText = '';
      _currentIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            _displayedText += widget.text[_currentIndex];
            _currentIndex++;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: TextStyle(
        fontSize: 13,
        color: const Color(0xFF14181F).withValues(alpha: 0.85),
        height: 1.4,
      ),
    );
  }
}