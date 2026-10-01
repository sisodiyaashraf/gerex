import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import '../../domain/entities/workout_entities.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/presentation/widgets/gerex_app_bar.dart';

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({super.key});

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0-indexed (Mon-Sun)
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<String> _defaultWorkoutNames = [
    'Upper Body Pull & Arms',
    'Legs & Core Destroyer',
    'Active Rest & Mobility',
    'Push Day Hypertrophy',
    'Rest & Recovery',
    'Ab Shred & HIIT Cardio',
    'Fullbody Power Circuit'
  ];

  List<int> _pendingNotificationIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPendingReminders();
    });
  }

  void _loadPendingReminders() async {
    if (!mounted) return;
    final ids = await context.read<NotificationProvider>().getPendingNotificationIds();
    if (!mounted) return;
    setState(() {
      _pendingNotificationIds = ids;
    });
  }

  int _notificationId(String workoutId) {
    return 'workout-$workoutId'.hashCode & 0x7fffffff;
  }

  void _toggleWorkoutReminder(Workout workout, bool value) async {
    final provider = context.read<NotificationProvider>();
    final workoutId = workout.id;
    if (value) {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (date != null && mounted) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null && mounted) {
          final startsAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          final firstExercise = workout.exercises.isNotEmpty
              ? workout.exercises.first.exercise
              : null;
          await provider.scheduleWorkoutReminder(
            workoutId: workoutId,
            workoutName: workout.name,
            startsAt: startsAt,
            exercisesCount: workout.exercises.length,
            imageUrl: firstExercise?.imageUrl,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Scheduled ${workout.name} successfully!'),
                backgroundColor: AppColors.accentEmeraldDeep,
              ),
            );
          }
          _loadPendingReminders();
        }
      }
    } else {
      await provider.cancelNotification('workout-$workoutId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancelled reminder for ${workout.name}')),
        );
      }
      _loadPendingReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    // Calculate dynamic weekly completions and statistics
    final now = DateTime.now();
    final mondayOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final weeklyCompletions = List.generate(7, (index) {
      final dayDate = DateTime(
        mondayOfThisWeek.year,
        mondayOfThisWeek.month,
        mondayOfThisWeek.day,
      ).add(Duration(days: index));

      return workoutProvider.sessions.any((s) {
        final compDate = s.completedAt ?? s.startedAt;
        return compDate.year == dayDate.year &&
            compDate.month == dayDate.month &&
            compDate.day == dayDate.day;
      });
    });

    final weeklyCompletedCount = weeklyCompletions.where((c) => c).length;
    final totalWorkoutSeconds = workoutProvider.sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final totalWorkoutMins = (totalWorkoutSeconds / 60).round();
    final estimatedCalories = (totalWorkoutMins * 7.5).round();

    final headingColor = isDark ? AppColors.textDarkHeading : theme.colorScheme.onSurface;
    final mutedColor = isDark ? AppColors.textDarkMuted : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GerexAppBar.standard(
        title: 'Workout Tracker',
        subtitle: 'Weekly Schedule & Completion',
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, size: 18, color: headingColor),
            ),
            tooltip: 'Create Workout',
            onPressed: () => context.push('/workout-builder'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Quick Stats Header Overview
              _buildQuickStatsOverview(
                context: context,
                isDark: isDark,
                theme: theme,
                completedWorkouts: weeklyCompletedCount,
                totalMinutes: totalWorkoutMins,
                calories: estimatedCalories,
              ),

              const SizedBox(height: 24),

              // 2. Weekly Intensity & Activity Progress Chart
              _buildSectionHeader(
                title: 'Weekly Activity & Intensity',
                subtitle: 'Track your routine consistency',
                headingColor: headingColor,
                mutedColor: mutedColor,
                actionText: 'View Log',
                onActionTap: () => context.push('/workouts'),
              ),
              const SizedBox(height: 12),
              _buildWeeklyIntensityChart(
                context: context,
                isDark: isDark,
                theme: theme,
                weeklyCompletions: weeklyCompletions,
                headingColor: headingColor,
                mutedColor: mutedColor,
              ),

              const SizedBox(height: 24),

              // 3. Today's Active Routine Hero Banner
              _buildSectionHeader(
                title: 'Today\'s Scheduled Routine',
                subtitle: _weekdays[_selectedDayIndex],
                headingColor: headingColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 12),
              _buildTodaysRoutineCard(
                context: context,
                isDark: isDark,
                theme: theme,
                workoutProvider: workoutProvider,
                isTodayCompleted: weeklyCompletions[_selectedDayIndex],
              ),

              const SizedBox(height: 24),

              // 4. Upcoming Workouts & Reminder Alerts
              _buildSectionHeader(
                title: 'Scheduled Reminders',
                subtitle: '${workoutProvider.workouts.length} routines saved',
                headingColor: headingColor,
                mutedColor: mutedColor,
                actionText: 'Manage',
                onActionTap: () => context.push('/workouts'),
              ),
              const SizedBox(height: 12),
              _buildUpcomingRemindersSection(
                context: context,
                isDark: isDark,
                theme: theme,
                workoutProvider: workoutProvider,
                headingColor: headingColor,
                mutedColor: mutedColor,
              ),

              const SizedBox(height: 24),

              // 5. Training Categories Explorer ("What Do You Want to Train?")
              _buildSectionHeader(
                title: 'What Do You Want to Train?',
                subtitle: 'Choose a program to kickstart',
                headingColor: headingColor,
                mutedColor: mutedColor,
              ),
              const SizedBox(height: 12),
              _buildTrainingCategoryExplorer(
                context: context,
                isDark: isDark,
                theme: theme,
                workoutProvider: workoutProvider,
                headingColor: headingColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Section Header Helper ---
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required Color headingColor,
    required Color mutedColor,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: headingColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: mutedColor,
              ),
            ),
          ],
        ),
        if (actionText != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentEmeraldLight,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.accentEmeraldLight,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // --- 1. Quick Stats Header Overview ---
  Widget _buildQuickStatsOverview({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    required int completedWorkouts,
    required int totalMinutes,
    required int calories,
  }) {
    return GlassContainer(
      type: GlassContainerType.normal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            isDark: isDark,
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF6B6B),
            value: '$completedWorkouts',
            label: 'Completed',
          ),
          _buildDivider(isDark),
          _buildStatItem(
            isDark: isDark,
            icon: Icons.timer_rounded,
            iconColor: const Color(0xFF4DABF7),
            value: '${totalMinutes}m',
            label: 'Total Time',
          ),
          _buildDivider(isDark),
          _buildStatItem(
            isDark: isDark,
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFFCC419),
            value: '$calories',
            label: 'Est. Kcal',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLightHeading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textDarkMuted : AppTheme.lightMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 28,
      width: 1,
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
    );
  }

  // --- 2. Weekly Intensity Chart ---
  Widget _buildWeeklyIntensityChart({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    required List<bool> weeklyCompletions,
    required Color headingColor,
    required Color mutedColor,
  }) {
    // Mock intensity values for visual bar heights (0.4 to 1.0)
    final barIntensities = [0.75, 1.0, 0.4, 0.9, 0.35, 0.8, 0.6];

    return GlassContainer(
      type: GlassContainerType.normal,
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected = index == _selectedDayIndex;
              final isCompleted = weeklyCompletions[index];
              final intensity = isCompleted ? 1.0 : barIntensities[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? AppColors.accentEmeraldDeep.withValues(alpha: 0.25)
                            : AppColors.accentEmeraldLight.withValues(alpha: 0.18))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentEmeraldLight
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Completion badge indicator dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.accentEmeraldLight
                              : (isDark ? Colors.white24 : Colors.black12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Bar container
                      Container(
                        height: 70,
                        width: 16,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            FractionallySizedBox(
                              heightFactor: intensity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isCompleted
                                      ? GerexGradients.primaryCTA
                                      : LinearGradient(
                                          colors: [
                                            AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                                            AppColors.accentEmeraldDeep.withValues(alpha: 0.7),
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _weekdays[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? AppColors.accentEmeraldLight
                              : mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Day Callout Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (weeklyCompletions[_selectedDayIndex]
                            ? AppColors.accentEmeraldLight
                            : AppColors.accentEmeraldDeep)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    weeklyCompletions[_selectedDayIndex]
                        ? Icons.check_circle_rounded
                        : Icons.fitness_center_rounded,
                    color: weeklyCompletions[_selectedDayIndex]
                        ? AppColors.accentEmeraldLight
                        : headingColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _defaultWorkoutNames[_selectedDayIndex],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: headingColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weeklyCompletions[_selectedDayIndex]
                            ? 'Status: Completed 100%'
                            : 'Status: Planned for ${_weekdays[_selectedDayIndex]}',
                        style: TextStyle(
                          fontSize: 11,
                          color: weeklyCompletions[_selectedDayIndex]
                              ? AppColors.accentEmeraldLight
                              : mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!weeklyCompletions[_selectedDayIndex])
                  GestureDetector(
                    onTap: () => context.push('/quick-workout'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: GerexGradients.primaryCTA,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Today's Scheduled Routine Hero Card ---
  Widget _buildTodaysRoutineCard({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    required WorkoutProvider workoutProvider,
    required bool isTodayCompleted,
  }) {
    final todayRoutineName = _defaultWorkoutNames[_selectedDayIndex];

    return GlassContainer(
      type: GlassContainerType.mint,
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentEmeraldDeep.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentEmeraldLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isTodayCompleted ? 'COMPLETED TODAY' : 'SCHEDULED TODAY',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentEmeraldLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.fitness_center_rounded,
                size: 18,
                color: isDark ? Colors.white70 : AppColors.textLightHeading.withValues(alpha: 0.7),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            todayRoutineName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textLightHeading,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetaChip(
                icon: Icons.layers_rounded,
                label: '5 Exercises',
                isDark: isDark,
              ),
              _buildMetaChip(
                icon: Icons.timer_outlined,
                label: '45 mins',
                isDark: isDark,
              ),
              _buildMetaChip(
                icon: Icons.local_fire_department_rounded,
                label: '350 kcal',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AnimatedTappable(
                  onTap: () {
                    final match = workoutProvider.workouts.firstWhere(
                      (w) => w.name.toLowerCase().contains(todayRoutineName.split(' ')[0].toLowerCase()),
                      orElse: () => Workout(
                        id: 'today_routine_${todayRoutineName.hashCode}',
                        name: todayRoutineName,
                        createdAt: DateTime.now(),
                        exercises: const [],
                      ),
                    );
                    context.push('/workout-details', extra: match);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: GerexGradients.primaryCTA,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentEmeraldDeep.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Start Workout Now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? AppColors.textDarkMuted : AppTheme.lightMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkBody : AppColors.textLightBody,
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Scheduled Reminders Section ---
  Widget _buildUpcomingRemindersSection({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    required WorkoutProvider workoutProvider,
    required Color headingColor,
    required Color mutedColor,
  }) {
    if (workoutProvider.workouts.isEmpty) {
      return GlassContainer(
        type: GlassContainerType.normal,
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        child: Column(
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 28,
              color: mutedColor,
            ),
            const SizedBox(height: 10),
            Text(
              'No workout templates scheduled',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a workout routine to set automated reminder alarms',
              style: TextStyle(fontSize: 12, color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/workout-builder'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: GerexGradients.primaryCTA,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+ Create Routine Template',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: workoutProvider.workouts.take(2).map((workout) {
        final isReminderActive = _pendingNotificationIds.contains(_notificationId(workout.id));
        return GlassContainer(
          type: GlassContainerType.sky,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 20,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isReminderActive
                          ? AppColors.accentEmeraldLight
                          : AppColors.accentEmeraldDeep)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReminderActive
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  size: 16,
                  color: isReminderActive
                      ? AppColors.accentEmeraldLight
                      : headingColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${workout.exercises.length} exercises • Alarm ${isReminderActive ? "Active" : "Off"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isReminderActive,
                activeThumbColor: AppColors.accentEmeraldLight,
                activeTrackColor: AppColors.accentEmeraldDeep.withValues(alpha: 0.5),
                onChanged: (val) => _toggleWorkoutReminder(workout, val),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 5. Categorized Workout Explorer ("What Do You Want to Train?") ---
  Widget _buildTrainingCategoryExplorer({
    required BuildContext context,
    required bool isDark,
    required ThemeData theme,
    required WorkoutProvider workoutProvider,
    required Color headingColor,
    required Color mutedColor,
  }) {
    final categories = [
      {
        'title': 'Fullbody Hypertrophy',
        'exercises': 6,
        'duration': '45 mins',
        'level': 'Intermediate',
        'icon': Icons.fitness_center_rounded,
        'type': GlassContainerType.indigo,
      },
      {
        'title': 'Lower Body Strength',
        'exercises': 5,
        'duration': '40 mins',
        'level': 'Advanced',
        'icon': Icons.directions_run_rounded,
        'type': GlassContainerType.sky,
      },
      {
        'title': 'Core & Ab Shred',
        'exercises': 4,
        'duration': '15 mins',
        'level': 'Beginner',
        'icon': Icons.accessibility_new_rounded,
        'type': GlassContainerType.mint,
      },
      {
        'title': 'Push Day Power',
        'exercises': 6,
        'duration': '50 mins',
        'level': 'Intermediate',
        'icon': Icons.sports_gymnastics_rounded,
        'type': GlassContainerType.violet,
      },
    ];

    return Column(
      children: categories.map((cat) {
        final title = cat['title'] as String;
        final exerciseCount = cat['exercises'] as int;
        final duration = cat['duration'] as String;
        final level = cat['level'] as String;
        final icon = cat['icon'] as IconData;
        final type = cat['type'] as GlassContainerType;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedTappable(
            onTap: () {
              final match = workoutProvider.workouts.firstWhere(
                (w) => w.name.toLowerCase().contains(title.split(' ')[0].toLowerCase()),
                orElse: () => Workout(
                  id: 'mock_cat_${title.hashCode}',
                  name: title,
                  createdAt: DateTime.now(),
                  exercises: const [],
                ),
              );
              context.push('/workout-details', extra: match);
            },
            child: GlassContainer(
              type: type,
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentEmeraldLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: AppColors.accentEmeraldLight,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: headingColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                level,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_outline_rounded,
                                  size: 12,
                                  color: mutedColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$exerciseCount exercises',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: mutedColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  duration,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: mutedColor,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
