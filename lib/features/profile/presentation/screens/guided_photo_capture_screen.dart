import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../providers/progress_photos_provider.dart';
import 'package:gerex/core/presentation/widgets/glass_container.dart';
import 'package:gerex/core/theme/app_theme.dart';

class GuidedPhotoCaptureScreen extends StatefulWidget {
  const GuidedPhotoCaptureScreen({super.key});

  @override
  State<GuidedPhotoCaptureScreen> createState() => _GuidedPhotoCaptureScreenState();
}

class _GuidedPhotoCaptureScreenState extends State<GuidedPhotoCaptureScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off;
  String _selectedPose = 'Front'; // 'Front', 'Back', 'Left', 'Right'

  final List<String> _poses = ['Front', 'Back', 'Left', 'Right'];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCameraController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Failed to get cameras: $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    setState(() => _isCameraInitialized = false);
    _cameraController = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Failed to initialize camera controller: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    final nextFlash = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _cameraController!.setFlashMode(nextFlash);
      setState(() {
        _flashMode = nextFlash;
      });
    } catch (e) {
      debugPrint('Failed to toggle flash: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      final XFile rawImage = await _cameraController!.takePicture();
      final File imageFile = File(rawImage.path);

      if (mounted) {
        final provider = context.read<ProgressPhotosProvider>();
        final err = await provider.addCapturedPhoto(imageFile, _selectedPose);

        if (mounted) {
          if (err != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully captured and saved $_selectedPose progress photo!')),
            );
            context.pop();
          }
        }
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture photo. Please check permissions.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Guided Align Capture', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Camera preview background
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'Initializing camera sensor...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Translucent human figure outline overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SilhouettePainter(theme: theme),
              ),
            ),
          ),

          // 3. Pose selection tab strip (top of camera overlay)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _poses.map((pose) {
                  final isSelected = pose == _selectedPose;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(pose),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedPose = pose);
                        }
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      backgroundColor: Colors.black54,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 4. Guided Capture pill panel controls (bottom layout)
          Positioned(
            bottom: 30 + MediaQuery.of(context).padding.bottom,
            left: 20,
            right: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              borderRadius: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flash toggle button
                  IconButton(
                    icon: Icon(
                      _flashMode == FlashMode.torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _toggleFlash,
                  ),

                  // Capture button (large gradient circle)
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        gradient: GerexGradients.primaryCTA,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Camera flip sensor
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 24),
                    onPressed: _flipCamera,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final ThemeData theme;

  _SilhouettePainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paintOutline = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Drawing a simple body silhouette template
    // Head
    path.addOval(Rect.fromCircle(center: Offset(cx, cy - 140), radius: 35));

    // Neck
    path.moveTo(cx - 8, cy - 105);
    path.lineTo(cx - 8, cy - 85);
    path.lineTo(cx + 8, cy - 85);
    path.lineTo(cx + 8, cy - 105);

    // Shoulders & Chest
    path.moveTo(cx - 65, cy - 75);
    path.quadraticBezierTo(cx, cy - 88, cx + 65, cy - 75);
    path.lineTo(cx + 55, cy - 25);
    path.lineTo(cx - 55, cy - 25);
    path.close();

    // Hips & Legs guideline
    path.moveTo(cx - 45, cy - 25);
    path.lineTo(cx + 45, cy - 25);
    path.lineTo(cx + 35, cy + 90);
    path.lineTo(cx + 15, cy + 180);
    path.lineTo(cx - 15, cy + 180);
    path.lineTo(cx - 35, cy + 90);
    path.close();

    canvas.drawPath(path, paintOutline);

    // Dynamic grid assist lines
    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paintGrid);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paintGrid);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
