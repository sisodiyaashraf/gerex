import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:gerex/features/ai/data/services/pose_detector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoseDetectorService & Pipeline Architectural Tests', () {
    late PoseDetectorService service;

    setUp(() {
      service = PoseDetectorService();
    });

    tearDown(() {
      service.dispose();
    });

    test('PoseDetectorService initializes and disposes without throwing exceptions', () async {
      await service.initialize();
      service.dispose();
    });

    test('InputImageRotation values mapping correctly', () {
      final rotations = [0, 90, 180, 270];
      for (final r in rotations) {
        final rot = InputImageRotationValue.fromRawValue(r);
        expect(rot, isNotNull);
      }
    });

    test('InputImageFormat values mapping correctly', () {
      final formats = [InputImageFormat.nv21, InputImageFormat.bgra8888];
      for (final f in formats) {
        expect(f.rawValue, isNotNull);
      }
    });
  });
}
