import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  PoseDetector? _poseDetector;
  int _lastInferenceMs = 0;

  int get lastInferenceMs => _lastInferenceMs;

  PoseDetectorService();

  Future<void> initialize() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      );
      _poseDetector = PoseDetector(options: options);
      if (kDebugMode) {
        print('[PoseDetectorService] ML Kit PoseDetector initialized in stream mode.');
      }
    }
  }

  Future<List<Pose>> processImage(InputImage inputImage) async {
    if (_poseDetector == null) return [];
    final stopwatch = Stopwatch()..start();
    final poses = await _poseDetector!.processImage(inputImage);
    stopwatch.stop();
    _lastInferenceMs = stopwatch.elapsedMilliseconds;
    if (kDebugMode) {
      print('[PoseDetectorService] Processed frame in ${_lastInferenceMs}ms (${poses.length} pose(s) detected)');
    }
    return poses;
  }

  void dispose() {
    _poseDetector?.close();
    _poseDetector = null;
    if (kDebugMode) {
      print('[PoseDetectorService] ML Kit PoseDetector closed.');
    }
  }
}
