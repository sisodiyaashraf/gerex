import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';
import '../../../exercise/domain/entities/exercise.dart';
import '../../../ai/presentation/providers/ai_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Create Template')),
      body: LiquidBackground(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Template Name Input
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    hintText: 'e.g. Upper Body Focus',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: Validators.validateWorkoutName,
                  onSaved: (val) => _name = val ?? '',
                ),
              ),

              // Exercises Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exercises', style: theme.textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => _showAddExerciseSelector(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // List of exercises in template
              Expanded(
                child: _exercises.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises added yet.\nTap "Add Exercise" to start.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final item = _exercises[index];
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.exercise?.name ?? 'Exercise',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () => _suggestAlternatives(
                                                context, index, item),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.swap_horiz_rounded,
                                                  size: 14,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Suggest Swap',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        theme.colorScheme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: theme.colorScheme.error,
                                      onPressed: () {
                                        setState(() {
                                          _exercises.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.sets.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Sets',
                                          isDense: true,
                                        ),
                                        validator: Validators.validateSetsCount,
                                        onChanged: (val) {
                                          _updateExercise(
                                            index,
                                            sets: int.tryParse(val) ?? 3,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.reps.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps',
                                          isDense: true,
                                        ),
                                        validator: Validators.validateReps,
                                        onChanged: (val) {
                                          _updateExercise(
                                            index,
                                            reps: int.tryParse(val) ?? 10,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.weight.toString(),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Weight (kg)',
                                          isDense: true,
                                        ),
                                        validator: Validators.validateWeight,
                                        onChanged: (val) {
                                          _updateExercise(
                                            index,
                                            weight: double.tryParse(val) ?? 0.0,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.restTime.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Rest (s)',
                                          isDense: true,
                                        ),
                                        onChanged: (val) {
                                          _updateExercise(
                                            index,
                                            rest: int.tryParse(val) ?? 60,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Save Panel
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
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
                                ),
                              );
                            }
                          }
                        },
                  child: workoutProvider.isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Save Template',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  void _showAddExerciseSelector(BuildContext context) {
    final exProvider = context.read<ExerciseProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Select Exercise'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: exProvider,
            builder: (context, _) {
              if (exProvider.isLoading && exProvider.exercises.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                itemCount: exProvider.exercises.length,
                itemBuilder: (context, idx) {
                  final ex = exProvider.exercises[idx];
                  return ListTile(
                    title: Text(ex.name),
                    subtitle: Text('${ex.muscleGroup} • ${ex.equipment}'),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () {
                      setState(() {
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
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _suggestAlternatives(
    BuildContext context,
    int index,
    WorkoutExercise item,
  ) {
    final theme = Theme.of(context);
    final aiProvider = context.read<AIProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: FutureBuilder<List<String>>(
            future: aiProvider.getExerciseAlternatives(
              item.exercise?.name ?? '',
              item.exercise?.muscleGroup ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Analyzing alternatives with Coach AI...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                  ],
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'AI swap failed. Please try again.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                );
              }

              final alternatives = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AI Alternatives for ${item.exercise?.name}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select an alternative to swap instantly:',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: alternatives.map((altName) {
                          return Card(
                            color: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              ),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                altName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Targets: ${item.exercise?.muscleGroup ?? "Same group"}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Icon(
                                Icons.swap_horiz_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              onTap: () {
                                final replacement = Exercise(
                                  id: 'swapped_${DateTime.now().millisecondsSinceEpoch}',
                                  name: altName,
                                  muscleGroup: item.exercise?.muscleGroup ?? 'Other',
                                  equipment: item.exercise?.equipment ?? 'Other',
                                  instructions: const [],
                                );
                                setState(() {
                                  _exercises[index] = WorkoutExercise(
                                    id: item.id,
                                    workoutId: item.workoutId,
                                    exerciseId: replacement.id,
                                    exercise: replacement,
                                    sets: item.sets,
                                    reps: item.reps,
                                    weight: item.weight,
                                    restTime: item.restTime,
                                    sequenceOrder: item.sequenceOrder,
                                  );
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
