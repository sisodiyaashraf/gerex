import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/validation/validators.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

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
    final provider = Provider.of<ExerciseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context),
        child: const Icon(Icons.add),
      ),
      body: LiquidBackground(
        child: Column(
          children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => provider.updateSearchQuery(val),
            ),
          ),

          // Muscle Group Category Selector
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscleGroups.length,
              itemBuilder: (context, index) {
                final group = _muscleGroups[index];
                final isSelected = provider.selectedMuscleGroup == group;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (_) => provider.updateMuscleGroup(group),
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // List results
          Expanded(
            child: provider.isLoading && provider.exercises.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.exercises.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises found.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: provider.exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = provider.exercises[index];
                           return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.fitness_center,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                exercise.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${exercise.muscleGroup} • ${exercise.equipment}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Instructions:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (exercise.instructions.isEmpty)
                                        const Text('No instructions available.')
                                      else
                                        ...exercise.instructions
                                            .asMap()
                                            .entries
                                            .map(
                                              (entry) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6.0,
                                                ),
                                                child: Text(
                                                  '${entry.key + 1}. ${entry.value}',
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
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

  void _showAddExerciseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String muscle = 'Chest';
    String equipment = 'Barbell';
    final instructionsController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: GlassContainer(
            borderRadius: 24,
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
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
                      'Add Custom Exercise',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: Validators.validateExerciseName,
                      onSaved: (val) => name = val ?? '',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: muscle,
                      decoration: InputDecoration(
                        labelText: 'Muscle Group',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: Validators.validateMuscleGroup,
                      items: _muscleGroups
                          .where((g) => g != 'All')
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) => muscle = val ?? 'Chest',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Equipment (e.g. Dumbbell)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: Validators.validateEquipment,
                      onSaved: (val) => equipment = val ?? '',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: instructionsController,
                      decoration: InputDecoration(
                        labelText: 'Instructions (comma separated)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          formKey.currentState?.save();
                          final steps = instructionsController.text
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();

                          final success = await context
                              .read<ExerciseProvider>()
                              .addCustomExercise(
                                name: name,
                                muscleGroup: muscle,
                                equipment: equipment,
                                instructions: steps,
                              );

                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exercise created!')),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
