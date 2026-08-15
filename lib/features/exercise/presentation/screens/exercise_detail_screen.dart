import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/exercise.dart';
import '../widgets/exercise_image_widget.dart';
import '../../../../features/workout/presentation/providers/workout_provider.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/providers/notification_provider.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final bool isPicker;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.isPicker = false,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _isDescriptionExpanded = false;
  int _selectedReps = 10;

  void _selectExerciseReminder(BuildContext context) async {
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
      if (time != null && context.mounted) {
        final scheduledTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        final provider = context.read<NotificationProvider>();
        await provider.scheduleExerciseReminder(
          exerciseId: widget.exercise.id,
          exerciseName: widget.exercise.name,
          startsAt: scheduledTime,
          imageUrl: widget.exercise.imageUrl,
          instructionsCount: widget.exercise.instructions.length,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reminder scheduled for ${widget.exercise.name} at ${scheduledTime.toString().substring(0, 16)}',
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

    // Dynamic calculations
    final difficulty = widget.exercise.difficulty;
    final baseBurn = widget.exercise.baseCalorieBurnPerRep;
    final totalBurn = _selectedReps * baseBurn;

    // Expandable text description
    final description = 'The ${widget.exercise.name} targeting ${widget.exercise.muscleGroup} is an excellent exercise for building muscular strength and cardiovascular stamina. It requires using ${widget.exercise.equipment} with strict biomechanical control to avoid spinal pressure and focus load on key muscle pathways.';

    Color difficultyColor = theme.colorScheme.primary;
    final diffLower = difficulty.toLowerCase();
    if (diffLower == 'beginner') {
      difficultyColor = const Color(0xFF10B981); // Emerald
    } else if (diffLower == 'intermediate') {
      difficultyColor = const Color(0xFFF59E0B); // Amber
    } else {
      difficultyColor = const Color(0xFFEF4444); // Red/Expert/Advanced
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
      'Expert': LinearGradient(
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
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.alarm_add_rounded),
                      onPressed: () => _selectExerciseReminder(context),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.exercise.name,
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
                                child: ExerciseImageWidget(
                                  imagePath: widget.exercise.effectiveImagePath,
                                  removeBackground: widget.exercise.removeBackground,
                                  size: 56.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exercise Breakdown',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatChip(
                            theme,
                            difficulty,
                            'Difficulty',
                            difficultyColor,
                            FontAwesomeIcons.circleInfo,
                          ),
                          _buildStatChip(
                            theme,
                            widget.exercise.equipment,
                            'Equipment',
                            const Color(0xFF38BDF8),
                            FontAwesomeIcons.screwdriverWrench,
                          ),
                          _buildStatChip(
                            theme,
                            '${totalBurn.toStringAsFixed(1)} kcal',
                            'Calories',
                            const Color(0xFFF43F5E),
                            FontAwesomeIcons.fire,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Description', difficultyColor, theme),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(
                          () =>
                              _isDescriptionExpanded = !_isDescriptionExpanded,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border(
                              left: BorderSide(
                                color: difficultyColor,
                                width: 3,
                              ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                maxLines: _isDescriptionExpanded ? null : 3,
                                overflow: _isDescriptionExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDescriptionExpanded
                                    ? 'Read Less'
                                    : 'Read More',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: difficultyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('How To Do It', difficultyColor, theme),
                      const SizedBox(height: 12),
                      if (widget.exercise.instructions.isEmpty)
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
                          child: const Text('No instruction steps registered for this exercise.'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.exercise.instructions.length,
                          itemBuilder: (context, idx) {
                            final step = widget.exercise.instructions[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: difficultyColor.withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: difficultyColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          color: difficultyColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.4) : theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
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
                                      child: Text(
                                        step,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('Custom Repetitions Count', difficultyColor, theme),
                      const SizedBox(height: 12),
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.3) : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                            width: 1,
                          ),
                        ),
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 36,
                          physics: const FixedExtentScrollPhysics(),
                          perspective: 0.005,
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedReps = index + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 100,
                            builder: (context, index) {
                              final itemValue = index + 1;
                              final isSelected = itemValue == _selectedReps;
                              return Center(
                                child: Text(
                                  '$itemValue Reps',
                                  style: TextStyle(
                                    fontSize: isSelected ? 18 : 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? difficultyColor
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 140),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.isPicker)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: difficultyColor),
                        foregroundColor: difficultyColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.8),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.robot, size: 18),
                      label: const Text(
                        'Live AI Trainer Feedback',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final name = widget.exercise.name.toLowerCase();
                        String? targetKey;
                        if (name.contains('squat')) {
                          targetKey = 'squat';
                        } else if (name.contains('push') || name.contains('pushup')) {
                          targetKey = 'push_up';
                        } else if (name.contains('jumping') || name.contains('jack')) {
                          targetKey = 'jumping_jack';
                        } else if (name.contains('plank')) {
                          targetKey = 'plank';
                        } else if (widget.exercise.posePattern != null) {
                          targetKey = 'custom';
                        }
                        context.push('/pose-feedback', extra: {
                          'targetExercise': targetKey,
                          'customPattern': widget.exercise.posePattern,
                        });
                      },
                    ),
                  if (!widget.isPicker) const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [difficultyColor.withValues(alpha: 0.9), difficultyColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: difficultyColor.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (widget.isPicker) {
                          Navigator.pop(context, _selectedReps);
                        } else {
                          if (workoutProvider.isSessionActive) {
                            workoutProvider.addExerciseToSession(widget.exercise);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${widget.exercise.name} with $_selectedReps reps to active workout session!')),
                            );
                            context.pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No active workout session. Open the Workout tab or Workout Builder to save exercises!')),
                            );
                          }
                        }
                      },
                      child: Text(
                        widget.isPicker ? 'Confirm Custom Reps' : 'Save to Active Workout',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
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
}
