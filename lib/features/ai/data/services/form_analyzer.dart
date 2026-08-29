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

  /// Confidence threshold helper to discard weak landmark detections.
  static PoseLandmark? getValidLandmark(Pose pose, PoseLandmarkType type, {double threshold = 0.55}) {
    final landmark = pose.landmarks[type];
    if (landmark == null || landmark.likelihood < threshold) {
      return null;
    }
    return landmark;
  }

  /// Calculates the 3D angle (in degrees) at the vertex joint between first and last points.
  static double calculateAngle(PoseLandmark first, PoseLandmark vertex, PoseLandmark last) {
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

  /// Checks if key landmarks are visible with high confidence.
  static bool isFullyTracked(Pose pose, String exercise) {
    const double threshold = 0.55;
    
    bool hasLeftLower = getValidLandmark(pose, PoseLandmarkType.leftHip, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.leftKnee, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.leftAnkle, threshold: threshold) != null;
        
    bool hasRightLower = getValidLandmark(pose, PoseLandmarkType.rightHip, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.rightKnee, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.rightAnkle, threshold: threshold) != null;
        
    bool hasLeftUpper = getValidLandmark(pose, PoseLandmarkType.leftShoulder, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.leftElbow, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.leftWrist, threshold: threshold) != null;

    bool hasRightUpper = getValidLandmark(pose, PoseLandmarkType.rightShoulder, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.rightElbow, threshold: threshold) != null &&
        getValidLandmark(pose, PoseLandmarkType.rightWrist, threshold: threshold) != null;

    if (exercise == 'Squat') {
      bool leftOk = hasLeftLower && getValidLandmark(pose, PoseLandmarkType.leftShoulder, threshold: threshold) != null;
      bool rightOk = hasRightLower && getValidLandmark(pose, PoseLandmarkType.rightShoulder, threshold: threshold) != null;
      return leftOk || rightOk;
    } else if (exercise == 'Push-Up') {
      bool leftOk = hasLeftUpper && getValidLandmark(pose, PoseLandmarkType.leftHip, threshold: threshold) != null && getValidLandmark(pose, PoseLandmarkType.leftKnee, threshold: threshold) != null;
      bool rightOk = hasRightUpper && getValidLandmark(pose, PoseLandmarkType.rightHip, threshold: threshold) != null && getValidLandmark(pose, PoseLandmarkType.rightKnee, threshold: threshold) != null;
      return leftOk || rightOk;
    } else if (exercise == 'Jumping Jack') {
      return (getValidLandmark(pose, PoseLandmarkType.leftShoulder, threshold: threshold) != null &&
          getValidLandmark(pose, PoseLandmarkType.leftElbow, threshold: threshold) != null &&
          getValidLandmark(pose, PoseLandmarkType.leftHip, threshold: threshold) != null &&
          getValidLandmark(pose, PoseLandmarkType.leftKnee, threshold: threshold) != null) ||
          (getValidLandmark(pose, PoseLandmarkType.rightShoulder, threshold: threshold) != null &&
          getValidLandmark(pose, PoseLandmarkType.rightElbow, threshold: threshold) != null &&
          getValidLandmark(pose, PoseLandmarkType.rightHip, threshold: threshold) != null &&
          getValidLandmark(pose, PoseLandmarkType.rightKnee, threshold: threshold) != null);
    } else {
      bool leftOk = hasLeftLower && getValidLandmark(pose, PoseLandmarkType.leftShoulder, threshold: threshold) != null;
      bool rightOk = hasRightLower && getValidLandmark(pose, PoseLandmarkType.rightShoulder, threshold: threshold) != null;
      return leftOk || rightOk;
    }
  }

  /// Analyzes the pose and returns feedback based on squat performance.
  static FormFeedback analyzeSquat({
    required Pose pose,
    required String currentPhase, // 'up' or 'down'
    required double maxKneeFlexion, // track deepest point in current rep
    required Function(String nextPhase) onPhaseChanged,
    required Function() onRepCompleted,
  }) {
    // Dynamic side selection based on visibility
    final leftHip = getValidLandmark(pose, PoseLandmarkType.leftHip);
    final leftKnee = getValidLandmark(pose, PoseLandmarkType.leftKnee);
    final leftAnkle = getValidLandmark(pose, PoseLandmarkType.leftAnkle);
    final rightHip = getValidLandmark(pose, PoseLandmarkType.rightHip);
    final rightKnee = getValidLandmark(pose, PoseLandmarkType.rightKnee);
    final rightAnkle = getValidLandmark(pose, PoseLandmarkType.rightAnkle);

    final bool useLeft = (leftHip != null && leftKnee != null) &&
        (rightHip == null || rightKnee == null || (leftHip.likelihood > rightHip.likelihood));

    final hip = useLeft ? leftHip : rightHip;
    final knee = useLeft ? leftKnee : rightKnee;
    final ankle = useLeft ? leftAnkle : rightAnkle;
    final shoulder = useLeft ? getValidLandmark(pose, PoseLandmarkType.leftShoulder) : getValidLandmark(pose, PoseLandmarkType.rightShoulder);

    if (hip == null || knee == null || ankle == null) {
      return FormFeedback(message: "Stand sideways to show full profile", isGoodForm: false, progress: 0.0);
    }

    final kneeAngle = calculateAngle(hip, knee, ankle);
    final spineLean = shoulder != null ? calculateLeanAngle(shoulder, hip) : 0.0;

    // Face/Head Check
    final nose = getValidLandmark(pose, PoseLandmarkType.nose);
    bool isHeadNeutral = true;
    String headWarning = "";
    if (nose != null && shoulder != null) {
      if (nose.y > shoulder.y) {
        isHeadNeutral = false;
        headWarning = "Look straight, do not look down!";
      }
    }

    // Legs Check (Feet width)
    bool isLegsAligned = true;
    String legWarning = "";
    final leftAnkVal = getValidLandmark(pose, PoseLandmarkType.leftAnkle);
    final rightAnkVal = getValidLandmark(pose, PoseLandmarkType.rightAnkle);
    final leftHipVal = getValidLandmark(pose, PoseLandmarkType.leftHip);
    final rightHipVal = getValidLandmark(pose, PoseLandmarkType.rightHip);
    if (leftAnkVal != null && rightAnkVal != null && leftHipVal != null && rightHipVal != null) {
      final hipDist = (leftHipVal.x - rightHipVal.x).abs();
      final ankleDist = (leftAnkVal.x - rightAnkVal.x).abs();
      if (ankleDist < hipDist * 0.9) {
        isLegsAligned = false;
        legWarning = "Widen stance to shoulder width!";
      }
    }

    // Hands Check
    bool isHandsAligned = true;
    String handWarning = "";
    final leftWrist = getValidLandmark(pose, PoseLandmarkType.leftWrist);
    final rightWrist = getValidLandmark(pose, PoseLandmarkType.rightWrist);
    if (leftWrist != null && rightWrist != null) {
      if (leftWrist.y > hip.y && rightWrist.y > hip.y) {
        isHandsAligned = false;
        handWarning = "Raise arms for balance!";
      }
    }

    bool isGoodSpine = spineLean < 35.0;
    
    String feedback = "Squat down smoothly";
    if (!isGoodSpine) {
      feedback = "Keep your back straight!";
    } else if (!isHeadNeutral) {
      feedback = headWarning;
    } else if (!isLegsAligned) {
      feedback = legWarning;
    } else if (!isHandsAligned) {
      feedback = handWarning;
    }

    double progress = 0.0;
    if (currentPhase == 'up') {
      progress = max(0.0, (170.0 - kneeAngle) / 80.0);
      if (kneeAngle < 120.0) {
        onPhaseChanged('down');
      }
    } else if (currentPhase == 'down') {
      progress = min(1.0, (170.0 - kneeAngle) / 80.0);
      if (kneeAngle > 155.0) {
        onPhaseChanged('up');
        if (maxKneeFlexion < 110.0) {
          onRepCompleted();
          feedback = "Excellent squat!";
        } else {
          feedback = "Squat deeper next time!";
        }
      } else {
        if (feedback == "Squat down smoothly") {
          feedback = kneeAngle < 100.0
              ? "Good depth! Drive back up"
              : "Lower your hips below parallel";
        }
      }
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: isGoodSpine && isHeadNeutral && isLegsAligned && isHandsAligned && (kneeAngle < 110.0 || currentPhase == 'up'),
      progress: progress.clamp(0.0, 1.0),
    );
  }

  /// Analyzes the pose and returns feedback based on pushup performance.
  static FormFeedback analyzePushUp({
    required Pose pose,
    required String currentPhase, // 'up' or 'down'
    required double maxElbowFlexion,
    required Function(String nextPhase) onPhaseChanged,
    required Function() onRepCompleted,
  }) {
    // Dynamic side selection
    final leftShoulder = getValidLandmark(pose, PoseLandmarkType.leftShoulder);
    final leftElbow = getValidLandmark(pose, PoseLandmarkType.leftElbow);
    final leftWrist = getValidLandmark(pose, PoseLandmarkType.leftWrist);
    final leftHip = getValidLandmark(pose, PoseLandmarkType.leftHip);
    final leftKnee = getValidLandmark(pose, PoseLandmarkType.leftKnee);

    final rightShoulder = getValidLandmark(pose, PoseLandmarkType.rightShoulder);
    final rightElbow = getValidLandmark(pose, PoseLandmarkType.rightElbow);
    final rightWrist = getValidLandmark(pose, PoseLandmarkType.rightWrist);
    final rightHip = getValidLandmark(pose, PoseLandmarkType.rightHip);
    final rightKnee = getValidLandmark(pose, PoseLandmarkType.rightKnee);

    final bool useLeft = (leftShoulder != null && leftElbow != null && leftWrist != null) &&
        (rightShoulder == null || rightElbow == null || rightWrist == null || (leftShoulder.likelihood > rightShoulder.likelihood));

    final shoulder = useLeft ? leftShoulder : rightShoulder;
    final elbow = useLeft ? leftElbow : rightElbow;
    final wrist = useLeft ? leftWrist : rightWrist;
    final hip = useLeft ? leftHip : rightHip;
    final knee = useLeft ? leftKnee : rightKnee;

    if (shoulder == null || elbow == null || wrist == null) {
      return FormFeedback(message: "Position full upper body in frame", isGoodForm: false, progress: 0.0);
    }

    final elbowAngle = calculateAngle(shoulder, elbow, wrist);

    // Spine/Hip check
    double hipAngle = 180.0;
    if (hip != null && knee != null) {
      hipAngle = calculateAngle(shoulder, hip, knee);
    }
    final isStraightSpine = hipAngle > 155.0 && hipAngle < 195.0;

    // Face Check
    final nose = getValidLandmark(pose, PoseLandmarkType.nose);
    bool isHeadNeutral = true;
    String headWarning = "";
    if (nose != null) {
      if (nose.y > shoulder.y + 30) {
        isHeadNeutral = false;
        headWarning = "Keep your head up, aligned with spine!";
      }
    }

    // Hands Placement Check
    bool isHandsAligned = true;
    String handWarning = "";
    final leftWristVal = getValidLandmark(pose, PoseLandmarkType.leftWrist);
    final rightWristVal = getValidLandmark(pose, PoseLandmarkType.rightWrist);
    final leftShoulderVal = getValidLandmark(pose, PoseLandmarkType.leftShoulder);
    final rightShoulderVal = getValidLandmark(pose, PoseLandmarkType.rightShoulder);
    if (leftWristVal != null && rightWristVal != null && leftShoulderVal != null && rightShoulderVal != null) {
      final shoulderDist = (leftShoulderVal.x - rightShoulderVal.x).abs();
      final wristDist = (leftWristVal.x - rightWristVal.x).abs();
      if (wristDist > shoulderDist * 1.6) {
        isHandsAligned = false;
        handWarning = "Bring hands closer under shoulders!";
      }
    }

    // Legs Check (Locked knees)
    bool isLegsAligned = true;
    String legWarning = "";
    final ankle = useLeft ? getValidLandmark(pose, PoseLandmarkType.leftAnkle) : getValidLandmark(pose, PoseLandmarkType.rightAnkle);
    if (hip != null && knee != null && ankle != null) {
      final kneeAngle = calculateAngle(hip, knee, ankle);
      if (kneeAngle < 160.0) {
        isLegsAligned = false;
        legWarning = "Lock your knees straight!";
      }
    }

    String feedback = "Lower your body";
    if (!isStraightSpine) {
      feedback = "Don't sag your hips!";
    } else if (!isHeadNeutral) {
      feedback = headWarning;
    } else if (!isHandsAligned) {
      feedback = handWarning;
    } else if (!isLegsAligned) {
      feedback = legWarning;
    }

    double progress = 0.0;
    if (currentPhase == 'up') {
      progress = max(0.0, (160.0 - elbowAngle) / 75.0);
      if (elbowAngle < 115.0) {
        onPhaseChanged('down');
      }
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
        if (feedback == "Lower your body") {
          feedback = elbowAngle < 95.0 ? "Great depth! Push up" : "Lower your chest more";
        }
      }
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: isStraightSpine && isHeadNeutral && isHandsAligned && isLegsAligned && (elbowAngle < 100.0 || currentPhase == 'up'),
      progress: progress.clamp(0.0, 1.0),
    );
  }

  /// Analyzes the pose and returns feedback based on jumping jack performance.
  static FormFeedback analyzeJumpingJack({
    required Pose pose,
    required String currentPhase,
    required Function(String nextPhase) onPhaseChanged,
    required Function() onRepCompleted,
  }) {
    final leftShoulder = getValidLandmark(pose, PoseLandmarkType.leftShoulder);
    final leftElbow = getValidLandmark(pose, PoseLandmarkType.leftElbow);
    final leftHip = getValidLandmark(pose, PoseLandmarkType.leftHip);
    final leftKnee = getValidLandmark(pose, PoseLandmarkType.leftKnee);

    if (leftShoulder == null || leftHip == null || leftElbow == null) {
      return FormFeedback(message: "Stand fully in frame", isGoodForm: false, progress: 0.0);
    }

    final armAngle = calculateAngle(leftHip, leftShoulder, leftElbow);
    
    final rightHip = getValidLandmark(pose, PoseLandmarkType.rightHip);
    final rightKnee = getValidLandmark(pose, PoseLandmarkType.rightKnee);
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

  /// Analyzes the pose and returns feedback based on plank performance.
  static FormFeedback analyzePlank({
    required Pose pose,
  }) {
    // Dynamic side selection
    final leftShoulder = getValidLandmark(pose, PoseLandmarkType.leftShoulder);
    final leftHip = getValidLandmark(pose, PoseLandmarkType.leftHip);
    final leftKnee = getValidLandmark(pose, PoseLandmarkType.leftKnee);
    final leftAnkle = getValidLandmark(pose, PoseLandmarkType.leftAnkle);

    final rightShoulder = getValidLandmark(pose, PoseLandmarkType.rightShoulder);
    final rightHip = getValidLandmark(pose, PoseLandmarkType.rightHip);
    final rightKnee = getValidLandmark(pose, PoseLandmarkType.rightKnee);
    final rightAnkle = getValidLandmark(pose, PoseLandmarkType.rightAnkle);

    final bool useLeft = (leftShoulder != null && leftHip != null && leftKnee != null && leftAnkle != null) &&
        (rightShoulder == null || rightHip == null || rightKnee == null || rightAnkle == null || (leftShoulder.likelihood > rightShoulder.likelihood));

    final shoulder = useLeft ? leftShoulder : rightShoulder;
    final hip = useLeft ? leftHip : rightHip;
    final knee = useLeft ? leftKnee : rightKnee;
    final ankle = useLeft ? leftAnkle : rightAnkle;

    if (shoulder == null || hip == null || knee == null || ankle == null) {
      return FormFeedback(message: "Show side profile in frame", isGoodForm: false, progress: 0.0);
    }

    final hipAngle = calculateAngle(shoulder, hip, knee);
    final kneeAngle = calculateAngle(hip, knee, ankle);

    // Face check
    final nose = getValidLandmark(pose, PoseLandmarkType.nose);
    bool isHeadNeutral = true;
    String headWarning = "";
    if (nose != null) {
      if (nose.y > shoulder.y + 35) {
        isHeadNeutral = false;
        headWarning = "Keep head aligned, don't drop neck!";
      }
    }

    // Hip check
    final isHipAligned = hipAngle > 155.0 && hipAngle < 205.0;

    // Knee check
    final isKneeAligned = kneeAngle > 160.0;

    // Elbow check (directly under shoulders)
    final elbow = useLeft ? getValidLandmark(pose, PoseLandmarkType.leftElbow) : getValidLandmark(pose, PoseLandmarkType.rightElbow);
    bool isElbowAligned = true;
    String elbowWarning = "";
    if (elbow != null) {
      final dx = (elbow.x - shoulder.x).abs();
      if (dx > 70) {
        isElbowAligned = false;
        elbowWarning = "Elbows should be directly under shoulders!";
      }
    }

    String feedback = "Good plank hold!";
    if (!isHipAligned) {
      feedback = hipAngle < 155.0 ? "Lower your butt!" : "Lift your hips up!";
    } else if (!isHeadNeutral) {
      feedback = headWarning;
    } else if (!isKneeAligned) {
      feedback = "Keep your knees locked straight!";
    } else if (!isElbowAligned) {
      feedback = elbowWarning;
    }

    return FormFeedback(
      message: feedback,
      isGoodForm: isHipAligned && isKneeAligned && isHeadNeutral && isElbowAligned,
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

    PoseLandmark? first, vertex, last;
    if (jointStr == 'elbow') {
      first = getValidLandmark(pose, PoseLandmarkType.leftShoulder) ?? getValidLandmark(pose, PoseLandmarkType.rightShoulder);
      vertex = getValidLandmark(pose, PoseLandmarkType.leftElbow) ?? getValidLandmark(pose, PoseLandmarkType.rightElbow);
      last = getValidLandmark(pose, PoseLandmarkType.leftWrist) ?? getValidLandmark(pose, PoseLandmarkType.rightWrist);
    } else if (jointStr == 'knee') {
      first = getValidLandmark(pose, PoseLandmarkType.leftHip) ?? getValidLandmark(pose, PoseLandmarkType.rightHip);
      vertex = getValidLandmark(pose, PoseLandmarkType.leftKnee) ?? getValidLandmark(pose, PoseLandmarkType.rightKnee);
      last = getValidLandmark(pose, PoseLandmarkType.leftAnkle) ?? getValidLandmark(pose, PoseLandmarkType.rightAnkle);
    } else if (jointStr == 'shoulder') {
      first = getValidLandmark(pose, PoseLandmarkType.leftHip) ?? getValidLandmark(pose, PoseLandmarkType.rightHip);
      vertex = getValidLandmark(pose, PoseLandmarkType.leftShoulder) ?? getValidLandmark(pose, PoseLandmarkType.rightShoulder);
      last = getValidLandmark(pose, PoseLandmarkType.leftElbow) ?? getValidLandmark(pose, PoseLandmarkType.rightElbow);
    }

    if (first == null || vertex == null || last == null) {
      return FormFeedback(message: "Joints not fully in frame", isGoodForm: false, progress: 0.0);
    }

    final angle = calculateAngle(first, vertex, last);
    final midPoint = (targetMin + targetMax) / 2;

    double progress = 0.0;
    String feedback = "Perform custom movement";

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
}
