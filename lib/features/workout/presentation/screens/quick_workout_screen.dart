import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../../exercise/presentation/screens/add_exercise_screen.dart';
import '../../../../models/exercise.dart';

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

      // If matches are empty, search by muscle group/category
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
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final exProvider = Provider.of<ExerciseProvider>(context);

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Quick Workout',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkHeading,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDarkHeading),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Light Hero Header block
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: GerexGradients.heroMintLight,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentEmeraldLight.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.bolt, color: AppColors.badgeTealText, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Quick Setup',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLightHeading,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a focus area or add specific movements to configure your workout splits in seconds.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLightBody.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Focus Area Quick Picks
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildPresetChip('Full Body', exProvider.exercises),
                    const SizedBox(width: 8),
                    _buildPresetChip('Core', exProvider.exercises),
                    const SizedBox(width: 8),
                    _buildPresetChip('Cardio', exProvider.exercises),
                  ],
                ),
              ),

              // AI Live Form Tracker Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  borderGradient: _aiTrackingEnabled 
                      ? LinearGradient(
                          colors: [
                            AppColors.accentEmeraldLight.withValues(alpha: 0.25),
                            AppColors.accentEmeraldLight.withValues(alpha: 0.05),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _aiTrackingEnabled 
                              ? AppColors.accentEmeraldLight.withValues(alpha: 0.15) 
                              : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.robot,
                          color: AppColors.accentEmeraldLight,
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDarkHeading,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Real-time posture checking, reps count & feedback coaching.',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _aiTrackingEnabled,
                        activeTrackColor: AppColors.accentEmeraldLight,
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

              // Exercises List
              Expanded(
                child: _exercises.isEmpty
                    ? _buildEmptyState(context)
                    : Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.transparent, // Fix drag shadow color
                        ),
                        child: ReorderableListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
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
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Dismissible(
                                key: ValueKey('dismiss_quick_${item.exerciseId}_$index'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.destructiveRed.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: AppColors.destructiveRed),
                                ),
                                onDismissed: (_) {
                                  setState(() {
                                    _exercises.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Exercise removed')),
                                  );
                                },
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(12),
                                  borderRadius: 16,
                                  child: Row(
                                    children: [
                                      // Drag Handle
                                      const Icon(Icons.drag_indicator_rounded, color: Colors.grey, size: 20),
                                      const SizedBox(width: 8),

                                      // Main info & Inputs
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              item.exercise?.name ?? 'Exercise',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textDarkHeading,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildInlineInput(
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
                                                    label: 'Weight (kg)',
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

          // Add Exercises floating button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 90,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.cardDarkGlass,
              foregroundColor: AppColors.accentEmeraldLight,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              onPressed: () async {
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
            ),
          ),

          // Slide to confirm start trigger
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
    );
  }

  Widget _buildPresetChip(String label, List<Exercise> library) {
    final isSelected = _selectedPreset == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: AppColors.accentEmeraldLight.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accentEmeraldLight : Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.accentEmeraldLight : Colors.white10,
        width: 1.0,
      ),
      onSelected: (val) {
        if (val) {
          _applyPreset(label, library);
        }
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.dumbbell,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No exercises configured',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDarkHeading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a preset chip above or tap "+ Add Exercise" to compile your quick session routine.',
              style: TextStyle(
                color: AppColors.textDarkMuted,
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
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 11),
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