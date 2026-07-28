import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class FormFeedback {
  final String message;
  final bool isGoodForm;
  final double progress; // 0.0 to 1.0 representation of rep completeness

  FormFeedback({
    required this.message,
    required this.isGoodForm,
    required this.progress,
  });
}

class FormAnalyzer {
  FormAnalyzer._();

  /// Calculates the 3D angle (in degrees) at the vertex joint between first and last points.
  static double calculateAngle(PoseLandmark first, PoseLandmark vertex, PoseLandmark last) {
    // Vectors relative to vertex
    final double ax = first.x - vertex.x;
    final double ay = first.y - vertex.y;
    final double az = first.z - vertex.z;

    final double cx = last.x - vertex.x;
    final double cy = last.y - vertex.y;
    final double cz = last.z - vertex.z;

    final double dotProduct = ax * cx + ay * cy + az * cz;
    final double magnitudeA = sqrt(ax * ax + ay * ay + az * az);
    final double magnitudeC = sqrt(cx * cx + cy * cy + cz * cz);

    if (magnitudeA * magnitudeC == 0) return 180.0;

    double cosValue = dotProduct / (magnitudeA * magnitudeC);
    // Clamp to valid range to prevent acos NaN
    if (cosValue < -1.0) cosValue = -1.0;
    if (cosValue > 1.0) cosValue = 1.0;

    final double radians = acos(cosValue);
    return radians * 180.0 / pi;
  }

  /// Calculates the horizontal lean angle (in degrees) of a segment relative to vertical axis.
  static double calculateLeanAngle(PoseLandmark upper, PoseLandmark lower) {
    final double dx = (upper.x - lower.x).abs();
    final double dy = (upper.y - lower.y).abs();
    return atan2(dx, dy) * 180.0 / pi;
  }

  /// Analyzes the pose and returns feedback based on target exercise.
  /// Also tracks state variables (rep count, rep phase) internally.
  static FormFeedback analyzeSquat({
    required Pose pose,
    required String currentPhase, // 'up' or 'down'
    required double maxKneeFlexion, // track deepest point in current rep
    required Function(String nextPhase) onPhaseChanged,
    required Function() onRepCompleted,
  }) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];

    if (leftHip == null || leftKnee == null || leftAnkle == null) {
      return FormFeedback(message: "Stand sideways to show profile", isGoodForm: false, progress: 0.0);
    }

    final kneeAngle = calculateAngle(leftHip, leftKnee, ankleOrFallback(leftAnkle, pose));
    final spineLean = leftShoulder != null ? calculateLeanAngle(leftShoulder, leftHip) : 0.0;

    bool isGoodSpine = spineLean < 35.0;
    String feedback = "Keep your chest up";

    // Squat Rep-Counter Logic
    double progress = 0.0;
    if (currentPhase == 'up') {
      // Standing position is ~170-180 deg
      progress = max(0.0, (170.0 - kneeAngle) / 80.0); // Progress increases as knee bends
      if (kneeAngle < 120.0) {
        onPhaseChanged('down');
      }
      feedback = isGoodSpine ? "Squat down smoothly" : "Keep your back straight!";
    } else if (currentPhase == 'down') {
      progress = min(1.0, (170.0 - kneeAngle) / 80.0);
      if (kneeAngle > 155.0) {
        // Returned to starting position - rep check
        onPhaseChanged('up');
        if (maxKneeFlexion < 110.0) {
          onRepCompleted();
          feedback = "Excellent squat!";
        } else {
          feedback = "Squat deeper next time!";
        }
      } else {
        feedback = kneeAngle < 100.0
            ? "Good depth! Drive back up"
            : "Lower your hips below parallel";
      }
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: isGoodSpine && (kneeAngle < 110.0 || currentPhase == 'up'),
      progress: progress.clamp(0.0, 1.0),
    );
  }

  static FormFeedback analyzePushUp({
    required Pose pose,
    required String currentPhase, // 'up' or 'down'
    required double maxElbowFlexion,
    required Function(String nextPhase) onPhaseChanged,
    required Function() onRepCompleted,
  }) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftElbow == null || leftWrist == null) {
      return FormFeedback(message: "Position full upper body in frame", isGoodForm: false, progress: 0.0);
    }

    final elbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    
    // Hip sag check (body alignment)
    double hipAngle = 180.0;
    if (leftHip != null && leftKnee != null) {
      hipAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    }
    final isStraightSpine = hipAngle > 155.0 && hipAngle < 195.0;
    String feedback = "Lower your body";

    double progress = 0.0;
    if (currentPhase == 'up') {
      progress = max(0.0, (160.0 - elbowAngle) / 75.0);
      if (elbowAngle < 115.0) {
        onPhaseChanged('down');
      }
      feedback = isStraightSpine ? "Lower your body" : "Don't sag your hips!";
    } else if (currentPhase == 'down') {
      progress = min(1.0, (160.0 - elbowAngle) / 75.0);
      if (elbowAngle > 150.0) {
        onPhaseChanged('up');
        if (maxElbowFlexion < 100.0) {
          onRepCompleted();
          feedback = "Solid rep!";
        } else {
          feedback = "Go lower next time!";
        }
      } else {
        feedback = elbowAngle < 95.0 ? "Great depth! Push up" : "Lower your chest more";
      }
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: isStraightSpine && (elbowAngle < 100.0 || currentPhase == 'up'),
      progress: progress.clamp(0.0, 1.0),
    );
  }

  static FormFeedback analyzeJumpingJack({
    required Pose pose,
    required String currentPhase,
    required Function(String nextPhase) onPhaseChanged,
    required Function() onRepCompleted,
  }) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    if (leftShoulder == null || leftHip == null || leftElbow == null) {
      return FormFeedback(message: "Stand fully in frame", isGoodForm: false, progress: 0.0);
    }

    // Measure arm lift (shoulder-elbow angle relative to hip-shoulder line)
    final armAngle = calculateAngle(leftHip, leftShoulder, leftElbow);
    
    // Leg width check (left hip to right hip vs hip to knee)
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    double legWidthRatio = 0.0;
    if (rightHip != null && rightKnee != null && leftKnee != null) {
      final hipWidth = sqrt(pow(leftHip.x - rightHip.x, 2) + pow(leftHip.y - rightHip.y, 2));
      final footWidth = sqrt(pow(leftKnee.x - rightKnee.x, 2) + pow(leftKnee.y - rightKnee.y, 2));
      legWidthRatio = footWidth / (hipWidth == 0 ? 1 : hipWidth);
    }

    double progress = 0.0;
    String feedback = "Clap hands above head";
    if (currentPhase == 'up') {
      progress = max(0.0, armAngle / 130.0);
      if (armAngle > 110.0 && legWidthRatio > 1.8) {
        onPhaseChanged('down');
      }
      feedback = "Jump hands up and feet wide";
    } else if (currentPhase == 'down') {
      progress = min(1.0, armAngle / 130.0);
      if (armAngle < 45.0 && legWidthRatio < 1.4) {
        onPhaseChanged('up');
        onRepCompleted();
        feedback = "Perfect jack!";
      } else {
        feedback = "Bring arms back down";
      }
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: true,
      progress: progress.clamp(0.0, 1.0),
    );
  }

  static FormFeedback analyzePlank({
    required Pose pose,
  }) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    if (leftShoulder == null || leftHip == null || leftKnee == null || leftAnkle == null) {
      return FormFeedback(message: "Show side profile in frame", isGoodForm: false, progress: 0.0);
    }

    final hipAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    final kneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);

    // Ideal plank has hip and knee alignment ~180° (+/- 20 degrees deviation)
    final isHipAligned = hipAngle > 155.0 && hipAngle < 205.0;
    final isKneeAligned = kneeAngle > 160.0;

    String feedback = "Good plank hold!";
    if (!isHipAligned) {
      feedback = hipAngle < 155.0 ? "Lower your butt!" : "Lift your hips up!";
    } else if (!isKneeAligned) {
      feedback = "Keep your knees locked/straight!";
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: isHipAligned && isKneeAligned,
      progress: 1.0,
    );
  }

  /// Form check for custom recorded movement using recorded joint thresholds.
  static FormFeedback analyzeCustom({
    required Pose pose,
    required Map<String, dynamic> pattern,
    required String currentPhase,
    required double currentExtremeAngle,
    required Function(String nextPhase) onPhaseChanged,
    required Function() onRepCompleted,
  }) {
    final jointStr = pattern['joint'] as String? ?? 'knee';
    final targetMin = (pattern['minAngle'] as num? ?? 90.0).toDouble();
    final targetMax = (pattern['maxAngle'] as num? ?? 160.0).toDouble();

    // Dynamically retrieve landmarks based on primary joint
    PoseLandmark? first, vertex, last;
    if (jointStr == 'elbow') {
      first = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
      vertex = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
      last = pose.landmarks[PoseLandmarkType.leftWrist] ?? pose.landmarks[PoseLandmarkType.rightWrist];
    } else if (jointStr == 'knee') {
      first = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
      vertex = pose.landmarks[PoseLandmarkType.leftKnee] ?? pose.landmarks[PoseLandmarkType.rightKnee];
      last = pose.landmarks[PoseLandmarkType.leftAnkle] ?? pose.landmarks[PoseLandmarkType.rightAnkle];
    } else if (jointStr == 'shoulder') {
      first = pose.landmarks[PoseLandmarkType.leftHip] ?? pose.landmarks[PoseLandmarkType.rightHip];
      vertex = pose.landmarks[PoseLandmarkType.leftShoulder] ?? pose.landmarks[PoseLandmarkType.rightShoulder];
      last = pose.landmarks[PoseLandmarkType.leftElbow] ?? pose.landmarks[PoseLandmarkType.rightElbow];
    }

    if (first == null || vertex == null || last == null) {
      return FormFeedback(message: "Joints not fully in frame", isGoodForm: false, progress: 0.0);
    }

    final angle = calculateAngle(first, vertex, last);
    final midPoint = (targetMin + targetMax) / 2;

    double progress = 0.0;
    String feedback = "Perform custom movement";

    // Track reps by crossing midpoint bounds
    if (currentPhase == 'up') {
      progress = max(0.0, (targetMax - angle) / (targetMax - targetMin));
      if (angle < midPoint) {
        onPhaseChanged('down');
      }
      feedback = "Contract the muscle";
    } else if (currentPhase == 'down') {
      progress = min(1.0, (targetMax - angle) / (targetMax - targetMin));
      if (angle > (targetMax - 10.0)) {
        onPhaseChanged('up');
        // If we flexed deep enough
        if (currentExtremeAngle <= (targetMin + 15.0)) {
          onRepCompleted();
          feedback = "Rep completed!";
        } else {
          feedback = "Fuller range of motion!";
        }
      } else {
        feedback = "Now extend back";
      }
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: true,
      progress: progress.clamp(0.0, 1.0),
    );
  }

  // Fallbacks
  static PoseLandmark ankleOrFallback(PoseLandmark? ankle, Pose pose) {
    if (ankle != null) return ankle;
    return pose.landmarks[PoseLandmarkType.leftKnee]!;
  }
}
