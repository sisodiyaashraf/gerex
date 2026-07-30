import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/workout_provider.dart';
import '../../domain/entities/workout_entities.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/providers/notification_provider.dart';

class WorkoutTrackerScreen extends StatefulWidget {
  const WorkoutTrackerScreen({super.key});

  @override
  State<WorkoutTrackerScreen> createState() => _WorkoutTrackerScreenState();
}

class _WorkoutTrackerScreenState extends State<WorkoutTrackerScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0-indexed (Mon-Sun)
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  // Weekly completion status (1.0 = complete, 0.0 = not)
  final List<double> _completionIntensities = [0.8, 1.0, 0.0, 0.9, 0.0, 0.7, 0.0];
  final List<String> _workoutNames = [
    'Upper Body Pull',
    'Legs Destroyer',
    'Rest Day',
    'Push Day Power',
    'Rest Day',
    'Ab Shredder',
    'Rest Day'
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
              SnackBar(content: Text('Scheduled ${workout.name} successfully!')),
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
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    // Calculate real completions from WorkoutProvider
    final now = DateTime.now();
    final last7DaysCompletions = List.generate(7, (index) {
      final targetDate = now.subtract(Duration(days: 6 - index));
      final hasCompleted = workoutProvider.sessions.any((s) {
        final compDate = s.completedAt ?? s.startedAt;
        return compDate.year == targetDate.year &&
            compDate.month == targetDate.month &&
            compDate.day == targetDate.day;
      });
      return hasCompleted;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Weekly Tracker Graph
              Text(
                'Weekly Intensity Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              PastelGradientCard(
                type: PastelCardType.slate,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final isSelected = index == _selectedDayIndex;
                        final intensity = _completionIntensities[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDayIndex = index;
                            });
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 80,
                                width: 14,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    if (intensity > 0)
                                      FractionallySizedBox(
                                        heightFactor: intensity,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? GerexGradients.primaryCTA
                                                : LinearGradient(
                                                    colors: [
                                                      theme.colorScheme.primary.withValues(alpha: 0.6),
                                                      theme.colorScheme.primary,
                                                    ],
                                                  ),
                                            borderRadius: BorderRadius.circular(10),
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
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : const Color(0xFF14181F).withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Tooltip-style callout
                    PastelGradientCard(
                      type: PastelCardType.slate,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: _completionIntensities[_selectedDayIndex] > 0
                                ? theme.colorScheme.primary
                                : const Color(0xFF14181F).withValues(alpha: 0.3),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _workoutNames[_selectedDayIndex],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  _completionIntensities[_selectedDayIndex] > 0
                                      ? 'Completion status: ${(_completionIntensities[_selectedDayIndex] * 100).toInt()}%'
                                      : 'Rest Day / No Activity',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                  ),
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

              const SizedBox(height: 24),

              // 2. Daily Workout Schedule row
              Text(
                'Today\'s Workout Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              PastelGradientCard(
                type: PastelCardType.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: FaIcon(
                        FontAwesomeIcons.calendarDay,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Rest & Mobility',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Recommended duration: 20 min',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF14181F).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: last7DaysCompletions.last,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        // Mark or start mock workout
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Upcoming Workouts with reminder toggles
              Text(
                'Upcoming Workouts Reminders',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workoutProvider.workouts.take(2).length,
                itemBuilder: (context, index) {
                  final workout = workoutProvider.workouts[index];
                  return PastelGradientCard(
                    type: PastelCardType.sky,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                          child: const FaIcon(
                            FontAwesomeIcons.bell,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${workout.exercises.length} exercises scheduled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _pendingNotificationIds.contains(_notificationId(workout.id)),
                          activeThumbColor: theme.colorScheme.primary,
                          onChanged: (val) => _toggleWorkoutReminder(workout, val),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (workoutProvider.workouts.isEmpty)
                PastelGradientCard(
                  type: PastelCardType.slate,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No templates created yet. Set upcoming reminder templates by adding workout routines.',
                    style: TextStyle(
                      color: const Color(0xFF14181F).withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // 4. What Do You Want to Train
              Text(
                'What Do You Want to Train?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Categories lists
              _buildTrainCategoryCard(
                context,
                title: 'Fullbody Hypertrophy',
                exerciseCount: 6,
                duration: '45 mins',
                icon: FontAwesomeIcons.dumbbell,
                workoutProvider: workoutProvider,
                type: PastelCardType.indigo,
              ),
              const SizedBox(height: 12),
              _buildTrainCategoryCard(
                context,
                title: 'Lower Body Strength',
                exerciseCount: 5,
                duration: '40 mins',
                icon: FontAwesomeIcons.personWalking,
                workoutProvider: workoutProvider,
                type: PastelCardType.sky,
              ),
              const SizedBox(height: 12),
              _buildTrainCategoryCard(
                context,
                title: 'Core & Ab Shred',
                exerciseCount: 4,
                duration: '15 mins',
                icon: FontAwesomeIcons.solidCircleDot,
                workoutProvider: workoutProvider,
                type: PastelCardType.mint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainCategoryCard(
    BuildContext context, {
    required String title,
    required int exerciseCount,
    required String duration,
    required dynamic icon,
    required WorkoutProvider workoutProvider,
    required PastelCardType type,
  }) {
    final theme = Theme.of(context);
    return AnimatedTappable(
      onTap: () {
        // Find existing template matching title, or create a mock workout structure
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
      child: PastelGradientCard(
        type: type,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.circlePlay,
                        size: 10,
                        color: const Color(0xFF14181F).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$exerciseCount exercises',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF14181F).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FaIcon(
                        FontAwesomeIcons.clock,
                        size: 10,
                        color: const Color(0xFF14181F).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF14181F).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF14181F).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
