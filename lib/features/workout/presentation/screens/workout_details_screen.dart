import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/workout_provider.dart';
import '../../domain/entities/workout_entities.dart';
import 'package:gerex/core/providers/notification_provider.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import 'package:gerex/core/theme/app_theme.dart';

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
          final firstExercise = widget.workout.exercises.isNotEmpty
              ? widget.workout.exercises.first.exercise
              : null;
          context.read<NotificationProvider>().sendNotification(
            'Workout Scheduled',
            'Your workout "${widget.workout.name}" is scheduled for ${_scheduledDateTime.toString().substring(0, 16)}.',
          );
          context.read<NotificationProvider>().scheduleWorkoutReminder(
            workoutId: widget.workout.id,
            workoutName: widget.workout.name,
            startsAt: _scheduledDateTime!,
            exercisesCount: widget.workout.exercises.length,
            imageUrl: firstExercise?.imageUrl,
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

    final String difficulty = exerciseCount > 8
        ? 'Advanced'
        : exerciseCount > 4
            ? 'Intermediate'
            : 'Beginner';

    Color difficultyColor = theme.colorScheme.primary;
    if (difficulty == 'Beginner') {
      difficultyColor = const Color(0xFF10B981); // Emerald Green
    } else if (difficulty == 'Intermediate') {
      difficultyColor = const Color(0xFFF59E0B); // Amber
    } else if (difficulty == 'Advanced') {
      difficultyColor = const Color(0xFFEF4444); // Red/Coral
    }

    final isDark = theme.brightness == Brightness.dark;

    final difficultyGradients = {
      'Beginner': LinearGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.15),
          isDark ? const Color(0xFF14181F).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'Intermediate': LinearGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.15),
          isDark ? const Color(0xFF14181F).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      'Advanced': LinearGradient(
        colors: [
          const Color(0xFFEF4444).withValues(alpha: 0.15),
          isDark ? const Color(0xFF14181F).withValues(alpha: 0.95) : const Color(0xFFF8FAFC).withValues(alpha: 0.95),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    };

    final headerGradient = difficultyGradients[difficulty] ?? (isDark ? GerexGradients.scaffoldBackground : const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFEEF2F6)]));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
            // Difficulty-specific glow blobs in background
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
                      color: difficultyColor.withValues(alpha: isDark ? 0.15 : 0.06),
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
                      color: difficultyColor.withValues(alpha: isDark ? 0.1 : 0.04),
                      blurRadius: 120,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.workout.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: headerGradient,
                      ),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                difficultyColor.withValues(alpha: 0.3),
                                difficultyColor.withValues(alpha: 0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: difficultyColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF14181F).withValues(alpha: 0.6),
                                border: Border.all(
                                  color: difficultyColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.dumbbell,
                                  size: 32,
                                  color: difficultyColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: FaIcon(
                        _isFavorited
                            ? FontAwesomeIcons.solidHeart
                            : FontAwesomeIcons.heart,
                        color: _isFavorited
                            ? Colors.redAccent
                            : theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFavorited = !_isFavorited;
                        });
                      },
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Difficulty Tag line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Workout Routine',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: difficultyColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              difficulty.toUpperCase(),
                              style: TextStyle(
                                color: difficultyColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Workout Stat Chips row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatChip(
                            theme,
                            '$exerciseCount',
                            'Exercises',
                            const Color(0xFF38BDF8), // Blue/Teal Accent
                            FontAwesomeIcons.list,
                          ),
                          _buildStatChip(
                            theme,
                            estimatedDuration,
                            'Duration',
                            const Color(0xFFF59E0B), // Amber Accent
                            FontAwesomeIcons.clock,
                          ),
                          _buildStatChip(
                            theme,
                            '~$estimatedCalories kcal',
                            'Calories',
                            const Color(0xFFF43F5E), // Coral/Red Accent
                            FontAwesomeIcons.fire,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Schedule section
                      _buildSectionHeader('Schedule Workout', difficultyColor, theme),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectSchedule(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                              width: 1,
                            ),
                            boxShadow: isDark ? null : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.calendarCheck,
                                color: difficultyColor,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _scheduledDateTime == null
                                      ? 'Not Scheduled Yet'
                                      : 'Scheduled for ${_weekdays[_scheduledDateTime!.weekday - 1]} at ${_scheduledDateTime!.hour.toString().padLeft(2, '0')}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Equipments Needed
                      if (equipments.isNotEmpty) ...[
                        _buildSectionHeader('Equipments You Will Need', difficultyColor, theme),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: equipments.map((equip) => _buildEquipmentChip(theme, equip, difficultyColor)).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Exercises list
                      _buildSectionHeader('Exercise Routine', difficultyColor, theme),
                      const SizedBox(height: 12),
                      if (widget.workout.exercises.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                              width: 1,
                            ),
                          ),
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                                    width: 1,
                                  ),
                                  boxShadow: isDark ? null : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: difficultyColor.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: difficultyColor.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            color: difficultyColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.exercise?.name ?? 'Exercise',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                                            ),
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
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 100), // Space for sticky bottom slide button
                    ]),
                  ),
                ),
              ],
            ),

            // Sticky Bottom Slide-to-Start Button
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
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

  Widget _buildStatChip(
    ThemeData theme,
    String value,
    String label,
    Color color,
    dynamic icon,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.03),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              FaIcon(
                icon,
                color: color,
                size: 14,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: color,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentChip(
    ThemeData theme,
    String equipment,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/svg icons/barbel.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              accentColor,
              BlendMode.srcIn,
            ),
            errorBuilder: (c, e, s) => FaIcon(
              FontAwesomeIcons.dumbbell,
              color: accentColor,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            equipment,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}

