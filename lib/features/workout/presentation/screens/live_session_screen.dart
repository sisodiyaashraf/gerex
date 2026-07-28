import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LiveSessionScreen extends StatelessWidget {
  const LiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<WorkoutProvider>(context);

    // Format duration to MM:SS or HH:MM:SS
    String formatDuration(int totalSeconds) {
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    if (!provider.isSessionActive) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Workout')),
        body: LiquidBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Workout Session',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a workout from a template or create a custom one from scratch.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Text(
              provider.activeSessionName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              formatDuration(provider.sessionDurationSeconds),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmCancelSession(context, provider),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
      body: LiquidBackground(
        child: Column(
        children: [
          // Rest Timer Panel
          if (provider.isRestActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rest Timer: ${provider.restTimeRemaining}s / ${provider.restTimerTotal}s',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => provider.skipRestTimer(),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),


          // Workout Player List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.liveExercises.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.liveExercises.length) {
                  // Bottom Actions
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showAddExerciseSheet(context, provider),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Exercise'),
                      ),
                      const SizedBox(height: 24),
                      provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SlideToConfirmButton(
                              label: 'Slide to Finish Workout',
                              knobIcon: FontAwesomeIcons.solidCircleCheck,
                              onConfirm: () async {
                                final done = await provider.finishWorkoutSession();
                                if (done && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Workout complete! Saved to logs.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  context.pop();
                                }
                              },
                            ),
                      const SizedBox(height: 40),
                    ],
                  );
                }

                final exercise = provider.liveExercises[index];
                final sets = provider.liveSets[exercise.id] ?? [];

                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_box_outlined),
                              onPressed: () =>
                                  provider.addSetToExercise(exercise.id),
                            ),
                          ],
                        ),
                        Text(
                          '${exercise.muscleGroup} • ${exercise.equipment}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header labels
                        const Row(
                          children: [
                            SizedBox(width: 40, child: Text('Set')),
                            Expanded(
                              child: Text('Weight (kg)', textAlign: TextAlign.center),
                            ),
                            Expanded(
                              child: Text('Reps', textAlign: TextAlign.center),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text('Done', textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                        const Divider(),

                        // Sets row log items
                        ...sets.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final setLog = entry.value;
                          return _SetLogRow(
                            key: ValueKey(setLog.id.isEmpty
                                ? '${exercise.id}_$idx'
                                : setLog.id),
                            setLog: setLog,
                            onChanged: (reps, weight) {
                              provider.updateSetValues(
                                exercise.id,
                                idx,
                                reps: reps,
                                weight: weight,
                              );
                            },
                            onToggleComplete: () {
                              provider.toggleSetComplete(exercise.id, idx);
                            },
                            onDelete: () {
                              provider.removeSetFromExercise(exercise.id, idx);
                            },
                          );
                        }),
                      ],
                    ),
                  );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  void _confirmCancelSession(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Workout?'),
          content: const Text(
            'Are you sure you want to cancel the current session? All current logged sets will be discarded.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Workout'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                provider.cancelWorkoutSession();
                Navigator.pop(context);
              },
              child: const Text('Cancel Workout'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExerciseSheet(BuildContext context, WorkoutProvider provider) {
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
            title: const Text('Add Exercise to Session'),
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
                    trailing: const Icon(Icons.add),
                    onTap: () {
                      provider.addExerciseToSession(ex);
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
}

class _SetLogRow extends StatefulWidget {
  final LoggedSet setLog;
  final Function(int reps, double weight) onChanged;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const _SetLogRow({
    super.key,
    required this.setLog,
    required this.onChanged,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  State<_SetLogRow> createState() => _SetLogRowState();
}

class _SetLogRowState extends State<_SetLogRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setLog.weight.toString(),
    );
    _repsController = TextEditingController(
      text: widget.setLog.reps.toString(),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = widget.setLog.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        color: isDone
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
            : Colors.transparent,
        child: Row(
          children: [
            // Delete / Number
            SizedBox(
              width: 40,
              child: isDone
                  ? Text(
                      '${widget.setLog.setNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )
                  : GestureDetector(
                      onLongPress: widget.onDelete,
                      child: Tooltip(
                        message: 'Long press to delete set',
                        child: Text(
                          '${widget.setLog.setNumber}',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),

            // Weight Input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isDone,
                  textAlign: TextAlign.center,
                  onChanged: (val) {
                    final weight = double.tryParse(val) ?? 0.0;
                    widget.onChanged(widget.setLog.reps, weight);
                  },
                ),
              ),
            ),

            // Reps Input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isDone,
                  textAlign: TextAlign.center,
                  onChanged: (val) {
                    final reps = int.tryParse(val) ?? 0;
                    widget.onChanged(reps, widget.setLog.weight);
                  },
                ),
              ),
            ),

            // Check button
            SizedBox(
              width: 60,
              child: IconButton(
                icon: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isDone ? theme.colorScheme.primary : theme.disabledColor,
                ),
                onPressed: widget.onToggleComplete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
