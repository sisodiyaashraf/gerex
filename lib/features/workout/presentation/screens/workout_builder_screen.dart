import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../../exercise/presentation/screens/add_exercise_screen.dart';
import '../../../../models/exercise.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
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
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Create Template',
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
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Template Name Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                borderRadius: 16,
                child: TextFormField(
                  style: TextStyle(color: AppColors.textDarkHeading),
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    labelStyle: TextStyle(color: AppColors.accentEmeraldLight),
                    hintText: 'e.g. Upper Body Focus',
                    hintStyle: TextStyle(color: AppColors.textDarkMuted),
                    border: InputBorder.none,
                  ),
                  validator: Validators.validateWorkoutName,
                  onSaved: (val) => _name = val ?? '',
                ),
              ),
            ),

            // Exercises Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Exercises List',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDarkHeading,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateToAddExercises(context),
                    icon: const Icon(Icons.add, color: AppColors.accentEmeraldLight),
                    label: const Text(
                      'Add Exercise',
                      style: TextStyle(
                        color: AppColors.accentEmeraldLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // List of exercises in template with drag-to-reorder
            Expanded(
              child: _exercises.isEmpty
                  ? _buildEmptyState(context)
                  : Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.transparent, // Clean drag background
                      ),
                      child: ReorderableListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Dismissible(
                              key: ValueKey('dismiss_builder_${item.exerciseId}_$index'),
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
                              },
                              child: GlassContainer(
                                padding: const EdgeInsets.all(12),
                                borderRadius: 16,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.drag_indicator_rounded, color: Colors.grey, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.exercise?.name ?? 'Exercise',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textDarkHeading,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
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
                                            label: 'Weight',
                                            value: item.weight.toString(),
                                            onChanged: (val) {
                                              _updateExercise(index, weight: double.tryParse(val));
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildInlineInput(
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

            // Save Template Sticky Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: GerexGradients.primaryCTA,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentEmeraldLight.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: workoutProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            _formKey.currentState?.save();
                            if (_exercises.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Add at least one exercise.'),
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
                                  content: Text('Workout template saved!'),
                                  backgroundColor: AppColors.accentEmeraldDeep,
                                ),
                              );
                            }
                          }
                        },
                  child: workoutProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Template',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
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
                  FontAwesomeIcons.clipboardList,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No exercises added yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDarkHeading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "+ Add Exercise" at the top right to select exercises from the library and build your routine split.',
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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