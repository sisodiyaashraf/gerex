import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/exercise_provider.dart';
import '../../../../models/exercise.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/gerex_scaffold.dart';
import 'package:gerex/core/theme/app_theme.dart';
import '../widgets/exercise_image_widget.dart';

class AddExerciseScreen extends StatefulWidget {
  final List<String> initiallySelectedIds;

  const AddExerciseScreen({
    super.key,
    this.initiallySelectedIds = const [],
  });

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<Exercise> _selectedExercises = [];

  final List<String> _categories = [
    'All',
    'Strength',
    'Cardio',
    'Stretching',
    'Powerlifting',
    'Olympic Weightlifting',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExerciseProvider>();
      provider.fetchExercises();
      
      // Load initially selected exercises once exercises are loaded
      if (widget.initiallySelectedIds.isNotEmpty) {
        setState(() {
          for (var id in widget.initiallySelectedIds) {
            final match = provider.exercises.firstWhere(
              (e) => e.id == id,
              orElse: () => Exercise(
                id: id,
                name: id.replaceAll('_', ' '),
                primaryMuscles: const [],
                secondaryMuscles: const [],
                category: 'Strength',
                level: 'Beginner',
                instructions: const [],
                images: const [],
              ),
            );
            _selectedExercises.add(match);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exProvider = Provider.of<ExerciseProvider>(context);

    // Filter exercises locally
    final filteredExercises = exProvider.exercises.where((ex) {
      final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.muscleGroup.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          ex.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    return GerexScaffold(
      appBar: AppBar(
        title: Text(
          'Add Exercises',
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
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circlePlus, size: 20, color: AppColors.accentEmeraldLight),
            tooltip: 'Create Custom Exercise',
            onPressed: () async {
              final newEx = await context.push<dynamic>('/create-exercise');
              if (newEx != null && newEx is Exercise) {
                exProvider.addExerciseEntity(newEx);
                setState(() {
                  _selectedExercises.add(newEx);
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  borderRadius: 16,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppColors.textDarkHeading),
                    decoration: InputDecoration(
                      hintText: 'Search exercises or muscle groups...',
                      hintStyle: TextStyle(color: AppColors.textDarkMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.accentEmeraldLight),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),

              // Category Chip selector
              SizedBox(
                height: 48,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: isSelected
                                ? GerexGradients.primaryCTA
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentEmeraldLight
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDarkMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Exercises List
              Expanded(
                child: exProvider.isLoading && exProvider.exercises.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredExercises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fitness_center_rounded, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'No exercises match filters.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final ex = filteredExercises[index];
                              final isSelected = _selectedExercises.any((e) => e.id == ex.id);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: InkWell(
                                  onTap: () => _toggleSelection(ex),
                                  borderRadius: BorderRadius.circular(16),
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(12),
                                    borderRadius: 16,
                                    color: isSelected
                                        ? AppColors.accentEmeraldLight.withValues(alpha: 0.08)
                                        : null,
                                    borderWidth: isSelected ? 1.5 : 1.0,
                                    borderGradient: isSelected
                                        ? GerexGradients.accentBorder
                                        : null,
                                    child: Row(
                                      children: [
                                        // Image thumbnail
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 56,
                                            height: 56,
                                            child: ExerciseImageWidget(imagePath: ex.imageUrl),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Meta details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ex.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textDarkHeading,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.05),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      ex.muscleGroup,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors.textDarkMuted,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    ex.difficulty,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: ex.difficulty.toLowerCase() == 'beginner'
                                                          ? Colors.greenAccent
                                                          : ex.difficulty.toLowerCase() == 'intermediate'
                                                              ? Colors.orangeAccent
                                                              : Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Selection indicator with micro scale animation
                                        AnimatedScale(
                                          scale: isSelected ? 1.1 : 1.0,
                                          duration: const Duration(milliseconds: 150),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons.radio_button_unchecked_rounded,
                                            color: isSelected
                                                ? AppColors.accentEmeraldLight
                                                : Colors.white.withValues(alpha: 0.2),
                                            size: 24,
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
            ],
          ),

          // Sticky Confirm button at bottom
          if (_selectedExercises.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, _selectedExercises),
                  child: Text(
                    'Add ${_selectedExercises.length} ${_selectedExercises.length == 1 ? "Exercise" : "Exercises"}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleSelection(Exercise ex) {
    setState(() {
      final index = _selectedExercises.indexWhere((e) => e.id == ex.id);
      if (index != -1) {
        _selectedExercises.removeAt(index);
      } else {
        _selectedExercises.add(ex);
      }
    });
  }
}