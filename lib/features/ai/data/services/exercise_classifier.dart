import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'form_analyzer.dart';

class ExerciseClassifier {
  ExerciseClassifier._();

  /// Determines which known exercise pattern the user's current stance matches.
  static String? classify(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist] ?? pose.landmarks[PoseLandmarkType.rightWrist];
    
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee] ?? pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle] ?? pose.landmarks[PoseLandmarkType.rightAnkle];

    if (leftHip == null || leftKnee == null) return null;

    // 1. Calculate main joint flexion angles
    double kneeAngle = 180.0;
    if (leftAnkle != null) {
      kneeAngle = FormAnalyzer.calculateAngle(leftHip, leftKnee, leftAnkle);
    }
    
    double elbowAngle = 180.0;
    if (leftShoulder != null && leftElbow != null && leftWrist != null) {
      elbowAngle = FormAnalyzer.calculateAngle(leftShoulder, leftElbow, leftWrist);
    }

    // 2. Classify by angle ranges and alignment signatures
    // A. Plank signature: horizontal leaning body + straight hip/knees + elbows flexed ~90°
    if (leftShoulder != null && leftAnkle != null) {
      final spineLean = FormAnalyzer.calculateLeanAngle(leftShoulder, leftHip);
      final hipAngle = FormAnalyzer.calculateAngle(leftShoulder, leftHip, leftKnee);
      
      if (spineLean > 60.0 && hipAngle > 150.0 && hipAngle < 210.0 && kneeAngle > 155.0) {
        return 'plank';
      }
    }

    // B. Squat signature: active bending of knees < 115° while standing/upright torso
    if (kneeAngle < 125.0) {
      if (leftShoulder != null) {
        final spineLean = FormAnalyzer.calculateLeanAngle(leftShoulder, leftHip);
        // Upright or slightly leaning (typical back position during squat)
        if (spineLean < 40.0) {
          return 'squat';
        }
      }
    }

    // C. Push-up signature: horizontal body + active bending of elbows < 115°
    if (elbowAngle < 120.0 && leftShoulder != null) {
      final spineLean = FormAnalyzer.calculateLeanAngle(leftShoulder, leftHip);
      if (spineLean > 60.0) {
        return 'push_up';
      }
    }

    // D. Jumping Jack signature: arms high up + legs wide
    if (leftShoulder != null && leftElbow != null) {
      final armAngle = FormAnalyzer.calculateAngle(leftHip, leftShoulder, leftElbow);
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
      
      double legWidthRatio = 0.0;
      if (rightHip != null && rightKnee != null) {
        final hipWidth = (leftHip.x - rightHip.x).abs();
        final footWidth = (leftKnee.x - rightKnee.x).abs();
        legWidthRatio = footWidth / (hipWidth == 0 ? 1 : hipWidth);
      }
      
      if (armAngle > 95.0 && legWidthRatio > 1.5) {
        return 'jumping_jack';
      }
    }

    return null;
  }
}
