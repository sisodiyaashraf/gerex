import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  PoseDetector? _poseDetector;

  PoseDetectorService();

  Future<void> initialize() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      );
      _poseDetector = PoseDetector(options: options);
    }
  }

  Future<List<Pose>> processImage(InputImage inputImage) async {
    if (_poseDetector == null) return [];
    return _poseDetector!.processImage(inputImage);
  }

  void dispose() {
    _poseDetector?.close();
  }
}
