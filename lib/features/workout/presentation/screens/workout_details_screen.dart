import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/workout_provider.dart';
import '../../domain/entities/workout_entities.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailsScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  bool _isFavorited = false;
  DateTime? _scheduledDateTime;

  void _selectSchedule(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _scheduledDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        if (context.mounted) {
          context.read<NotificationProvider>().sendNotification(
            'Workout Scheduled',
            'Your workout "${widget.workout.name}" is scheduled for ${_scheduledDateTime.toString().substring(0, 16)}.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scheduled successfully for ${_scheduledDateTime.toString().substring(0, 16)}',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    // Dynamic calorie estimation
    final exerciseCount = widget.workout.exercises.length;
    final estimatedCalories = exerciseCount * 65;
    final estimatedDuration = '${exerciseCount * 7} mins';

    // Unique list of equipments needed
    final equipments = widget.workout.exercises
        .map((e) => (e.exercise?.equipment == null || e.exercise!.equipment.isEmpty)
            ? 'Bodyweight'
            : e.exercise!.equipment)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.redAccent : null,
            ),
            onPressed: () {
              setState(() {
                _isFavorited = !_isFavorited;
              });
            },
          ),
        ],
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Overview Card
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoColumn(
                              theme,
                              'Exercises',
                              '$exerciseCount',
                              FontAwesomeIcons.list,
                            ),
                            _buildInfoColumn(
                              theme,
                              'Duration',
                              estimatedDuration,
                              FontAwesomeIcons.clock,
                            ),
                            _buildInfoColumn(
                              theme,
                              'Calories',
                              '~$estimatedCalories kcal',
                              FontAwesomeIcons.fire,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Difficulty & Schedule Button Rows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Difficulty Level',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                exerciseCount > 5 ? 'Intermediate' : 'Beginner',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectSchedule(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Schedule Workout',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _scheduledDateTime == null
                                        ? 'Not Scheduled'
                                        : '${_weekdays[_scheduledDateTime!.weekday - 1]} at ${_scheduledDateTime!.hour.toString().padLeft(2, '0')}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Equipment Needs
                  Text(
                    'You\'ll Need',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: equipments.length,
                      itemBuilder: (context, index) {
                        final equip = equipments[index];
                        return GlassContainer(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/svg icons/barbel.svg',
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  theme.colorScheme.primary,
                                  BlendMode.srcIn,
                                ),
                                errorBuilder: (c, e, s) => FaIcon(
                                  FontAwesomeIcons.dumbbell,
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                equip,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Exercises lists grouped by set
                  Text(
                    'Exercises List',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.workout.exercises.isEmpty)
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'This workout template currently contains no exercises.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.workout.exercises.length,
                      itemBuilder: (context, index) {
                        final item = widget.workout.exercises[index];
                        return GlassContainer(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.exercise?.name ?? 'Exercise',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Target: ${item.sets} sets x ${item.reps} reps • ${item.exercise?.muscleGroup ?? 'General'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // 4. Sticky Bottom Start Button
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SlideToConfirmButton(
                label: 'Slide to Start Workout',
                knobIcon: FontAwesomeIcons.play,
                onConfirm: () {
                  workoutProvider.startWorkoutSession(widget.workout);
                  context.push('/session');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    ThemeData theme,
    String label,
    String value,
    dynamic icon,
  ) {
    return Column(
      children: [
        FaIcon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.8), size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}
