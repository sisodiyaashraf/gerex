import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../data/services/pose_detector_service.dart';
import '../../data/services/form_analyzer.dart';
import '../../data/services/exercise_classifier.dart';
import '../../data/services/hand_landmark_service.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';
import 'package:gerex/core/presentation/widgets/pastel_gradient_card.dart';
import 'package:gerex/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class PoseOverlayData {
  final Pose pose;
  final List<HandSkeleton> hands;
  final bool isGoodForm;
  final double currentJointAngle;
  final PoseLandmarkType primaryJointType;
  final String currentPhase;
  final String exercise;

  const PoseOverlayData({
    required this.pose,
    required this.hands,
    required this.isGoodForm,
    required this.currentJointAngle,
    required this.primaryJointType,
    required this.currentPhase,
    required this.exercise,
  });
}

class PoseFeedbackScreen extends StatefulWidget {
  /// Optional: if provided, form-check mode targets this specific exercise.
  final String?
  targetExercise; // 'squat', 'push_up', 'bicep_curl', 'shoulder_press', 'jumping_jack', 'plank'
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
  final HandLandmarkService _handLandmarkService = HandLandmarkService();
  final ValueNotifier<PoseOverlayData?> _poseOverlayNotifier = ValueNotifier(null);

  bool _isCameraInitialized = false;
  bool _isSimulationMode = kIsWeb;
  bool _isCalibrating = true;
  bool _isProcessing = false;

  // Freestyle vs Targeted Mode & Exercise Selector
  bool _isFreestyleMode = false;
  String _selectedExerciseKey = 'squat';
  final Map<String, int> _freestyleTally = {
    'Push-up': 0,
    'Squat': 0,
    'Bicep Curl': 0,
    'Shoulder Press': 0,
    'Jumping Jack': 0,
  };

  // Target reps configuration
  final int _targetReps = 10;

  // Gesture State & Pause Cooldown
  bool _isPausedByGesture = false;
  final bool _enableGesturePause =
      false; // Off by default to avoid accidental pause loops during workout
  DateTime? _resumeCooldownUntil;
  String? _gestureNotice;
  DateTime? _noticeDismissAt;

  // UI Layout State
  bool _showBottomPanel = false;

  // Last detected pose & hand landmarks (for skeleton painter)
  Pose? _lastPose;
  Size _cameraPreviewSize = Size.zero;

  // Rep counting & Form State
  int _repCount = 0;
  String _currentPhase = 'up';
  double _maxFlexion = 180.0;
  String _feedbackMessage = 'Get into position...';
  bool _isGoodForm = true;
  double _repProgress = 0.0;

  // Classifier state
  String? _classifiedExercise;
  String? _mismatchNotice;

  // Simulation demo controls
  double _simKneeAngle = 180.0;
  final double _simSpineAngle = 0.0;
  double _simElbowAngle = 180.0;
  bool _simPalmGesture = false;
  bool _simThumbsUpGesture = false;

  // Throttle (30ms = ~33 FPS optimal for live pose + hand tracking without hangs)
  DateTime _lastProcessedAt = DateTime.now();
  static const _throttleMs = 30;

  // Animation for calibration pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isFreestyleMode = widget.targetExercise == null;
    _selectedExerciseKey = widget.targetExercise ?? 'squat';

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
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
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
    // Non-blocking guard: drop incoming frames immediately if detector is busy
    if (_isProcessing) return;

    final now = DateTime.now();
    if (_isPausedByGesture) return;
    if (now.difference(_lastProcessedAt).inMilliseconds < 30) return;
    _lastProcessedAt = now;
    _isProcessing = true;

    try {
      Uint8List bytes;
      if (image.planes.length == 1) {
        bytes = image.planes[0].bytes;
      } else {
        final WriteBuffer allBytes = WriteBuffer();
        for (final plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
      }

      InputImageFormat? format = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
      format ??= (defaultTargetPlatform == TargetPlatform.android
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888);

      final int sensorOrientation =
          _cameraController?.description.sensorOrientation ?? 270;
      final InputImageRotation rotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.isNotEmpty
              ? image.planes[0].bytesPerRow
              : image.width,
        ),
      );

      final poses = await _poseDetectorService.processImage(inputImage);
      if (mounted) {
        if (poses.isNotEmpty) {
          final pose = poses.first;
          final hands = _handLandmarkService.extractHandsFromPose(
            pose,
            _cameraPreviewSize,
          );
          _processHandGestures(hands, pose);
          _updatePoseState(pose, hands);
        } else {
          _poseOverlayNotifier.value = null;
          if (_feedbackMessage != 'No body detected — step into camera frame') {
            setState(() {
              _feedbackMessage = 'No body detected — step into camera frame';
              _isGoodForm = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted && _feedbackMessage != 'Scanning frame...') {
        setState(() {
          _feedbackMessage = 'Scanning frame...';
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _resumeDetection() {
    setState(() {
      _isPausedByGesture = false;
      _resumeCooldownUntil = DateTime.now().add(const Duration(seconds: 4));
      _showGestureNotice('AI Detection Resumed');
    });
  }

  void _processHandGestures(List<HandSkeleton> hands, Pose pose) {
    if (!_enableGesturePause) return;
    if (_resumeCooldownUntil != null &&
        DateTime.now().isBefore(_resumeCooldownUntil!)) {
      return;
    }

    for (final hand in hands) {
      final gesture = _handLandmarkService.detectGesture(hand);
      if (gesture == HandGesture.openPalm) {
        final nose = pose.landmarks[PoseLandmarkType.nose];
        if (hand.wrist != null && nose != null && hand.wrist!.y < nose.y + 30) {
          if (!_isPausedByGesture) {
            setState(() {
              _isPausedByGesture = true;
              _showGestureNotice('✋ Open Palm: Detection Paused');
            });
          }
        }
        break;
      } else if (gesture == HandGesture.thumbsUp) {
        setState(() {
          _showGestureNotice('👍 Thumbs Up: Set Completed!');
        });
        break;
      }
    }
  }

  void _showGestureNotice(String msg) {
    _gestureNotice = msg;
    _noticeDismissAt = DateTime.now().add(const Duration(seconds: 3));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          _noticeDismissAt != null &&
          DateTime.now().isAfter(_noticeDismissAt!)) {
        setState(() => _gestureNotice = null);
      }
    });
  }

  void _updatePoseState(Pose pose, List<HandSkeleton> hands) {
    final classifiedEx = ExerciseClassifier.classify(pose);

    // Active Exercise determination
    final activeKey = _isFreestyleMode
        ? (classifiedEx ?? _selectedExerciseKey)
        : _selectedExerciseKey;

    String? mismatch;
    if (!_isFreestyleMode &&
        widget.targetExercise != null &&
        classifiedEx != null &&
        classifiedEx != widget.targetExercise) {
      mismatch =
          'This looks like ${_exerciseDisplayName(classifiedEx)} — switch?';
    }

    // Wrist rotation check for bicep curl
    double? wristRotation;
    if (hands.isNotEmpty) {
      final elbow =
          pose.landmarks[PoseLandmarkType.leftElbow] ??
          pose.landmarks[PoseLandmarkType.rightElbow];
      wristRotation = _handLandmarkService.getWristRotationAngle(
        hands.first,
        elbow,
      );
    }

    FormFeedback? feedback;
    double currentAngle = 180.0;
    PoseLandmarkType vertexJoint = PoseLandmarkType.leftKnee;

    if (activeKey == 'squat') {
      vertexJoint = PoseLandmarkType.leftKnee;
      final hip =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftHip) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightHip);
      final knee =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftKnee) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightKnee);
      final ankle =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftAnkle) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightAnkle);
      if (hip != null && knee != null && ankle != null) {
        currentAngle = FormAnalyzer.calculateAngle(hip, knee, ankle);
      }

      feedback = FormAnalyzer.analyzeSquat(
        pose: pose,
        currentPhase: _currentPhase,
        maxKneeFlexion: _maxFlexion,
        onPhaseChanged: (p) {
          _currentPhase = p;
          if (p == 'down') _maxFlexion = 180.0;
        },
        onRepCompleted: () => _handleRepCompleted('Squat'),
      );
    } else if (activeKey == 'push_up') {
      vertexJoint = PoseLandmarkType.leftElbow;
      final shoulder =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftShoulder) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightShoulder);
      final elbow =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftElbow) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightElbow);
      final wrist =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftWrist) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightWrist);
      if (shoulder != null && elbow != null && wrist != null) {
        currentAngle = FormAnalyzer.calculateAngle(shoulder, elbow, wrist);
      }

      feedback = FormAnalyzer.analyzePushUp(
        pose: pose,
        currentPhase: _currentPhase,
        maxElbowFlexion: _maxFlexion,
        onPhaseChanged: (p) {
          _currentPhase = p;
          if (p == 'down') _maxFlexion = 180.0;
        },
        onRepCompleted: () => _handleRepCompleted('Push-up'),
      );
    } else if (activeKey == 'bicep_curl') {
      vertexJoint = PoseLandmarkType.leftElbow;
      final shoulder =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftShoulder) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightShoulder);
      final elbow =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftElbow) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightElbow);
      final wrist =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftWrist) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightWrist);
      if (shoulder != null && elbow != null && wrist != null) {
        currentAngle = FormAnalyzer.calculateAngle(shoulder, elbow, wrist);
      }

      feedback = FormAnalyzer.analyzeBicepCurl(
        pose: pose,
        currentPhase: _currentPhase,
        onPhaseChanged: (p) => _currentPhase = p,
        onRepCompleted: () => _handleRepCompleted('Bicep Curl'),
        wristRotationAngle: wristRotation,
      );
    } else if (activeKey == 'shoulder_press') {
      vertexJoint = PoseLandmarkType.leftElbow;
      final shoulder =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftShoulder) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightShoulder);
      final elbow =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftElbow) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightElbow);
      final wrist =
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.leftWrist) ??
          FormAnalyzer.getValidLandmark(pose, PoseLandmarkType.rightWrist);
      if (shoulder != null && elbow != null && wrist != null) {
        currentAngle = FormAnalyzer.calculateAngle(shoulder, elbow, wrist);
      }

      feedback = FormAnalyzer.analyzeShoulderPress(
        pose: pose,
        currentPhase: _currentPhase,
        onPhaseChanged: (p) => _currentPhase = p,
        onRepCompleted: () => _handleRepCompleted('Shoulder Press'),
      );
    } else if (activeKey == 'jumping_jack') {
      vertexJoint = PoseLandmarkType.leftShoulder;
      feedback = FormAnalyzer.analyzeJumpingJack(
        pose: pose,
        currentPhase: _currentPhase,
        onPhaseChanged: (p) => _currentPhase = p,
        onRepCompleted: () => _handleRepCompleted('Jumping Jack'),
      );
    } else if (activeKey == 'plank') {
      vertexJoint = PoseLandmarkType.leftHip;
      feedback = FormAnalyzer.analyzePlank(pose: pose);
    } else if (widget.customPattern != null) {
      vertexJoint = PoseLandmarkType.leftKnee;
      feedback = FormAnalyzer.analyzeCustom(
        pose: pose,
        pattern: widget.customPattern!,
        currentPhase: _currentPhase,
        currentExtremeAngle: _maxFlexion,
        onPhaseChanged: (p) {
          _currentPhase = p;
          if (p == 'down') _maxFlexion = 180.0;
        },
        onRepCompleted: () => _handleRepCompleted('Custom'),
      );
    }

    if (!mounted) return;

    // Zero-latency isolated repaint of pose overlay painter
    _poseOverlayNotifier.value = PoseOverlayData(
      pose: pose,
      hands: hands,
      isGoodForm: feedback?.isGoodForm ?? true,
      currentJointAngle: currentAngle,
      primaryJointType: vertexJoint,
      currentPhase: _currentPhase,
      exercise: widget.targetExercise ?? classifiedEx ?? 'custom',
    );

    // Only invoke setState when text/badge UI state changes to keep UI 60 FPS
    final bool msgChanged = feedback != null && feedback.message != _feedbackMessage;
    final bool isGoodFormChanged = feedback != null && feedback.isGoodForm != _isGoodForm;
    final bool exChanged = classifiedEx != _classifiedExercise;
    final bool progressChanged = feedback != null && (feedback.progress - _repProgress).abs() > 0.05;

    if (msgChanged || isGoodFormChanged || exChanged || progressChanged) {
      setState(() {
        _lastPose = pose;
        _lastHands = hands;
        _classifiedExercise = classifiedEx;
        _mismatchNotice = mismatch;
        _currentJointAngle = currentAngle;
        _primaryJointType = vertexJoint;

        if (feedback != null) {
          _feedbackMessage = feedback.message;
          _isGoodForm = feedback.isGoodForm;
          _repProgress = feedback.progress;
          if (_currentPhase == 'down' && feedback.progress < _maxFlexion) {
            _maxFlexion = feedback.progress;
          }
        }
      });
    }
  }

  void _handleRepCompleted(String exerciseName) {
    setState(() {
      _repCount++;
      if (_freestyleTally.containsKey(exerciseName)) {
        _freestyleTally[exerciseName] =
            (_freestyleTally[exerciseName] ?? 0) + 1;
      }
    });
  }

  @override
  void dispose() {
    _poseOverlayNotifier.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseDetectorService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeExerciseLabel = _isFreestyleMode
        ? (_classifiedExercise != null
              ? _exerciseDisplayName(_classifiedExercise!)
              : 'Freestyle Detect')
        : (widget.targetExercise != null
              ? _exerciseDisplayName(widget.targetExercise!)
              : 'Auto-Detect');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          activeExerciseLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Text(
                  'Sim',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isSimulationMode,
                    activeTrackColor: AppColors.accentEmeraldLight.withValues(
                      alpha: 0.5,
                    ),
                    activeThumbColor: AppColors.accentEmeraldLight,
                    onChanged: (val) {
                      setState(() {
                        _isSimulationMode = val;
                        if (!val && !_isCameraInitialized) {
                          _initializeCamera();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Full Screen Camera / Overlay Viewport
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Camera preview or simulation
                  _isSimulationMode
                      ? _buildSimulationGraphic(theme)
                      : _isCameraInitialized && _cameraController != null
                      ? ClipRect(
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraPreviewSize.width,
                                height: _cameraPreviewSize.height,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CameraPreview(_cameraController!),
                                    ValueListenableBuilder<PoseOverlayData?>(
                                      valueListenable: _poseOverlayNotifier,
                                      builder: (context, overlayData, _) {
                                        if (overlayData == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return CustomPaint(
                                          painter: _SkeletonOverlayPainter(
                                            pose: overlayData.pose,
                                            hands: overlayData.hands,
                                            imageSize: _cameraPreviewSize,
                                            isFrontCamera:
                                                _cameraController
                                                        ?.description
                                                        .lensDirection ==
                                                    CameraLensDirection.front,
                                            isGoodForm: overlayData.isGoodForm,
                                            showGhostTrainer:
                                                Provider.of<ProfileProvider>(
                                                  context,
                                                  listen: false,
                                                ).ghostTrainerEnabled,
                                            exercise: overlayData.exercise,
                                            phase: overlayData.currentPhase,
                                            measuredAngle:
                                                overlayData.currentJointAngle,
                                            jointType:
                                                overlayData.primaryJointType,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentEmeraldLight,
                          ),
                        ),

                  // 3. Vertical Gradient Progress Slider (Right Edge)
                  Positioned(
                    right: 8,
                    top: 60,
                    bottom: 60,
                    child: _buildVerticalProgressSlider(),
                  ),

                  // 4. Calibration overlay
                  if (_isCalibrating)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: FadeTransition(
                          opacity: _pulseAnimation,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.accentEmeraldLight,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Calibrating AI & Hand Landmarks...',
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

                  // 4.5 Paused by Gesture Overlay Banner
                  if (_isPausedByGesture)
                    Positioned(
                      top: 180,
                      left: 24,
                      right: 40,
                      child: GestureDetector(
                        onTap: _resumeDetection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withValues(
                              alpha: 0.95,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amberAccent,
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 10),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pause_circle_filled_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '✋ Detection Paused by Gesture — Tap to Resume',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 5. Active Header UI & Notifications
                  if (!_isCalibrating)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 28,
                      child: Column(
                        children: [
                          // Top Status Row (horizontal scroll prevents any overflow)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRepCounterBadge(),
                                const SizedBox(width: 6),
                                _buildExerciseSelectorChip(),
                                const SizedBox(width: 6),
                                _buildExerciseGuideChip(),
                                const SizedBox(width: 6),
                                _buildPhaseChip(_currentPhase),
                                const SizedBox(width: 6),
                                if (_classifiedExercise != null)
                                  _buildInfoBadge(
                                    'DETECTED',
                                    _exerciseDisplayName(_classifiedExercise!),
                                    Colors.amber,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Progress Ticks Dot Row
                          _buildProgressDotsRow(),
                          const SizedBox(height: 8),

                          // Form Feedback Banner
                          _buildFeedbackCard(
                            _feedbackMessage,
                            _isGoodForm
                                ? AppColors.accentEmeraldLight
                                : Colors.orange,
                          ),
                          const SizedBox(height: 6),

                          // Live rep progress indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _repProgress,
                              minHeight: 4,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isGoodForm
                                    ? AppColors.accentEmeraldLight
                                    : Colors.orange,
                              ),
                            ),
                          ),

                          // Multi-exercise Live Tally Panel (Freestyle Mode — hidden when AI is actively detecting for full screen view)
                          if (_isFreestyleMode && _lastPose == null) ...[
                            const SizedBox(height: 8),
                            _buildFreestyleTallyPanel(),
                          ],

                          // Gesture Toast Notification Alert
                          if (_gestureNotice != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentEmeraldLight.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                _gestureNotice!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],

                          // Mismatch Notice
                          if (!_isFreestyleMode && _mismatchNotice != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.amber,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _mismatchNotice!,
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // 6. Floating Controls Toggle Chip (Bottom Center)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: InkWell(
                        onTap: () => setState(
                          () => _showBottomPanel = !_showBottomPanel,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentEmeraldLight.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showBottomPanel
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.tune_rounded,
                                color: AppColors.accentEmeraldLight,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showBottomPanel
                                    ? 'Hide Controls'
                                    : 'Show Controls',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
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

            // Bottom Control Panel (Hides when _showBottomPanel is false for 100% full screen view)
            if (_showBottomPanel)
              Container(
                color: Colors.black,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: PastelGradientCard(
                  type: PastelCardType.slate,
                  padding: const EdgeInsets.all(12),
                  borderRadius: 20,
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

  Widget _buildExerciseSelectorChip() {
    final label = _exerciseDisplayName(_selectedExerciseKey);
    return GestureDetector(
      onTap: _showExercisePickerModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentEmeraldLight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentEmeraldLight, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.accentEmeraldLight,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.accentEmeraldLight,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.accentEmeraldLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseGuideChip() {
    return GestureDetector(
      onTap: () => _showExerciseGuideModal(_selectedExerciseKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber, width: 1.2),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.amber, size: 14),
            SizedBox(width: 4),
            Text(
              'Guide',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExercisePickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14181F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final exercises = [
          {
            'key': 'squat',
            'name': 'Squat',
            'icon': Icons.fitness_center_rounded,
          },
          {
            'key': 'push_up',
            'name': 'Push-Up',
            'icon': Icons.sports_gymnastics_rounded,
          },
          {
            'key': 'bicep_curl',
            'name': 'Bicep Curl',
            'icon': Icons.accessibility_new_rounded,
          },
          {
            'key': 'shoulder_press',
            'name': 'Shoulder Press',
            'icon': Icons.accessibility_rounded,
          },
          {
            'key': 'jumping_jack',
            'name': 'Jumping Jack',
            'icon': Icons.directions_run_rounded,
          },
          {
            'key': 'plank',
            'name': 'Plank',
            'icon': Icons.horizontal_rule_rounded,
          },
        ];

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Exercise to Track',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: exercises.map((ex) {
                        final String key = ex['key'] as String;
                        final bool isSelected =
                            !_isFreestyleMode && _selectedExerciseKey == key;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          leading: Icon(
                            ex['icon'] as IconData,
                            color: isSelected
                                ? AppColors.accentEmeraldLight
                                : Colors.white70,
                          ),
                          title: Text(
                            ex['name'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.accentEmeraldLight
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showExerciseGuideModal(key);
                                },
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.accentEmeraldLight,
                                ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedExerciseKey = key;
                              _isFreestyleMode = false;
                              _repCount = 0;
                              _maxFlexion = 180.0;
                            });
                            Navigator.pop(context);
                            _showExerciseGuideModal(key);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepCounterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentEmeraldLight, width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            'REPS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          Text(
            '$_repCount/$_targetReps',
            style: const TextStyle(
              color: AppColors.accentEmeraldLight,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChip(String phase) {
    final String label = phase.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accentEmeraldLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDotsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_targetReps, (index) {
        final bool isCompleted = index < _repCount;
        final bool isCurrent = index == _repCount;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isCurrent ? 14 : 10,
          height: isCurrent ? 14 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.accentEmeraldLight
                : isCurrent
                ? Colors.amber
                : Colors.white24,
            boxShadow: isCompleted || isCurrent
                ? [
                    BoxShadow(
                      color:
                          (isCompleted
                                  ? AppColors.accentEmeraldLight
                                  : Colors.amber)
                              .withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildVerticalProgressSlider() {
    final double ratio = (_repCount / _targetReps).clamp(0.0, 1.0);
    return Container(
      width: 8,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          FractionallySizedBox(
            heightFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentEmeraldLight, Color(0xFF2DD4BF)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreestyleTallyPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _freestyleTally.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: const TextStyle(
                      color: AppColors.accentEmeraldLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(String feedback, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            _isGoodForm
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
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
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePanel(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.center_focus_strong_rounded,
                size: 24,
                color: Color(0xFF0D807B),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isFreestyleMode
                      ? 'Freestyle Circuit Mode'
                      : 'Targeted Form Check',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF14181F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isFreestyleMode
                ? 'AI is continuously identifying movements (Squats, Push-ups, Curls, Presses) & auto-tallying reps.'
                : 'Targeting ${_exerciseDisplayName(widget.targetExercise ?? "Squat")}. ✋ Open palm pauses live camera stream. 👍 Thumbs-up completes set.',
            style: TextStyle(
              color: const Color(0xFF14181F).withValues(alpha: 0.65),
              fontSize: 11,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0D807B)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(
                  Icons.restart_alt_rounded,
                  color: Color(0xFF0D807B),
                  size: 16,
                ),
                label: const Text(
                  'Reset',
                  style: TextStyle(
                    color: Color(0xFF0D807B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                onPressed: () => setState(() {
                  _repCount = 0;
                  _currentPhase = 'up';
                  _maxFlexion = 180.0;
                  _freestyleTally.updateAll((key, value) => 0);
                }),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isPausedByGesture
                        ? Colors.orange.shade800
                        : const Color(0xFF0D807B),
                  ),
                  backgroundColor: _isPausedByGesture
                      ? Colors.orange.shade50
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                icon: Icon(
                  _isPausedByGesture
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: _isPausedByGesture
                      ? Colors.orange.shade800
                      : const Color(0xFF0D807B),
                  size: 16,
                ),
                label: Text(
                  _isPausedByGesture ? 'Resume' : 'Pause',
                  style: TextStyle(
                    color: _isPausedByGesture
                        ? Colors.orange.shade800
                        : const Color(0xFF0D807B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isPausedByGesture = !_isPausedByGesture;
                    _showGestureNotice(
                      _isPausedByGesture ? '✋ AI Paused' : 'AI Resumed',
                    );
                  });
                },
              ),
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  final bool ghostEnabled = profileProvider.ghostTrainerEnabled;
                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: ghostEnabled ? Colors.teal : Colors.grey,
                      ),
                      backgroundColor: ghostEnabled
                          ? Colors.teal.withValues(alpha: 0.08)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    icon: Icon(
                      ghostEnabled ? Icons.visibility : Icons.visibility_off,
                      color: ghostEnabled ? Colors.teal : Colors.grey,
                      size: 16,
                    ),
                    label: Text(
                      'Ghost Silhouette',
                      style: TextStyle(
                        color: ghostEnabled ? Colors.teal : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    onPressed: () {
                      profileProvider.toggleGhostTrainer(!ghostEnabled);
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationControls(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Simulation & Hand Gesture Controller',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF14181F),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildSlider('Knee Angle', _simKneeAngle, 70, 180, (val) {
            setState(() {
              _simKneeAngle = val;
              _currentJointAngle = val;
              _simulateSquatUpdate(val);
            });
          }),
          _buildSlider('Elbow Angle', _simElbowAngle, 60, 180, (val) {
            setState(() {
              _simElbowAngle = val;
              _currentJointAngle = val;
            });
          }),
          Row(
            children: [
              FilterChip(
                label: const Text(
                  '✋ Open Palm Gesture',
                  style: TextStyle(fontSize: 10),
                ),
                selected: _simPalmGesture,
                onSelected: (val) {
                  setState(() {
                    _simPalmGesture = val;
                    _isPausedByGesture = val;
                    _showGestureNotice(
                      val
                          ? '✋ Open Palm: Detection Paused'
                          : '✋ Open Palm: Detection Resumed',
                    );
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text(
                  '👍 Thumbs Up Gesture',
                  style: TextStyle(fontSize: 10),
                ),
                selected: _simThumbsUpGesture,
                onSelected: (val) {
                  setState(() {
                    _simThumbsUpGesture = val;
                    if (val) _showGestureNotice('👍 Thumbs Up: Set Completed!');
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF14181F).withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value,
            activeColor: const Color(0xFF0D807B),
            inactiveColor: const Color(0xFF14181F).withValues(alpha: 0.15),
            onChanged: onChanged,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}°',
          style: const TextStyle(
            color: Color(0xFF14181F),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _simulateSquatUpdate(double kneeAngle) {
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
        _handleRepCompleted('Squat');
        _feedbackMessage = 'Rep $_repCount complete!';
        _isGoodForm = true;
        _repProgress = 0.0;
      });
    }
  }

  Widget _buildSimulationGraphic(ThemeData theme) {
    final hands = _handLandmarkService.generateSimulationHands(
      const Size(200, 200),
      _simPalmGesture,
      _simThumbsUpGesture,
    );

    return CustomPaint(
      painter: _StickmanPainter(
        theme: theme,
        kneeAngle: _simKneeAngle,
        spineAngle: _simSpineAngle,
        isGoodForm: _isGoodForm,
        hands: hands,
      ),
    );
  }

  String _exerciseDisplayName(String key) {
    return {
          'squat': 'Squat',
          'push_up': 'Push-Up',
          'bicep_curl': 'Bicep Curl',
          'shoulder_press': 'Shoulder Press',
          'jumping_jack': 'Jumping Jack',
          'plank': 'Plank',
          'custom': 'Custom Exercise',
        }[key] ??
        key;
  }

  static final Map<String, Map<String, dynamic>> _exerciseGuides = {
    'squat': {
      'title': 'Squat Form Guide',
      'icon': Icons.fitness_center_rounded,
      'targetAngle': 'Knee flex ≤ 95° at bottom',
      'setup':
          'Stand tall with feet shoulder-width apart, toes turned slightly outward (5-15°). Keep your chest upright and core tight.',
      'execution':
          'Initiate movement by pushing hips back as if sitting in a chair. Bend knees until thighs are parallel to floor (<95° knee angle). Press through heels to stand tall.',
      'aiCues':
          'AI tracks hip-knee-ankle angle continuously. Green skeleton indicates optimal depth and erect posture.',
      'mistakes':
          '• Knees collapsing inward (valgus)\n• Heels lifting off floor\n• Excessive forward torso leaning',
    },
    'push_up': {
      'title': 'Push-Up Form Guide',
      'icon': Icons.sports_gymnastics_rounded,
      'targetAngle': 'Elbow flex ≤ 90° at bottom',
      'setup':
          'Place hands slightly wider than shoulders. Form a straight rigid line from shoulders through hips to ankles in high plank.',
      'execution':
          'Lower body as a single unit by bending elbows to 90° or lower. Keep elbows at ~45° angle relative to torso. Press up firmly.',
      'aiCues':
          'AI evaluates shoulder-elbow-wrist angle and spine linearity to ensure complete reps.',
      'mistakes':
          '• Hips sagging toward ground\n• Piking hips upward into inverted V\n• Incomplete elbow bending (half reps)',
    },
    'bicep_curl': {
      'title': 'Bicep Curl Form Guide',
      'icon': Icons.accessibility_new_rounded,
      'targetAngle': 'Elbow flex ≤ 50° top, ~180° bottom',
      'setup':
          'Stand tall with arms fully extended down by sides, palms facing forward (supinated grip), shoulders pulled back.',
      'execution':
          'Flex elbows to curl weight upward while keeping elbows pinned to ribcage. Squeeze biceps at peak (<50° angle) and lower under control.',
      'aiCues':
          'AI measures elbow flexion range & checks wrist rotation/alignment with 21 hand landmarks.',
      'mistakes':
          '• Swinging body for momentum\n• Elbows flaring out or moving forward\n• Cutting bottom extension short',
    },
    'shoulder_press': {
      'title': 'Overhead Press Form Guide',
      'icon': Icons.accessibility_rounded,
      'targetAngle': 'Arm extension ≥ 165° overhead',
      'setup':
          'Hold weights or hands at ear/shoulder height, elbows bent at 90°, core and glutes engaged.',
      'execution':
          'Press straight overhead until arms are extended overhead without arching lower back. Return under control to shoulder level.',
      'aiCues':
          'AI measures overhead arm angle & checks shoulder height symmetry in real time.',
      'mistakes':
          '• Excessive lower back arching\n• Asymmetrical press (one arm higher)\n• Stopping short of full overhead lockout',
    },
    'jumping_jack': {
      'title': 'Jumping Jack Guide',
      'icon': Icons.directions_run_rounded,
      'targetAngle': 'Arm abduction > 140° overhead',
      'setup':
          'Stand upright with feet together and arms hanging relaxed by your sides.',
      'execution':
          'Jump feet out laterally beyond shoulders while raising arms in wide arc overhead. Jump back to starting position dynamically.',
      'aiCues':
          'AI detects full arm overhead swing and wide stance jumps for rep counting.',
      'mistakes':
          '• Half-arm swings below head height\n• Short foot jumps\n• Irregular, jerky rhythm',
    },
    'plank': {
      'title': 'Plank Form Guide',
      'icon': Icons.horizontal_rule_rounded,
      'targetAngle': 'Spine alignment ~180° straight line',
      'setup':
          'Place forearms on ground under shoulders. Extend legs straight back resting on toes.',
      'execution':
          'Contract core, glutes, and quad muscles to maintain rigid straight line from neck to heels. Hold steady without moving.',
      'aiCues':
          'AI analyzes shoulder-hip-ankle line to detect hip drop or hip pike warnings.',
      'mistakes':
          '• Dropping lower back and hips\n• Raising hips into inverted V\n• Holding breath',
    },
  };

  void _showExerciseGuideModal(String exerciseKey) {
    final guide = _exerciseGuides[exerciseKey] ?? _exerciseGuides['squat']!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14181F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmeraldLight.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          guide['icon'] as IconData,
                          color: AppColors.accentEmeraldLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Target: ${guide['targetAngle'] as String}',
                            style: const TextStyle(
                              color: AppColors.accentEmeraldLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              // Scrollable Instructions & Tips
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGuideSection(
                        '1. Starting Stance',
                        guide['setup'] as String,
                        Icons.accessibility_new_rounded,
                        Colors.lightBlueAccent,
                      ),
                      const SizedBox(height: 12),
                      _buildGuideSection(
                        '2. Movement Execution',
                        guide['execution'] as String,
                        Icons.fitness_center_rounded,
                        AppColors.accentEmeraldLight,
                      ),
                      const SizedBox(height: 12),
                      _buildGuideSection(
                        '3. Real-Time AI Feedback Cues',
                        guide['aiCues'] as String,
                        Icons.center_focus_strong_rounded,
                        Colors.amber,
                      ),
                      const SizedBox(height: 12),
                      _buildGuideSection(
                        '4. Common Mistakes to Avoid',
                        guide['mistakes'] as String,
                        Icons.warning_amber_rounded,
                        Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentEmeraldLight,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text(
                    'Start AI Form Check Now',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideSection(
    String title,
    String content,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Upgraded CustomPainter for rendering full connected body skeleton, live joint angle readout chips, & 21-point hand skeleton overlay.
class _SkeletonOverlayPainter extends CustomPainter {
  final Pose pose;
  final List<HandSkeleton> hands;
  final Size imageSize;
  final bool isFrontCamera;
  final bool isGoodForm;
  final bool showGhostTrainer;
  final String exercise;
  final String phase;
  final double measuredAngle;
  final PoseLandmarkType jointType;

  _SkeletonOverlayPainter({
    required this.pose,
    required this.hands,
    required this.imageSize,
    this.isFrontCamera = true,
    required this.isGoodForm,
    this.showGhostTrainer = false,
    this.exercise = 'custom',
    this.phase = 'up',
    required this.measuredAngle,
    required this.jointType,
  });

  static const _fullConnections = [
    // Face outline / head
    [PoseLandmarkType.nose, PoseLandmarkType.leftEye],
    [PoseLandmarkType.nose, PoseLandmarkType.rightEye],
    [PoseLandmarkType.leftEye, PoseLandmarkType.leftEar],
    [PoseLandmarkType.rightEye, PoseLandmarkType.rightEar],
    [PoseLandmarkType.leftEye, PoseLandmarkType.rightEye],
    [PoseLandmarkType.leftMouth, PoseLandmarkType.rightMouth],
    [PoseLandmarkType.nose, PoseLandmarkType.leftMouth],
    [PoseLandmarkType.nose, PoseLandmarkType.rightMouth],

    // Torso box
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],

    // Arms
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],

    // Legs
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Color accentColor = isGoodForm
        ? AppColors.accentEmeraldLight
        : Colors.orange;

    final bonePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = isGoodForm ? const Color(0xFFBBF7E0) : Colors.amber
      ..strokeWidth = 7.0
      ..style = PaintingStyle.fill;

    final faceJointPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    Offset toScreen(double lx, double ly) {
      final double x = isFrontCamera
          ? (1.0 - lx / imageSize.width) * size.width
          : (lx / imageSize.width) * size.width;
      final double y = (ly / imageSize.height) * size.height;
      return Offset(x, y);
    }

    // 1. Draw Ghost Silhouette if enabled
    if (showGhostTrainer) {
      final ghostPaint = Paint()
        ..color = const Color(0xFF14B8A6).withValues(alpha: 0.3)
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      for (final pair in _fullConnections) {
        final a = pose.landmarks[pair[0]];
        final b = pose.landmarks[pair[1]];
        if (a != null &&
            b != null &&
            a.likelihood > 0.4 &&
            b.likelihood > 0.4) {
          canvas.drawLine(toScreen(a.x, a.y), toScreen(b.x, b.y), ghostPaint);
        }
      }
    }

    // 2. Draw Full Connected User Body Skeleton
    for (final pair in _fullConnections) {
      final a = pose.landmarks[pair[0]];
      final b = pose.landmarks[pair[1]];
      if (a != null && b != null && a.likelihood > 0.4 && b.likelihood > 0.4) {
        canvas.drawLine(toScreen(a.x, a.y), toScreen(b.x, b.y), bonePaint);
      }
    }

    // Draw Joint Dots
    const faceTypes = {
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEyeInner,
      PoseLandmarkType.leftEye,
      PoseLandmarkType.leftEyeOuter,
      PoseLandmarkType.rightEyeInner,
      PoseLandmarkType.rightEye,
      PoseLandmarkType.rightEyeOuter,
      PoseLandmarkType.leftEar,
      PoseLandmarkType.rightEar,
      PoseLandmarkType.leftMouth,
      PoseLandmarkType.rightMouth,
    };

    for (final entry in pose.landmarks.entries) {
      final lm = entry.value;
      if (lm.likelihood > 0.4) {
        final pos = toScreen(lm.x, lm.y);
        if (faceTypes.contains(entry.key)) {
          canvas.drawCircle(pos, 3.5, faceJointPaint);
        } else {
          canvas.drawCircle(pos, 5.0, jointPaint);
        }
      }
    }

    // 3. Draw Live Joint-Angle Floating Chip Readout
    final targetJoint =
        pose.landmarks[jointType] ?? pose.landmarks[PoseLandmarkType.leftElbow];
    if (targetJoint != null && targetJoint.likelihood > 0.4) {
      final jointPos = toScreen(targetJoint.x, targetJoint.y);
      final angleText = '${measuredAngle.toStringAsFixed(0)}°';

      final TextSpan span = TextSpan(
        text: angleText,
        style: TextStyle(
          color: isGoodForm ? AppColors.accentEmeraldLight : Colors.amber,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout();

      final RRect bgRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          jointPos.dx + 12,
          jointPos.dy - 12,
          tp.width + 16,
          tp.height + 8,
        ),
        const Radius.circular(8),
      );

      final Paint bgPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.85);
      final Paint borderPaint = Paint()
        ..color = isGoodForm ? AppColors.accentEmeraldLight : Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawRRect(bgRRect, bgPaint);
      canvas.drawRRect(bgRRect, borderPaint);
      tp.paint(canvas, Offset(jointPos.dx + 20, jointPos.dy - 8));
    }

    // 4. Draw 21-point Hand & Finger Skeleton Overlay
    final handBonePaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final handJointPaint = Paint()
      ..color = const Color(0xFFBBF7E0)
      ..style = PaintingStyle.fill;

    for (final hand in hands) {
      if (hand.landmarks.length < 21) continue;

      // Finger connection groups
      final fingerIndices = [
        [0, 1, 2, 3, 4], // Thumb
        [0, 5, 6, 7, 8], // Index
        [0, 9, 10, 11, 12], // Middle
        [0, 13, 14, 15, 16], // Ring
        [0, 17, 18, 19, 20], // Pinky
        [5, 9, 13, 17], // Palm bridge
      ];

      for (final group in fingerIndices) {
        for (int i = 0; i < group.length - 1; i++) {
          final p1 = hand.landmarks[group[i]];
          final p2 = hand.landmarks[group[i + 1]];
          canvas.drawLine(
            toScreen(p1.x, p1.y),
            toScreen(p2.x, p2.y),
            handBonePaint,
          );
        }
      }

      for (final pt in hand.landmarks) {
        canvas.drawCircle(toScreen(pt.x, pt.y), 3.0, handJointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonOverlayPainter oldDelegate) => true;
}

/// Simulation mode painter.
class _StickmanPainter extends CustomPainter {
  final ThemeData theme;
  final double kneeAngle;
  final double spineAngle;
  final bool isGoodForm;
  final List<HandSkeleton> hands;

  _StickmanPainter({
    required this.theme,
    required this.kneeAngle,
    required this.spineAngle,
    required this.isGoodForm,
    required this.hands,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 20);
    final Color boneColor = isGoodForm
        ? AppColors.accentEmeraldLight
        : Colors.orange;

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

    // Render hands in simulation mode
    final handPaint = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..strokeWidth = 2;

    for (final hand in hands) {
      for (int i = 0; i < hand.landmarks.length - 1; i++) {
        canvas.drawLine(
          Offset(hand.landmarks[i].x, hand.landmarks[i].y),
          Offset(hand.landmarks[i + 1].x, hand.landmarks[i + 1].y),
          handPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
