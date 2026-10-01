import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../../exercise/presentation/screens/add_exercise_screen.dart';
import '../../../../models/exercise.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/animated_tappable.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:gerex/core/validation/validators.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  const WorkoutBuilderScreen({super.key});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  final List<WorkoutExercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExerciseProvider>().fetchExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    final headingColor = isDark ? AppColors.textDarkHeading : theme.colorScheme.onSurface;
    final mutedColor = isDark ? AppColors.textDarkMuted : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: const GerexAppBar.standard(
        title: 'Create Template',
        subtitle: 'Custom Workout Design',
      ),
      body: LiquidBackground(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Template Name Input Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  type: GlassContainerType.normal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.accentEmeraldLight,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          style: TextStyle(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Template Routine Name',
                            labelStyle: const TextStyle(
                              color: AppColors.accentEmeraldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            hintText: 'e.g. Upper Body Power & Core',
                            hintStyle: TextStyle(
                              color: mutedColor.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          validator: Validators.validateWorkoutName,
                          onSaved: (val) => _name = val ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Exercises List Header with Add Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercises Routine Split',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: headingColor,
                          ),
                        ),
                        Text(
                          '${_exercises.length} exercises added',
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                    AnimatedTappable(
                      onTap: () => _navigateToAddExercises(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmeraldLight.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: AppColors.accentEmeraldLight,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add Exercise',
                              style: TextStyle(
                                color: AppColors.accentEmeraldLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // List of exercises with drag-to-reorder & dismissible swipe
              Expanded(
                child: _exercises.isEmpty
                    ? _buildEmptyState(context, headingColor, mutedColor)
                    : Theme(
                        data: theme.copyWith(
                          canvasColor: Colors.transparent,
                        ),
                        child: ReorderableListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
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
                              key: ValueKey('builder_ex_${item.exerciseId}_$index'),
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Dismissible(
                                key: ValueKey('dismiss_builder_${item.exerciseId}_$index'),
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
                                          fontSize: 11,
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
                                },
                                child: GlassContainer(
                                  type: GlassContainerType.normal,
                                  padding: const EdgeInsets.all(14),
                                  borderRadius: 18,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.drag_indicator_rounded,
                                            color: mutedColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
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
                                          const SizedBox(width: 6),
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
                                          const SizedBox(width: 6),
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
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _buildInlineInput(
                                              isDark: isDark,
                                              headingColor: headingColor,
                                              mutedColor: mutedColor,
                                              label: 'Rest (s)',
                                              value: item.restTime.toString(),
                                              onChanged: (val) {
                                                _updateExercise(index, rest: int.tryParse(val));
                                              },
                                            ),
                                          ),
                                        ],
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

              // Save Template Bottom Sticky Action
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16.0,
                  8.0,
                  16.0,
                  MediaQuery.of(context).padding.bottom + 12.0,
                ),
                child: AnimatedTappable(
                  onTap: workoutProvider.isLoading
                      ? () {}
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            _formKey.currentState?.save();
                            if (_exercises.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please add at least one exercise.'),
                                ),
                              );
                              return;
                            }

                            final success = await workoutProvider
                                .createWorkoutTemplate(_name, _exercises);

                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Workout template saved successfully!'),
                                  backgroundColor: AppColors.accentEmeraldDeep,
                                ),
                              );
                            }
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: GerexGradients.primaryCTA,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentEmeraldDeep.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: workoutProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save Workout Template',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddExercises(BuildContext context) async {
    final List<String> currentIds = _exercises.map((e) => e.exerciseId).toList();
    final dynamic result = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) => AddExerciseScreen(initiallySelectedIds: currentIds),
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
                  Icons.format_list_bulleted_add,
                  color: AppColors.accentEmeraldLight,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Exercises in Template',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "+ Add Exercise" at the top right to select exercises from your library and construct your routine split.',
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
          fontSize: 12,
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
    int? rest,
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
      restTime: rest ?? current.restTime,
      sequenceOrder: index,
    );
  }
}