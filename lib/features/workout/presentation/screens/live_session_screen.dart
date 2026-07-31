import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../exercise/presentation/providers/exercise_provider.dart';
import '../../domain/entities/workout_entities.dart';
import '../providers/workout_provider.dart';
import '../../../ai/data/services/pose_detector_service.dart';
import '../../../ai/data/services/form_analyzer.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/widgets/slide_to_confirm_button.dart';
import 'package:gerex/core/theme/app_theme.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  // Camera & AI State
  CameraController? _cameraController;
  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  Timer? _simulationTimer;

  // Motion Sensors State
  bool _motionTrackingActive = false;
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  int _sensorRepCount = 0;
  String? _selectedMotionExerciseId;
  double _filteredMag = 0.0;
  bool _isMotionPeak = false;
  DateTime? _lastRepTime;

  // Selected analyzer target
  String _selectedExerciseTarget = 'Squat'; // 'Squat', 'Push-Up', 'Jumping Jack', 'Plank'
  
  // Real-time stats
  int _aiRepCount = 0;
  String _aiPhase = 'up';
  double _aiMaxFlexion = 180.0;
  String _aiFeedbackMessage = 'Position body in frame';
  bool _aiIsGoodForm = true;
  double _aiProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _poseDetectorService.initialize();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkoutProvider>();
      if (provider.aiTrackingEnabled) {
        // Try matching first exercise in workout template to preset targets
        if (provider.liveExercises.isNotEmpty) {
          final firstEx = provider.liveExercises.first.name.toLowerCase();
          if (firstEx.contains('squat')) {
            _selectedExerciseTarget = 'Squat';
          } else if (firstEx.contains('push')) {
            _selectedExerciseTarget = 'Push-Up';
          } else if (firstEx.contains('jack')) {
            _selectedExerciseTarget = 'Jumping Jack';
          } else if (firstEx.contains('plank')) {
            _selectedExerciseTarget = 'Plank';
          }
        }
        _initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetectorService.dispose();
    _simulationTimer?.cancel();
    _accelSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _aiFeedbackMessage = 'No cameras found. Simulation active.';
        });
        _runSimulation();
        return;
      }
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _aiFeedbackMessage = 'AI Form Tracking Active';
      });
      _startAnalysisStream();
    } catch (e) {
      setState(() {
        _aiFeedbackMessage = 'Camera failed. Simulation active.';
      });
      _runSimulation();
    }
  }

  void _runSimulation() {
    if (_isAnalyzing) return;
    _isAnalyzing = true;
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_isAnalyzing) {
        timer.cancel();
        return;
      }
      setState(() {
        _aiRepCount++;
        _aiFeedbackMessage = 'Simulated Rep Completed!';
        _aiIsGoodForm = true;
        _aiProgress = 1.0;
      });
      _onAiRepCompleted();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _aiProgress = 0.0;
            _aiFeedbackMessage = 'Prepare for next rep';
          });
        }
      });
    });
  }

  void _startAnalysisStream() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    bool isProcessing = false;
    _isAnalyzing = true;

    _cameraController!.startImageStream((CameraImage image) async {
      if (isProcessing || !mounted || !_isAnalyzing) return;
      isProcessing = true;

      try {
        final poses = await _poseDetectorService.processImage(
          InputImage.fromBytes(
            bytes: image.planes[0].bytes,
            metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: InputImageRotation.rotation270deg,
              format: InputImageFormat.nv21,
              bytesPerRow: image.planes[0].bytesPerRow,
            ),
          ),
        );

        if (poses.isNotEmpty && mounted) {
          final pose = poses.first;
          FormFeedback feedback;

          if (_selectedExerciseTarget == 'Squat') {
            feedback = FormAnalyzer.analyzeSquat(
              pose: pose,
              currentPhase: _aiPhase,
              maxKneeFlexion: _aiMaxFlexion,
              onPhaseChanged: (nextPhase) {
                _aiPhase = nextPhase;
                if (nextPhase == 'down') {
                  _aiMaxFlexion = 180.0;
                }
              },
              onRepCompleted: () {
                setState(() {
                  _aiRepCount++;
                });
                _onAiRepCompleted();
              },
            );
            // Track deepest flexion point
            final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
            final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
            final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
            if (leftHip != null && leftKnee != null && leftAnkle != null) {
              final angle = FormAnalyzer.calculateAngle(leftHip, leftKnee, leftAnkle);
              if (angle < _aiMaxFlexion) {
                _aiMaxFlexion = angle;
              }
            }
          } else if (_selectedExerciseTarget == 'Push-Up') {
            feedback = FormAnalyzer.analyzePushUp(
              pose: pose,
              currentPhase: _aiPhase,
              maxElbowFlexion: _aiMaxFlexion,
              onPhaseChanged: (nextPhase) {
                _aiPhase = nextPhase;
                if (nextPhase == 'down') {
                  _aiMaxFlexion = 180.0;
                }
              },
              onRepCompleted: () {
                setState(() {
                  _aiRepCount++;
                });
                _onAiRepCompleted();
              },
            );
            final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
            final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
            final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
            if (leftShoulder != null && leftElbow != null && leftWrist != null) {
              final angle = FormAnalyzer.calculateAngle(leftShoulder, leftElbow, leftWrist);
              if (angle < _aiMaxFlexion) {
                _aiMaxFlexion = angle;
              }
            }
          } else if (_selectedExerciseTarget == 'Jumping Jack') {
            feedback = FormAnalyzer.analyzeJumpingJack(
              pose: pose,
              currentPhase: _aiPhase,
              onPhaseChanged: (nextPhase) => _aiPhase = nextPhase,
              onRepCompleted: () {
                setState(() {
                  _aiRepCount++;
                });
                _onAiRepCompleted();
              },
            );
          } else {
            // Plank
            feedback = FormAnalyzer.analyzePlank(pose: pose);
          }

          setState(() {
            _aiFeedbackMessage = feedback.message;
            _aiIsGoodForm = feedback.isGoodForm;
            _aiProgress = feedback.progress;
          });
        }
      } catch (_) {} finally {
        isProcessing = false;
      }
    });
  }

  void _onAiRepCompleted() {
    final provider = context.read<WorkoutProvider>();
    if (provider.liveExercises.isEmpty) return;

    // Find the first exercise matching our target name (or default to current first)
    final activeEx = provider.liveExercises.firstWhere(
      (e) => e.name.toLowerCase().contains(_selectedExerciseTarget.toLowerCase().split(' ').first),
      orElse: () => provider.liveExercises.first,
    );

    final sets = provider.liveSets[activeEx.id] ?? [];
    final incompleteIdx = sets.indexWhere((s) => !s.isCompleted);
    if (incompleteIdx != -1) {
      final currentSet = sets[incompleteIdx];
      final targetReps = currentSet.reps;
      provider.updateSetValues(activeEx.id, incompleteIdx, reps: currentSet.reps + 1);
      
      // Auto-complete set if reps completed matches target reps
      if (currentSet.reps + 1 >= targetReps) {
        provider.toggleSetComplete(activeEx.id, incompleteIdx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Tracker: Set ${incompleteIdx + 1} for ${activeEx.name} Completed!'),
            backgroundColor: AppColors.accentEmeraldLight,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleMotionTracking(WorkoutProvider provider) {
    if (_motionTrackingActive) {
      _stopMotionTracking();
    } else {
      _startMotionTracking(provider);
    }
  }

  void _startMotionTracking(WorkoutProvider provider) {
    if (provider.liveExercises.isEmpty) return;
    
    setState(() {
      _motionTrackingActive = true;
      if (_selectedMotionExerciseId == null || 
          !provider.liveExercises.any((e) => e.id == _selectedMotionExerciseId)) {
        _selectedMotionExerciseId = provider.liveExercises.first.id;
      }
      _sensorRepCount = 0;
      _filteredMag = 0.0;
      _isMotionPeak = false;
      _lastRepTime = null;
    });

    _accelSubscription?.cancel();
    _accelSubscription = userAccelerometerEventStream().listen((event) {
      if (!mounted || !_motionTrackingActive) return;

      final double rawMag = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Low pass filter
      const double alpha = 0.15;
      _filteredMag = alpha * rawMag + (1 - alpha) * _filteredMag;

      final now = DateTime.now();
      // Thresholds: departure > 2.0 (moving), return < 0.6 (rest)
      if (!_isMotionPeak && _filteredMag > 2.0) {
        _isMotionPeak = true;
      } else if (_isMotionPeak && _filteredMag < 0.6) {
        _isMotionPeak = false;
        
        if (_lastRepTime == null || now.difference(_lastRepTime!).inMilliseconds > 900) {
          _lastRepTime = now;
          setState(() {
            _sensorRepCount++;
          });
          _incrementRepForSelectedExercise(provider);
        }
      }
    });
  }

  void _stopMotionTracking() {
    _accelSubscription?.cancel();
    setState(() {
      _motionTrackingActive = false;
    });
  }

  void _incrementRepForSelectedExercise(WorkoutProvider provider) {
    if (_selectedMotionExerciseId == null) return;
    final sets = provider.liveSets[_selectedMotionExerciseId!] ?? [];
    final incompleteIdx = sets.indexWhere((s) => !s.isCompleted);
    if (incompleteIdx != -1) {
      final currentSet = sets[incompleteIdx];
      provider.updateSetValues(_selectedMotionExerciseId!, incompleteIdx, reps: currentSet.reps + 1);
    }
  }

  void _manuallyAdjustRep(WorkoutProvider provider, int delta) {
    if (_selectedMotionExerciseId == null) return;
    setState(() {
      _sensorRepCount = (_sensorRepCount + delta).clamp(0, 999);
    });
    
    final sets = provider.liveSets[_selectedMotionExerciseId!] ?? [];
    final incompleteIdx = sets.indexWhere((s) => !s.isCompleted);
    if (incompleteIdx != -1) {
      final currentSet = sets[incompleteIdx];
      final newReps = (currentSet.reps + delta).clamp(0, 999);
      provider.updateSetValues(_selectedMotionExerciseId!, incompleteIdx, reps: newReps);
    }
  }

  Widget _buildSensorTrackerPanel(BuildContext context, ThemeData theme, WorkoutProvider provider) {
    if (provider.liveExercises.isEmpty) return const SizedBox.shrink();

    final activeExId = _selectedMotionExerciseId ?? provider.liveExercises.first.id;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.mobileScreenButton,
                    color: _motionTrackingActive ? theme.colorScheme.primary : theme.disabledColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Motion Rep Counter',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _motionTrackingActive,
                onChanged: (val) {
                  _toggleMotionTracking(provider);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your phone in your hand or pocket while exercising to automatically count reps using built-in motion sensors.',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_motionTrackingActive) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: activeExId,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Target',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                    items: provider.liveExercises.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(e.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMotionExerciseId = val;
                        _sensorRepCount = 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove_rounded),
                  onPressed: () => _manuallyAdjustRep(provider, -1),
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Text(
                      '$_sensorRepCount',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Text(
                      'REPS DETECTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _manuallyAdjustRep(provider, 1),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiTrackerPanel(BuildContext context, ThemeData theme) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: 20,
      borderGradient: LinearGradient(
        colors: [
          AppColors.accentEmeraldLight.withValues(alpha: 0.25),
          AppColors.accentEmeraldLight.withValues(alpha: 0.05),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.robot, color: AppColors.accentEmeraldLight, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'AI Tracker: $_selectedExerciseTarget',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDarkHeading),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: _selectedExerciseTarget,
                dropdownColor: AppColors.cardDarkGlass,
                style: const TextStyle(color: AppColors.accentEmeraldLight, fontSize: 12, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                items: ['Squat', 'Push-Up', 'Jumping Jack', 'Plank'].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedExerciseTarget = val;
                      _aiRepCount = 0;
                      _aiPhase = 'up';
                      _aiMaxFlexion = 180.0;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 150,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _isCameraInitialized && _cameraController != null
                        ? AspectRatio(
                            aspectRatio: _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          )
                        : Container(
                            color: Colors.black45,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.videocam_off_rounded, color: Colors.grey[600], size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    _cameraController == null
                                        ? 'Initializing camera...'
                                        : 'Using AI Simulation Mode',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _aiProgress,
                      backgroundColor: Colors.transparent,
                      color: AppColors.accentEmeraldLight,
                      minHeight: 4,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _aiIsGoodForm 
                            ? AppColors.accentEmeraldLight.withValues(alpha: 0.8) 
                            : AppColors.destructiveRed.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _aiIsGoodForm ? 'GOOD FORM' : 'CORRECTION',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Reps: $_aiRepCount',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accentEmeraldLight, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _aiFeedbackMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<WorkoutProvider>(context);

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
        child: Stack(
          children: [
            Column(
              children: [
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

            // Live AI Tracker Panel
            if (provider.aiTrackingEnabled)
              _buildAiTrackerPanel(context, theme),

            // Motion Sensor Tracker Panel
            _buildSensorTrackerPanel(context, theme, provider),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.liveExercises.length + 1,
                itemBuilder: (context, index) {
                  if (index == provider.liveExercises.length) {
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
                        SlideToConfirmButton(
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
                                    if (provider.sessions.isNotEmpty) {
                                      _showShareSummaryDialog(context, provider.sessions.first);
                                    } else {
                                      context.pop();
                                    }
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
                              onPressed: () => provider.addSetToExercise(exercise.id),
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
                        ...sets.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final setLog = entry.value;
                          return _SetLogRow(
                            key: ValueKey(setLog.id.isEmpty ? '${exercise.id}_$idx' : setLog.id),
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
        if (provider.lastPrCelebration != null)
          PrCelebrationOverlay(
            event: provider.lastPrCelebration!,
            onDismiss: () {
              provider.clearPrCelebration();
            },
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

  void _showShareSummaryDialog(BuildContext context, WorkoutSession session) {
    final boundaryKey = GlobalKey();

    double totalVolume = 0;
    int totalSets = 0;
    final Set<String> uniqueExerciseIds = {};
    for (final loggedSet in session.loggedSets) {
      if (loggedSet.isCompleted) {
        totalVolume += loggedSet.weight * loggedSet.reps;
        totalSets++;
        uniqueExerciseIds.add(loggedSet.exerciseId);
      }
    }

    final minutes = session.durationSeconds ~/ 60;
    final seconds = session.durationSeconds % 60;
    final durationStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: boundaryKey,
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  borderGradient: LinearGradient(
                    colors: [
                      AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                      AppColors.accentEmeraldLight.withValues(alpha: 0.05),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'GEREX',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accentEmeraldLight,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentEmeraldLight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentEmeraldLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        session.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.completedAt?.day ?? DateTime.now().day} ${_getMonthName(session.completedAt?.month ?? DateTime.now().month)} ${session.completedAt?.year ?? DateTime.now().year}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildShareStat('Duration', durationStr),
                          _buildShareStat('Exercises', '${uniqueExerciseIds.length}'),
                          _buildShareStat('Sets Logged', '$totalSets'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Volume Lifted',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${totalVolume.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentEmeraldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Tracked with Gerex Coach App',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white30,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () async {
                      final RenderRepaintBoundary? boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                      if (boundary == null) return;
                      
                      if (boundary.debugNeedsPaint) {
                        await Future.delayed(const Duration(milliseconds: 100));
                      }
                      
                      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                      final Uint8List? pngBytes = byteData?.buffer.asUint8List();
                      
                      if (pngBytes != null) {
                        final tempDir = await getTemporaryDirectory();
                        final file = await File('${tempDir.path}/gerex_workout_${DateTime.now().millisecondsSinceEpoch}.png').create();
                        await file.writeAsBytes(pngBytes);
                        
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'Finished my workout session "${session.name}" on Gerex! 💪🔥',
                        );
                      }
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Card', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentEmeraldLight,
                      foregroundColor: const Color(0xFF14181F),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
  void didUpdateWidget(covariant _SetLogRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.setLog.weight != oldWidget.setLog.weight) {
      _weightController.text = widget.setLog.weight.toString();
    }
    if (widget.setLog.reps != oldWidget.setLog.reps) {
      _repsController.text = widget.setLog.reps.toString();
    }
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            SizedBox(
              width: 60,
              child: IconButton(
                icon: Icon(
                  isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
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

class PrCelebrationOverlay extends StatefulWidget {
  final PrCelebrationEvent event;
  final VoidCallback onDismiss;

  const PrCelebrationOverlay({
    super.key,
    required this.event,
    required this.onDismiss,
  });

  @override
  State<PrCelebrationOverlay> createState() => _PrCelebrationOverlayState();
}

class _PrCelebrationOverlayState extends State<PrCelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<GlassParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    final random = math.Random();
    final colors = [
      AppColors.accentEmeraldLight,
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFF43F5E),
    ];

    for (int i = 0; i < 35; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double speed = 0.1 + random.nextDouble() * 0.3;
      _particles.add(
        GlassParticle(
          x: 0.5,
          y: 0.45,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 0.2,
          baseSize: 6.0 + random.nextDouble() * 12.0,
          color: colors[random.nextInt(colors.length)],
        ),
      );
    }

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final opacity = progress < 0.1
              ? (progress / 0.1).clamp(0.0, 1.0)
              : (progress > 0.8
                  ? ((1.0 - progress) / 0.2).clamp(0.0, 1.0)
                  : 1.0);

          return Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: GlassConfettiPainter(
                      particles: _particles,
                      progress: progress,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * math.sin(progress * math.pi),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 24,
                        borderGradient: LinearGradient(
                          colors: [
                            AppColors.accentEmeraldLight.withValues(alpha: 0.4),
                            AppColors.accentEmeraldLight.withValues(alpha: 0.05),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🎉 NEW RECORD! 🎉',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accentEmeraldLight,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.event.exerciseName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${widget.event.weight.toStringAsFixed(1)} kg × ${widget.event.reps} reps',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'You just set a new personal record for this exercise. Incredible work!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GlassConfettiPainter extends CustomPainter {
  final List<GlassParticle> particles;
  final double progress;

  GlassConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final double progressScale = progress;
      final double x = p.x + p.vx * progressScale * size.width;
      final double y = p.y + p.vy * progressScale * size.height + (0.5 * 9.8 * progressScale * progressScale * 100);
      final double scale = p.baseSize * (1.0 - progressScale * 0.5);
      
      paint.color = p.color.withValues(alpha: (1.0 - progressScale).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GlassParticle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double baseSize;
  final Color color;

  GlassParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.baseSize,
    required this.color,
  });
}