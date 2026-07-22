import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/services/pose_detector_service.dart';
import 'package:gerex/core/presentation/widgets/liquid_background.dart';

class PoseFeedbackScreen extends StatefulWidget {
  const PoseFeedbackScreen({super.key});

  @override
  State<PoseFeedbackScreen> createState() => _PoseFeedbackScreenState();
}

class _PoseFeedbackScreenState extends State<PoseFeedbackScreen> {
  CameraController? _cameraController;
  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  bool _isCameraInitialized = false;
  bool _isSimulationMode = kIsWeb; // default simulation mode on Web

  // Simulator State
  double _kneeAngle = 180.0; // 180 (straight) to 70 (deep squat)
  double _spineAngle = 0.0; // 0 (straight) to 45 (rounded)

  @override
  void initState() {
    super.initState();
    _poseDetectorService.initialize();
    if (!_isSimulationMode) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _isSimulationMode = true);
        return;
      }

      // Use front camera
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
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (_) {
      // Fallback to simulation mode if camera fails
      if (mounted) {
        setState(() => _isSimulationMode = true);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute feedback alerts based on angles
    String squatFeedback = 'Standing/Ready 🏋️';
    Color squatColor = Colors.grey;
    if (_kneeAngle < 90) {
      squatFeedback = 'Great Squat Depth! (Below parallel) ✅';
      squatColor = theme.colorScheme.primary;
    } else if (_kneeAngle >= 90 && _kneeAngle < 140) {
      squatFeedback = 'Squatting... Go deeper for quad activation. ⚠️';
      squatColor = Colors.orange;
    }

    String spineFeedback = 'Spine is safe/neutral ✅';
    Color spineColor = Colors.green;
    if (_spineAngle > 25) {
      spineFeedback = 'Warning: Spine rounding! Keep chest up! 🚨';
      spineColor = theme.colorScheme.error;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Pose Feedback'),
        actions: [
          Row(
            children: [
              const Text('Simulate'),
              Switch(
                value: _isSimulationMode,
                onChanged: (val) {
                  setState(() {
                    _isSimulationMode = val;
                    if (!_isSimulationMode && !_isCameraInitialized) {
                      _initializeCamera();
                    }
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
          // 1. Camera / Simulator Display Panel
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isSimulationMode)
                    _buildSimulationGraphic(theme)
                  else if (_isCameraInitialized && _cameraController != null)
                    CameraPreview(_cameraController!)
                  else
                    const Center(
                      child: CircularProgressIndicator(),
                    ),

                  // Overlay Feedbacks
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFeedbackCard(
                          'Knee Angle: ${_kneeAngle.toStringAsFixed(0)}°',
                          squatFeedback,
                          squatColor,
                        ),
                        const SizedBox(height: 8),
                        _buildFeedbackCard(
                          'Spine Angle: ${_spineAngle.toStringAsFixed(0)}°',
                          spineFeedback,
                          spineColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Control Panel (Simulator adjustments or details info)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: _isSimulationMode
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Simulation Controller',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(width: 90, child: Text('Knee Angle')),
                            Expanded(
                              child: Slider(
                                min: 70,
                                max: 180,
                                value: _kneeAngle,
                                onChanged: (val) =>
                                    setState(() => _kneeAngle = val),
                              ),
                            ),
                            Text('${_kneeAngle.toStringAsFixed(0)}°'),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 90, child: Text('Spine Angle')),
                            Expanded(
                              child: Slider(
                                min: 0,
                                max: 45,
                                value: _spineAngle,
                                onChanged: (val) =>
                                    setState(() => _spineAngle = val),
                              ),
                            ),
                            Text('${_spineAngle.toStringAsFixed(0)}°'),
                          ],
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.center_focus_strong_rounded,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pose Detection Active',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Prop your phone up. Perform squats in front of the front-facing camera to monitor knee flexion and back alignment in real-time.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFeedbackCard(String label, String feedback, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            feedback,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationGraphic(ThemeData theme) {
    return CustomPaint(
      painter: _StickmanPainter(
        theme: theme,
        kneeAngle: _kneeAngle,
        spineAngle: _spineAngle,
      ),
    );
  }
}

class _StickmanPainter extends CustomPainter {
  final ThemeData theme;
  final double kneeAngle;
  final double spineAngle;

  _StickmanPainter({
    required this.theme,
    required this.kneeAngle,
    required this.spineAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 30);

    final paintJoint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final paintBone = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw Hip Joint
    final hip = center;

    // Calculate Knee and Foot based on kneeAngle
    // Simple trigonometry representation
    final radKnee = (kneeAngle * 3.14159) / 180.0;
    // Lower thigh segment
    const thighLength = 60.0;
    final knee = Offset(hip.dx - thighLength * 0.7, hip.dy + thighLength * 0.5);

    // Shin segment flexes based on knee angle relative to thigh
    const shinLength = 60.0;
    final foot = Offset(
      knee.dx + shinLength * (1 - radKnee / 3.14),
      knee.dy + shinLength,
    );

    // Draw Head & Torso with spine angle leaning forward
    final radSpine = (spineAngle * 3.14159) / 180.0;
    final shoulder = Offset(
      hip.dx + 80.0 * (radSpine / 3.14),
      hip.dy - 80.0 * (1 - radSpine / 3.14),
    );
    final head = Offset(
      shoulder.dx + 20.0 * (radSpine / 3.14),
      shoulder.dy - 20.0,
    );

    // Draw Bones
    canvas.drawLine(foot, knee, paintBone);
    canvas.drawLine(knee, hip, paintBone);
    canvas.drawLine(hip, shoulder, paintBone);

    // Draw Head circle
    canvas.drawCircle(head, 15, paintBone);

    // Draw Joints highlight
    canvas.drawCircle(foot, 5, paintJoint);
    canvas.drawCircle(knee, 5, paintJoint);
    canvas.drawCircle(hip, 5, paintJoint);
    canvas.drawCircle(shoulder, 5, paintJoint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
