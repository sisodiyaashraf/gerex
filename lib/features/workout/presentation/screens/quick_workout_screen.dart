import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../../exercise/presentation/screens/add_exercise_screen.dart';
import '../../../../models/exercise.dart';
import 'package:gerex/core/presentation/widgets/gerex_app_bar.dart';

class QuickWorkoutScreen extends StatefulWidget {
  const QuickWorkoutScreen({super.key});

  @override
  State<QuickWorkoutScreen> createState() => _QuickWorkoutScreenState();
}

class _QuickWorkoutScreenState extends State<QuickWorkoutScreen> {
  final List<WorkoutExercise> _exercises = [];
  String _selectedPreset = 'None';
  bool _aiTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().fetchExercises();
    });
  }

  void _applyPreset(String preset, List<Exercise> library) {
    setState(() {
      _selectedPreset = preset;
      _exercises.clear();

      List<Exercise> matches = [];
      if (preset == 'Full Body') {
        matches = library.where((e) => ['squat', 'bench press', 'pullups', 'deadlift'].contains(e.name.toLowerCase())).toList();
      } else if (preset == 'Core') {
        matches = library.where((e) => ['crunches', 'plank', 'situps'].contains(e.name.toLowerCase())).toList();
      } else if (preset == 'Cardio') {
        matches = library.where((e) => ['jumping jacks', 'rope jumping', 'running'].contains(e.name.toLowerCase())).toList();
      }

      // If matches are empty, search by category or muscle group
      if (matches.isEmpty) {
        if (preset == 'Full Body') {
          matches = library.take(3).toList();
        } else if (preset == 'Core') {
          matches = library.where((e) => e.primaryMuscles.contains('abdominals')).take(3).toList();
        } else if (preset == 'Cardio') {
          matches = library.where((e) => e.category.toLowerCase() == 'cardio').take(3).toList();
        }
      }

      for (var ex in matches) {
        _exercises.add(
          WorkoutExercise(
            id: '',
            workoutId: '',
            exerciseId: ex.id,
            exercise: ex,
            sets: 3,
            reps: 10,
            weight: 0,
            restTime: 60,
            sequenceOrder: _exercises.length,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final exProvider = Provider.of<ExerciseProvider>(context);

    final headingColor = isDark ? AppColors.textDarkHeading : theme.colorScheme.onSurface;
    final mutedColor = isDark ? AppColors.textDarkMuted : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: const GerexAppBar.standard(
        title: 'Quick Workout Setup',
        subtitle: 'Instant Routine Builder',
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // Hero Banner Block
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GlassContainer(
                    type: GlassContainerType.mint,
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentEmeraldLight.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: AppColors.accentEmeraldLight,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Instant Routine Builder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pick a focus preset or customize exercises, sets, and reps to launch your workout in seconds.',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Focus Area Preset Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildPresetChip('Full Body', exProvider.exercises, isDark),
                      const SizedBox(width: 8),
                      _buildPresetChip('Core', exProvider.exercises, isDark),
                      const SizedBox(width: 8),
                      _buildPresetChip('Cardio', exProvider.exercises, isDark),
                    ],
                  ),
                ),

                // AI Live Form Tracker Tile
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: GlassContainer(
                    type: _aiTrackingEnabled ? GlassContainerType.mint : GlassContainerType.normal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: 18,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_aiTrackingEnabled
                                    ? AppColors.accentEmeraldLight
                                    : AppColors.accentEmeraldDeep)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            color: _aiTrackingEnabled
                                ? AppColors.accentEmeraldLight
                                : headingColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Live Form Tracker',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: headingColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Real-time camera posture checks & rep tracking',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _aiTrackingEnabled,
                          activeThumbColor: AppColors.accentEmeraldLight,
                          activeTrackColor: AppColors.accentEmeraldDeep.withValues(alpha: 0.5),
                          onChanged: (val) {
                            setState(() {
                              _aiTrackingEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Exercises Reorderable List
                Expanded(
                  child: _exercises.isEmpty
                      ? _buildEmptyState(context, headingColor, mutedColor)
                      : Theme(
                          data: theme.copyWith(
                            canvasColor: Colors.transparent,
                          ),
                          child: ReorderableListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                            itemCount: _exercises.length,
                            onReorder: (oldIdx, newIdx) {
                              setState(() {
                                if (newIdx > oldIdx) newIdx--;
                                final item = _exercises.removeAt(oldIdx);
                                _exercises.insert(newIdx, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              final item = _exercises[index];
                              return Padding(
                                key: ValueKey('quick_ex_${item.exerciseId}_$index'),
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Dismissible(
                                  key: ValueKey('dismiss_quick_${item.exerciseId}_$index'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      gradient: GerexGradients.destructive,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: const EdgeInsets.only(right: 20),
                                    alignment: Alignment.centerRight,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'REMOVE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  onDismissed: (_) {
                                    setState(() {
                                      _exercises.removeAt(index);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Exercise removed from quick routine'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: GlassContainer(
                                    type: GlassContainerType.normal,
                                    padding: const EdgeInsets.all(14),
                                    borderRadius: 18,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.drag_indicator_rounded,
                                          color: mutedColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.exercise?.name ?? 'Exercise',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: headingColor,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.close_rounded,
                                                      size: 16,
                                                      color: mutedColor,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () {
                                                      setState(() {
                                                        _exercises.removeAt(index);
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildInlineInput(
                                                      isDark: isDark,
                                                      headingColor: headingColor,
                                                      mutedColor: mutedColor,
                                                      label: 'Sets',
                                                      value: item.sets.toString(),
                                                      onChanged: (val) {
                                                        _updateExercise(index, sets: int.tryParse(val));
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _buildInlineInput(
                                                      isDark: isDark,
                                                      headingColor: headingColor,
                                                      mutedColor: mutedColor,
                                                      label: 'Reps',
                                                      value: item.reps.toString(),
                                                      onChanged: (val) {
                                                        _updateExercise(index, reps: int.tryParse(val));
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _buildInlineInput(
                                                      isDark: isDark,
                                                      headingColor: headingColor,
                                                      mutedColor: mutedColor,
                                                      label: 'Kg',
                                                      value: item.weight.toString(),
                                                      onChanged: (val) {
                                                        _updateExercise(index, weight: double.tryParse(val));
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),

            // Floating Add Exercise Button
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + (_exercises.isNotEmpty ? 80 : 20),
              child: AnimatedTappable(
                onTap: () async {
                  final List<String> currentIds = _exercises.map((e) => e.exerciseId).toList();
                  final dynamic result = await Navigator.of(context).push<List<Exercise>>(
                    MaterialPageRoute(
                      builder: (_) => AddExerciseScreen(
                        initiallySelectedIds: currentIds,
                      ),
                    ),
                  );

                  if (result != null && result is List<Exercise>) {
                    setState(() {
                      for (var ex in result) {
                        if (!_exercises.any((e) => e.exerciseId == ex.id)) {
                          _exercises.add(
                            WorkoutExercise(
                              id: '',
                              workoutId: '',
                              exerciseId: ex.id,
                              exercise: ex,
                              sets: 3,
                              reps: 10,
                              weight: 0,
                              restTime: 60,
                              sequenceOrder: _exercises.length,
                            ),
                          );
                        }
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: GerexGradients.primaryCTA,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentEmeraldDeep.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Add Exercise',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Slide to Start Session Slider Trigger
            if (_exercises.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: SlideToConfirmButton(
                  label: 'Slide to Start Session',
                  onConfirm: () {
                    final workout = Workout(
                      id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
                      name: 'Custom Quick Workout',
                      exercises: _exercises,
                      createdAt: DateTime.now(),
                    );
                    workoutProvider.startWorkoutSession(workout, enableAiTracking: _aiTrackingEnabled);
                    context.pushReplacement('/session');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, List<Exercise> library, bool isDark) {
    final isSelected = _selectedPreset == label;
    return GestureDetector(
      onTap: () => _applyPreset(label, library),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentEmeraldLight.withValues(alpha: 0.2)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accentEmeraldLight
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.accentEmeraldLight
                : (isDark ? AppColors.textDarkBody : AppColors.textLightBody),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color headingColor, Color mutedColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentEmeraldLight.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.accentEmeraldLight,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Exercises Added Yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a preset chip above (Full Body, Core, Cardio) or tap "+ Add Exercise" to start building your custom routine.',
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineInput({
    required bool isDark,
    required Color headingColor,
    required Color mutedColor,
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        style: TextStyle(
          color: headingColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: mutedColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }

  void _updateExercise(
    int index, {
    int? sets,
    int? reps,
    double? weight,
  }) {
    final current = _exercises[index];
    _exercises[index] = WorkoutExercise(
      id: current.id,
      workoutId: current.workoutId,
      exerciseId: current.exerciseId,
      exercise: current.exercise,
      sets: sets ?? current.sets,
      reps: reps ?? current.reps,
      weight: weight ?? current.weight,
      restTime: current.restTime,
      sequenceOrder: index,
    );
  }
}