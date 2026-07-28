import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../data/services/pose_detector_service.dart';
import '../../data/services/form_analyzer.dart';
import '../../data/services/exercise_classifier.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/theme/app_theme.dart';

class PoseFeedbackScreen extends StatefulWidget {
  /// Optional: if provided, form-check mode targets this specific exercise.
  final String? targetExercise; // 'squat', 'push_up', 'jumping_jack', 'plank', or 'custom'
  final Map<String, dynamic>? customPattern; // for custom exercise reference

  const PoseFeedbackScreen({
    super.key,
    this.targetExercise,
    this.customPattern,
  });

  @override
  State<PoseFeedbackScreen> createState() => _PoseFeedbackScreenState();
}

class _PoseFeedbackScreenState extends State<PoseFeedbackScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  
  bool _isCameraInitialized = false;
  bool _isSimulationMode = kIsWeb;
  bool _isCalibrating = true;
  bool _isProcessing = false;
  
  // Last detected pose landmarks (for skeleton painter)
  Pose? _lastPose;
  Size _cameraPreviewSize = Size.zero;

  // Rep counting state
  int _repCount = 0;
  String _currentPhase = 'up';
  double _maxFlexion = 180.0; // track extreme reached this rep
  String _feedbackMessage = 'Get into position...';
  bool _isGoodForm = true;
  double _repProgress = 0.0;

  // Classifier state
  String? _classifiedExercise;
  String? _mismatchNotice;

  // Simulation demo angles
  double _kneeAngle = 180.0;
  double _spineAngle = 0.0;
  double _elbowAngle = 180.0;

  // Throttle
  DateTime _lastProcessedAt = DateTime.now();
  static const _throttleMs = 150;

  // Animation for calibration pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _poseDetectorService.initialize();
    if (!_isSimulationMode) {
      _initializeCamera();
    }

    // Auto dismiss calibration state after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isCalibrating = false);
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _isSimulationMode = true);
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
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _cameraPreviewSize = Size(
          _cameraController!.value.previewSize?.height ?? 480,
          _cameraController!.value.previewSize?.width ?? 640,
        );
      });

      _cameraController!.startImageStream(_processCameraImage);
    } catch (_) {
      if (mounted) setState(() => _isSimulationMode = true);
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessedAt).inMilliseconds < _throttleMs) return;
    _lastProcessedAt = now;
    _isProcessing = true;

    try {
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final poses = await _poseDetectorService.processImage(inputImage);
      if (poses.isNotEmpty && mounted) {
        _updatePoseState(poses.first);
      }
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  void _updatePoseState(Pose pose) {
    final classifiedEx = ExerciseClassifier.classify(pose);
    final targetEx = widget.targetExercise ?? classifiedEx;

    // Check for mismatch notice
    String? mismatch;
    if (widget.targetExercise != null &&
        classifiedEx != null &&
        classifiedEx != widget.targetExercise) {
      mismatch = 'This looks more like a ${_exerciseName(classifiedEx)} than a ${_exerciseName(widget.targetExercise!)} — switch?';
    }

    FormFeedback? feedback;
    if (targetEx == 'squat') {
      feedback = FormAnalyzer.analyzeSquat(
        pose: pose,
        currentPhase: _currentPhase,
        maxKneeFlexion: _maxFlexion,
        onPhaseChanged: (p) {
          _currentPhase = p;
          if (p == 'down') _maxFlexion = 180.0;
        },
        onRepCompleted: () => setState(() => _repCount++),
      );
    } else if (targetEx == 'push_up') {
      feedback = FormAnalyzer.analyzePushUp(
        pose: pose,
        currentPhase: _currentPhase,
        maxElbowFlexion: _maxFlexion,
        onPhaseChanged: (p) {
          _currentPhase = p;
          if (p == 'down') _maxFlexion = 180.0;
        },
        onRepCompleted: () => setState(() => _repCount++),
      );
    } else if (targetEx == 'jumping_jack') {
      feedback = FormAnalyzer.analyzeJumpingJack(
        pose: pose,
        currentPhase: _currentPhase,
        onPhaseChanged: (p) => _currentPhase = p,
        onRepCompleted: () => setState(() => _repCount++),
      );
    } else if (targetEx == 'plank') {
      feedback = FormAnalyzer.analyzePlank(pose: pose);
    } else if (widget.customPattern != null) {
      feedback = FormAnalyzer.analyzeCustom(
        pose: pose,
        pattern: widget.customPattern!,
        currentPhase: _currentPhase,
        currentExtremeAngle: _maxFlexion,
        onPhaseChanged: (p) {
          _currentPhase = p;
          if (p == 'down') _maxFlexion = 180.0;
        },
        onRepCompleted: () => setState(() => _repCount++),
      );
    }

    if (mounted) {
      setState(() {
        _lastPose = pose;
        _classifiedExercise = classifiedEx;
        _mismatchNotice = mismatch;
        if (feedback != null) {
          _feedbackMessage = feedback.message;
          _isGoodForm = feedback.isGoodForm;
          _repProgress = feedback.progress;
          // Track max flexion during rep
          if (_currentPhase == 'down' && feedback.progress < _maxFlexion) {
            _maxFlexion = feedback.progress;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetectorService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetLabel = widget.targetExercise != null
        ? _exerciseName(widget.targetExercise!)
        : 'Auto-Detect';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Live AI Detector — $targetLabel',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              const Text('Simulate', style: TextStyle(fontSize: 12, color: Colors.white54)),
              Switch(
                value: _isSimulationMode,
                activeThumbColor: AppColors.accentEmeraldLight,
                onChanged: (val) {
                  setState(() {
                    _isSimulationMode = val;
                    if (!val && !_isCameraInitialized) _initializeCamera();
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Camera / Skeleton Viewport
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background — camera or simulation
                  _isSimulationMode
                      ? _buildSimulationGraphic(theme)
                      : _isCameraInitialized && _cameraController != null
                          ? CameraPreview(_cameraController!)
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentEmeraldLight,
                              ),
                            ),

                  // Live skeleton overlay on real camera
                  if (!_isSimulationMode && _lastPose != null && _cameraPreviewSize != Size.zero)
                    CustomPaint(
                      painter: _SkeletonOverlayPainter(
                        pose: _lastPose!,
                        imageSize: _cameraPreviewSize,
                        isGoodForm: _isGoodForm,
                      ),
                    ),

                  // Calibrating overlay
                  if (_isCalibrating)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: FadeTransition(
                          opacity: _pulseAnimation,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppColors.accentEmeraldLight),
                              SizedBox(height: 12),
                              Text(
                                'Calibrating AI...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (!_isCalibrating)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        children: [
                          // Rep counter glass badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoBadge('REPS', '$_repCount', AppColors.accentEmeraldLight),
                              if (_classifiedExercise != null)
                                _buildInfoBadge('DETECTED', _exerciseName(_classifiedExercise!), Colors.amber),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Form feedback card
                          _buildFeedbackCard(
                            _feedbackMessage,
                            _isGoodForm ? AppColors.accentEmeraldLight : Colors.orange,
                          ),

                          // Rep progress bar
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _repProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isGoodForm ? AppColors.accentEmeraldLight : Colors.orange,
                              ),
                            ),
                          ),

                          // Mismatch notice
                          if (_mismatchNotice != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.amber, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _mismatchNotice!,
                                        style: const TextStyle(color: Colors.amber, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Control Panel
            Expanded(
              flex: 2,
              child: Container(
                color: const Color(0xFF12132A),
                padding: const EdgeInsets.all(20),
                child: _isSimulationMode
                    ? _buildSimulationControls(theme)
                    : _buildLivePanel(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(String feedback, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            _isGoodForm ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feedback,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePanel(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.center_focus_strong_rounded, size: 40, color: AppColors.accentEmeraldLight),
        const SizedBox(height: 12),
        const Text(
          'Live Detection Active',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.targetExercise != null
              ? 'Form-check mode: ${_exerciseName(widget.targetExercise!)}. Position yourself fully in frame and begin.'
              : 'Auto-detecting exercise from movement. Stand clearly in frame and perform any supported exercise.',
          style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt_rounded, color: AppColors.accentEmeraldLight),
          label: const Text('Reset Rep Count', style: TextStyle(color: AppColors.accentEmeraldLight)),
          onPressed: () => setState(() {
            _repCount = 0;
            _currentPhase = 'up';
            _maxFlexion = 180.0;
          }),
        ),
      ],
    );
  }

  Widget _buildSimulationControls(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Simulation Controller',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 16),
        _buildSlider('Knee Angle', _kneeAngle, 70, 180, (val) {
          setState(() => _kneeAngle = val);
          _simulateSquatUpdate(val);
        }),
        _buildSlider('Spine Angle', _spineAngle, 0, 45, (val) {
          setState(() => _spineAngle = val);
        }),
        _buildSlider('Elbow Angle', _elbowAngle, 60, 180, (val) {
          setState(() => _elbowAngle = val);
        }),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: Slider(
            min: min, max: max, value: value,
            activeColor: AppColors.accentEmeraldLight,
            onChanged: onChanged,
          ),
        ),
        Text('${value.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  void _simulateSquatUpdate(double kneeAngle) {
    // Mimic squat rep logic for demo
    if (kneeAngle < 100 && _currentPhase == 'up') {
      setState(() {
        _currentPhase = 'down';
        _feedbackMessage = 'Great depth!';
        _isGoodForm = true;
        _repProgress = 0.9;
      });
    } else if (kneeAngle > 160 && _currentPhase == 'down') {
      setState(() {
        _currentPhase = 'up';
        _repCount++;
        _feedbackMessage = 'Rep $_repCount complete!';
        _isGoodForm = true;
        _repProgress = 0.0;
      });
    } else {
      setState(() {
        _repProgress = ((170 - kneeAngle) / 100).clamp(0.0, 1.0);
        _feedbackMessage = kneeAngle < 130 ? 'Good squat!' : 'Lower your hips';
        _isGoodForm = _spineAngle < 30;
      });
    }
  }

  Widget _buildSimulationGraphic(ThemeData theme) {
    return CustomPaint(
      painter: _StickmanPainter(
        theme: theme,
        kneeAngle: _kneeAngle,
        spineAngle: _spineAngle,
        isGoodForm: _isGoodForm,
      ),
    );
  }

  String _exerciseName(String key) {
    return {
      'squat': 'Squat',
      'push_up': 'Push-Up',
      'jumping_jack': 'Jumping Jack',
      'plank': 'Plank',
      'custom': 'Custom Exercise',
    }[key] ?? key;
  }
}

/// Paints the live skeleton overlay on the camera preview for real-device mode.
class _SkeletonOverlayPainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final bool isGoodForm;

  _SkeletonOverlayPainter({
    required this.pose,
    required this.imageSize,
    required this.isGoodForm,
  });

  static const _connections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Color boneColor = isGoodForm ? AppColors.accentEmeraldLight : Colors.orange;
    final Color jointColor = isGoodForm ? const Color(0xFFBBF7E0) : Colors.amber;

    final bonePaint = Paint()
      ..color = boneColor.withValues(alpha: 0.85)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = jointColor
      ..strokeWidth = 6.0
      ..style = PaintingStyle.fill;

    Offset toScreen(PoseLandmark lm) {
      // Mirror x for front camera
      final double x = (1.0 - lm.x / imageSize.width) * size.width;
      final double y = (lm.y / imageSize.height) * size.height;
      return Offset(x, y);
    }

    // Draw connecting lines
    for (final pair in _connections) {
      final a = pose.landmarks[pair[0]];
      final b = pose.landmarks[pair[1]];
      if (a != null && b != null && a.likelihood > 0.5 && b.likelihood > 0.5) {
        canvas.drawLine(toScreen(a), toScreen(b), bonePaint);
      }
    }

    // Draw joints
    for (final entry in pose.landmarks.entries) {
      final lm = entry.value;
      if (lm.likelihood > 0.5) {
        canvas.drawCircle(toScreen(lm), 5, jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonOverlayPainter oldDelegate) => true;
}

/// Stick-figure simulation painter for demo/web mode.
class _StickmanPainter extends CustomPainter {
  final ThemeData theme;
  final double kneeAngle;
  final double spineAngle;
  final bool isGoodForm;

  _StickmanPainter({
    required this.theme,
    required this.kneeAngle,
    required this.spineAngle,
    required this.isGoodForm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 30);

    final Color boneColor = isGoodForm ? AppColors.accentEmeraldLight : Colors.orange;

    final paintJoint = Paint()
      ..color = AppColors.accentEmeraldLight
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final paintBone = Paint()
      ..color = boneColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final hip = center;
    final radKnee = (kneeAngle * pi) / 180.0;
    const thighLength = 60.0;
    final knee = Offset(hip.dx - thighLength * 0.7, hip.dy + thighLength * 0.5);

    const shinLength = 60.0;
    final foot = Offset(
      knee.dx + shinLength * (1 - radKnee / pi),
      knee.dy + shinLength,
    );

    final radSpine = (spineAngle * pi) / 180.0;
    final shoulder = Offset(
      hip.dx + 80.0 * (radSpine / pi),
      hip.dy - 80.0 * (1 - radSpine / pi),
    );
    final head = Offset(
      shoulder.dx + 20.0 * (radSpine / pi),
      shoulder.dy - 22.0,
    );

    canvas.drawLine(foot, knee, paintBone);
    canvas.drawLine(knee, hip, paintBone);
    canvas.drawLine(hip, shoulder, paintBone);
    canvas.drawCircle(head, 16, paintBone);
    canvas.drawCircle(foot, 5, paintJoint);
    canvas.drawCircle(knee, 5, paintJoint);
    canvas.drawCircle(hip, 5, paintJoint);
    canvas.drawCircle(shoulder, 5, paintJoint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
