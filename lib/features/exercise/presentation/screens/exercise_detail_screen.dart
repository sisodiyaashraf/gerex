import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/exercise.dart';
import '../widgets/exercise_image_widget.dart';
import '../../../../features/workout/presentation/providers/workout_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
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
  VideoPlayerController? _videoController;
  bool _isDescriptionExpanded = false;
  int _selectedReps = 10;
  bool _isVideoInitialized = false;

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
  void initState() {
    super.initState();
    // Initialize video player with a sample fitness instructional clip
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://assets.mixkit.co/videos/preview/mixkit-fitness-woman-doing-lunges-with-dumbbells-41484-large.mp4'),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.setLooping(true);
        }
      }).catchError((e) {
        debugPrint('Video Player error: $e');
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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
    final description = 'The ${widget.exercise.name} targetting ${widget.exercise.muscleGroup} is an excellent exercise for building muscular strength and cardiovascular stamina. It requires using ${widget.exercise.equipment} with strict biomechanical control to avoid spinal pressure and focus load on key muscle pathways.';

    return Scaffold(
      body: LiquidBackground(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Video header
                SliverAppBar(
                  expandedHeight: 240.0,
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
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_isVideoInitialized && _videoController != null)
                          GestureDetector(
                            onTap: () {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                              setState(() {});
                            },
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                          )
                        else
                          Container(
                            color: Colors.black.withValues(alpha: 0.4),
                            child: Center(
                              child: ExerciseImageWidget(
                                imagePath: widget.exercise.effectiveImagePath,
                                removeBackground: widget.exercise.removeBackground,
                                size: 160.0,
                              ),
                            ),
                          ),
                        // Play/Pause Overlay Indication
                        if (_videoController != null)
                          Center(
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              difficulty,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Burn: ${totalBurn.toStringAsFixed(1)} kcal',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                maxLines: _isDescriptionExpanded ? null : 3,
                                overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isDescriptionExpanded ? 'Read Less' : 'Read More',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Numbered Steps Instructions List
                      const Text('How To Do It', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      if (widget.exercise.instructions.isEmpty)
                        const GlassContainer(
                          padding: EdgeInsets.all(16),
                          child: Text('No instruction steps registered for this exercise.'),
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
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: theme.colorScheme.primary,
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GlassContainer(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        step,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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

                      // Custom Repetitions Picker
                      const Text('Custom Repetitions Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 110,
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
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 100), // Sticky CTA spacing
                    ]),
                  ),
                ),
              ],
            ),

            // Sticky Bottom CTA Panel
            Positioned(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live AI Detector optional toggle
                  if (!widget.isPicker)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accentEmeraldLight),
                        foregroundColor: AppColors.accentEmeraldLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                      ),
                      icon: const Icon(Icons.videocam_rounded, size: 18),
                      label: const Text(
                        'Live AI Detector',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        // Map exercise name/category to classifier key
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
                      gradient: GerexGradients.primaryCTA,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
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
                          // Save to active live workout session
                          if (workoutProvider.isSessionActive) {
                            workoutProvider.addExerciseToSession(widget.exercise);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added ${widget.exercise.name} with $_selectedReps reps to active workout session!')),
                            );
                            context.pop();
                          } else {
                            // Quick-log workout
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
}
