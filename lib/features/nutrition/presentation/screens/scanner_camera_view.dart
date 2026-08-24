import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerCameraView extends StatefulWidget {
  final Function(File) onImageCaptured;

  const ScannerCameraView({super.key, required this.onImageCaptured});

  @override
  State<ScannerCameraView> createState() => _ScannerCameraViewState();
}

class _ScannerCameraViewState extends State<ScannerCameraView> {
  CameraController? _controller;
  bool _isInitialized = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMsg = 'No camera hardware found');
        return;
      }
      final backCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(backCam, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _errorMsg = 'Camera permission or loading failed');
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_isInitialized) return;
    try {
      final xFile = await _controller!.takePicture();
      widget.onImageCaptured(File(xFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture photo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_errorMsg, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
        ),
      );
    }
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF50C19D)));
    }
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              heroTag: 'capture_food_btn',
              backgroundColor: const Color(0xFF50C19D),
              onPressed: _takePhoto,
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}
