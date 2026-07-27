import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/exercise_provider.dart';
import '../../domain/entities/exercise.dart';
import '../widgets/exercise_image_widget.dart';
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

  final List<String> _assetImages = const [
    'assets/exercise/bmi check.png',
    'assets/exercise/burpee.png',
    'assets/exercise/cycling.png',
    'assets/exercise/fitness dashboard.png',
    'assets/exercise/jumping jack.png',
    'assets/exercise/kettlebell swing.png',
    'assets/exercise/kickboxing.png',
    'assets/exercise/lunges.png',
    'assets/exercise/meditation.png',
    'assets/exercise/mountain climber.png',
    'assets/exercise/personal trainer.png',
    'assets/exercise/pushap.png',
    'assets/exercise/rest day.png',
    'assets/exercise/rowing machine.png',
    'assets/exercise/yoga pose.png',
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
                              leading: ExerciseImageWidget(
                                imagePath: exercise.effectiveImagePath,
                                removeBackground: exercise.removeBackground,
                                size: 40.0,
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
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () {
                                          context.push(
                                            '/exercise-detail',
                                            extra: {
                                              'exercise': exercise,
                                              'isPicker': false,
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.info_outline_rounded, size: 14),
                                        label: const Text('View Full Guide & Log Reps', style: TextStyle(fontSize: 12)),
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
        String? selectedImagePath;
        bool removeBg = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
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

                        // Image Preview
                        Center(
                          child: ExerciseImageWidget(
                            imagePath: selectedImagePath,
                            removeBackground: removeBg,
                            size: 80.0,
                          ),
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

                        // Template image dropdown selector
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Choose Graphic Template',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          initialValue: selectedImagePath != null && selectedImagePath!.startsWith('assets/')
                              ? selectedImagePath
                              : null,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No Image (Dumbbell Placeholder)'),
                            ),
                            ..._assetImages.map((path) {
                              final name = path.split('/').last.replaceAll('.png', '');
                              final title = name[0].toUpperCase() + name.substring(1);
                              return DropdownMenuItem<String>(
                                value: path,
                                child: Text(title),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setModalState(() {
                              selectedImagePath = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Custom Image Pick Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                          label: const Text('Or Upload Custom Photo...'),
                          onPressed: () async {
                            final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setModalState(() {
                                selectedImagePath = image.path;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Background Removal Switch
                        SwitchListTile(
                          title: const Text(
                            'Remove Background (Transparency)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Keys out white background pixels client-side',
                            style: TextStyle(fontSize: 11),
                          ),
                          value: removeBg,
                          onChanged: (val) {
                            setModalState(() {
                              removeBg = val;
                            });
                          },
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
                                    imagePath: selectedImagePath,
                                    removeBackground: removeBg,
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
      },
    );
  }
}
