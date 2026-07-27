import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/workout_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import '../../../metrics/presentation/providers/metrics_provider.dart';
import 'package:gerex/core/providers/activity_provider.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
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
        context.read<AIProvider>().loadDailyInsight(wp.sessions);
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
    if (bmi < 18.5) return Colors.blueAccent;
    if (bmi < 25.0) return theme.colorScheme.primary;
    if (bmi < 30.0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final metricsProvider = Provider.of<MetricsProvider>(context);
    final activity = Provider.of<ActivityProvider>(context);
    final notifications = Provider.of<NotificationProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    // Personalized greeting names
    final displayName = auth.user?.userMetadata?['full_name'] ??
        auth.user?.userMetadata?['name'] ??
        auth.user?.email?.split('@').first ??
        'Aesthetic Athlete';

    // BMI computation
    final double latestWeight = metricsProvider.weightLogs.isNotEmpty
        ? metricsProvider.weightLogs.last.value
        : 72.0; // Default fallback
    final double userHeight = activity.userHeight;
    final double bmiValue = _calculateBmi(latestWeight, userHeight);
    final String bmiStatus = _getBmiStatus(bmiValue);
    final Color bmiColor = _getBmiColor(bmiValue, theme);

    // Check if user completed workout today
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

    return Scaffold(
      body: LiquidBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final ai = context.read<AIProvider>();
            await workoutProvider.fetchWorkouts();
            await workoutProvider.fetchSessions();
            await metricsProvider.fetchWeightLogs();
            await ai.loadDailyInsight(workoutProvider.sessions, forceRefresh: true);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom AppBar with avatar and notification bell
              SliverAppBar(
                floating: true,
                title: const Text(
                  'Gerex Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Center(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final photoUrl = auth.user?.userMetadata?['avatar_url'] ??
                            auth.user?.userMetadata?['picture'];
                        final initials = displayName.isNotEmpty
                            ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : 'G';

                        return GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                            child: photoUrl == null
                                ? Text(
                                    initials,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.solidBell, size: 18),
                        onPressed: () => context.push('/notifications'),
                      ),
                      if (notifications.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${notifications.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Live Session Alert Banner if active
                    if (workoutProvider.isSessionActive) ...[
                      GlassContainer(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                        child: ListTile(
                          leading: FaIcon(
                            FontAwesomeIcons.dumbbell,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            'Workout in Progress',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          subtitle: Text(
                            'Active Session: ${workoutProvider.activeSessionName}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          onTap: () {
                            context.push('/session');
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 1. Personalized Greeting
                    Text(
                      'Welcome back,',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. BMI Summary Glass Card
                    GlassContainer(
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
                                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.1),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                  child: Row(
                                    children: [
                                      Text(
                                        'View more metrics',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: theme.colorScheme.primary,
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
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            completedToday ? Icons.check_circle : Icons.circle_outlined,
                            color: completedToday ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\'s Routine Target',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  completedToday 
                                      ? 'Daily Target achieved!' 
                                      : 'Complete at least 1 workout session today.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          context,
                          theme,
                          title: 'Sleep Tracker',
                          value: '${activity.sleepHours} hrs',
                          iconPath: 'assets/svg icons/sleep icon.svg',
                          fallbackIcon: FontAwesomeIcons.bed,
                        ),
                        const SizedBox(width: 8),
                        _buildStatCard(
                          context,
                          theme,
                          title: 'Burned',
                          value: '${activity.calories} kcal',
                          iconPath: '',
                          fallbackIcon: FontAwesomeIcons.fire,
                          iconColor: Colors.orangeAccent,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 5. Activity Status (heart-rate sparkline placeholder)
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Heart Rate Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'UI-Only / Sensor Needed',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '72',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'BPM',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const Spacer(),
                              // Custom sparkline layout
                              SizedBox(
                                width: 120,
                                height: 32,
                                child: CustomPaint(
                                  painter: _HeartSparklinePainter(theme: theme),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 6. Workout Progress Weekly completion summary
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workout Consistency Progress',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.surface.withValues(alpha: 0.1),
                                    child: isCompleted
                                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    weekdays[index],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                        return GlassContainer(
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

                    // AI Daily Insight Card
                    Consumer<AIProvider>(
                      builder: (context, ai, _) {
                        if (ai.isInsightLoading) {
                          return GlassContainer(
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
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (ai.dailyInsight != null) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.wandMagicSparkles,
                                      color: theme.colorScheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Daily Coach Insight',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
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
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
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

                    // Quick Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              workoutProvider.startEmptyWorkoutSession();
                              context.push('/session');
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
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: FaIcon(FontAwesomeIcons.circlePlus, color: theme.colorScheme.primary, size: 14),
                            label: const Text('New Template'),
                            onPressed: () {
                              context.push('/builder');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Workout Tracker navigation button
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
                            label: const Text('Tracker'),
                            onPressed: () {
                              context.push('/workout-tracker');
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
                            child: const GlassContainer(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(FontAwesomeIcons.solidCommentDots, size: 20),
                                  SizedBox(height: 8),
                                  Text(
                                    'AI Coach',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                            child: const GlassContainer(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 20),
                                  SizedBox(height: 8),
                                  Text(
                                    'Plan Gen',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                            child: const GlassContainer(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Column(
                                children: [
                                  FaIcon(FontAwesomeIcons.video, size: 20),
                                  SizedBox(height: 8),
                                  Text(
                                    'Form Check',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
                      GlassContainer(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No templates saved. Create one to standardise your routines!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
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
                            child: GlassContainer(
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
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${workout.exercises.length} exercises',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: theme.colorScheme.primary,
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
                      GlassContainer(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No completed workouts in history yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
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
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                iconColor: theme.colorScheme.primary,
                                collapsedIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                title: Text(
                                  session.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${date.day}/${date.month}/${date.year} • ${formatDuration(session.durationSeconds)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (session.loggedSets.isEmpty)
                                          const Text('No logged sets.')
                                        else
                                          ...session.loggedSets.map((setLog) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    setLog.exercise?.name ?? 'Exercise',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Set ${setLog.setNumber}: ${setLog.weight} kg x ${setLog.reps}',
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
    Color? iconColor,
  }) {
    return Expanded(
      child: AnimatedTappable(
        onTap: () => context.push('/activity-tracker'),
        child: GlassContainer(
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
                        iconColor ?? theme.colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                      errorBuilder: (c, e, s) => FaIcon(
                        fallbackIcon as FaIconData,
                        color: iconColor ?? theme.colorScheme.primary,
                        size: 14,
                      ),
                    )
                  : FaIcon(
                      fallbackIcon as FaIconData,
                      color: iconColor ?? theme.colorScheme.primary,
                      size: 16,
                    ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

  _HeartSparklinePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.25, size.height * 0.5)
      ..lineTo(size.width * 0.35, size.height * 0.2)
      ..lineTo(size.width * 0.45, size.height * 0.8)
      ..lineTo(size.width * 0.55, size.height * 0.1)
      ..lineTo(size.width * 0.65, size.height * 0.6)
      ..lineTo(size.width * 0.75, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
