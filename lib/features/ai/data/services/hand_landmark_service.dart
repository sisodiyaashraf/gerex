import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 21 keypoints standard MediaPipe Hand Landmark indexing:
/// 0: Wrist
/// 1-4: Thumb (CMC, MCP, IP, TIP)
/// 5-8: Index finger (MCP, PIP, DIP, TIP)
/// 9-12: Middle finger (MCP, PIP, DIP, TIP)
/// 13-16: Ring finger (MCP, PIP, DIP, TIP)
/// 17-20: Pinky finger (MCP, PIP, DIP, TIP)
class HandLandmarkPoint {
  final int index;
  final double x;
  final double y;
  final double z;
  final double confidence;

  const HandLandmarkPoint({
    required this.index,
    required this.x,
    required this.y,
    this.z = 0.0,
    this.confidence = 1.0,
  });
}

class HandSkeleton {
  final String side; // 'left' or 'right'
  final List<HandLandmarkPoint> landmarks; // 21 points
  final double confidence;

  HandSkeleton({
    required this.side,
    required this.landmarks,
    this.confidence = 1.0,
  });

  HandLandmarkPoint? get wrist => landmarks.isNotEmpty ? landmarks[0] : null;
  HandLandmarkPoint? get thumbTip => landmarks.length > 4 ? landmarks[4] : null;
  HandLandmarkPoint? get indexTip => landmarks.length > 8 ? landmarks[8] : null;
  HandLandmarkPoint? get middleTip => landmarks.length > 12 ? landmarks[12] : null;
  HandLandmarkPoint? get ringTip => landmarks.length > 16 ? landmarks[16] : null;
  HandLandmarkPoint? get pinkyTip => landmarks.length > 20 ? landmarks[20] : null;

  HandLandmarkPoint? get indexMcp => landmarks.length > 5 ? landmarks[5] : null;
  HandLandmarkPoint? get pinkyMcp => landmarks.length > 17 ? landmarks[17] : null;
}

enum HandGesture {
  none,
  openPalm,
  thumbsUp,
  fist,
  pointing,
}

class HandLandmarkService {
  DateTime? _lastPalmTime;
  DateTime? _lastThumbsUpTime;
  static const int _gestureCooldownMs = 1500;

  /// Infers 21-point detailed hand landmark structure using visible wrist/finger pose landmarks or image heuristics.
  List<HandSkeleton> extractHandsFromPose(Pose pose, Size imageSize) {
    final List<HandSkeleton> result = [];

    // Process Left Hand
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final leftThumb = pose.landmarks[PoseLandmarkType.leftThumb];
    final leftIndex = pose.landmarks[PoseLandmarkType.leftIndex];
    final leftPinky = pose.landmarks[PoseLandmarkType.leftPinky];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];

    if (leftWrist != null && leftWrist.likelihood > 0.4) {
      final hand = _buildHandSkeleton(
        side: 'left',
        wrist: leftWrist,
        thumbTip: leftThumb,
        indexTip: leftIndex,
        pinkyTip: leftPinky,
        elbow: leftElbow,
      );
      if (hand != null) result.add(hand);
    }

    // Process Right Hand
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final rightThumb = pose.landmarks[PoseLandmarkType.rightThumb];
    final rightIndex = pose.landmarks[PoseLandmarkType.rightIndex];
    final rightPinky = pose.landmarks[PoseLandmarkType.rightPinky];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];

    if (rightWrist != null && rightWrist.likelihood > 0.4) {
      final hand = _buildHandSkeleton(
        side: 'right',
        wrist: rightWrist,
        thumbTip: rightThumb,
        indexTip: rightIndex,
        pinkyTip: rightPinky,
        elbow: rightElbow,
      );
      if (hand != null) result.add(hand);
    }

    return result;
  }

  /// Synthesizes full 21 hand landmarks based on wrist and finger anchors.
  HandSkeleton? _buildHandSkeleton({
    required String side,
    required PoseLandmark wrist,
    required PoseLandmark? thumbTip,
    required PoseLandmark? indexTip,
    required PoseLandmark? pinkyTip,
    required PoseLandmark? elbow,
  }) {
    final double wx = wrist.x;
    final double wy = wrist.y;

    // Calculate forearm directional vector for orientation reference
    double dx = 0.0;
    double dy = -1.0;
    if (elbow != null) {
      dx = wx - elbow.x;
      dy = wy - elbow.y;
      final double len = sqrt(dx * dx + dy * dy);
      if (len > 0) {
        dx /= len;
        dy /= len;
      }
    }

    // Perpendicular vector for palm spread width
    final double px = -dy * (side == 'left' ? -1 : 1);
    final double py = dx * (side == 'left' ? -1 : 1);

    const double handScale = 45.0;
    final List<HandLandmarkPoint> points = List.filled(
      21,
      HandLandmarkPoint(index: 0, x: wx, y: wy),
    );

    // 0: Wrist
    points[0] = HandLandmarkPoint(index: 0, x: wx, y: wy, confidence: wrist.likelihood);

    // 1-4: Thumb
    final double tx = thumbTip != null && thumbTip.likelihood > 0.4
        ? thumbTip.x
        : wx + px * handScale * 0.7 - dx * handScale * 0.3;
    final double ty = thumbTip != null && thumbTip.likelihood > 0.4
        ? thumbTip.y
        : wy + py * handScale * 0.7 - dy * handScale * 0.3;

    for (int i = 1; i <= 4; i++) {
      final double t = i / 4.0;
      points[i] = HandLandmarkPoint(
        index: i,
        x: wx + (tx - wx) * t,
        y: wy + (ty - wy) * t,
      );
    }

    // Finger vectors relative to wrist
    _buildFingerPoints(points, 5, wx, wy, dx + px * 0.35, dy + py * 0.35, handScale * 1.1, indexTip);
    _buildFingerPoints(points, 9, wx, wy, dx, dy, handScale * 1.25, null);
    _buildFingerPoints(points, 13, wx, wy, dx - px * 0.3, dy - py * 0.3, handScale * 1.15, null);
    _buildFingerPoints(points, 17, wx, wy, dx - px * 0.6, dy - py * 0.6, handScale * 0.95, pinkyTip);

    return HandSkeleton(side: side, landmarks: points, confidence: wrist.likelihood);
  }

  void _buildFingerPoints(
    List<HandLandmarkPoint> points,
    int baseIndex,
    double wx,
    double wy,
    double dirX,
    double dirY,
    double length,
    PoseLandmark? customTip,
  ) {
    final double targetX = customTip != null && customTip.likelihood > 0.4
        ? customTip.x
        : wx + dirX * length;
    final double targetY = customTip != null && customTip.likelihood > 0.4
        ? customTip.y
        : wy + dirY * length;

    for (int i = 0; i < 4; i++) {
      final double t = (i + 1) / 4.0;
      points[baseIndex + i] = HandLandmarkPoint(
        index: baseIndex + i,
        x: wx + (targetX - wx) * t,
        y: wy + (targetY - wy) * t,
      );
    }
  }

  /// Classifies gestures from hand landmarks.
  HandGesture detectGesture(HandSkeleton hand) {
    if (hand.landmarks.length < 21) return HandGesture.none;

    final wrist = hand.wrist!;
    final thumbTip = hand.thumbTip!;
    final indexTip = hand.indexTip!;
    final middleTip = hand.middleTip!;
    final ringTip = hand.ringTip!;
    final pinkyTip = hand.pinkyTip!;

    final indexMcp = hand.indexMcp!;
    final pinkyMcp = hand.pinkyMcp!;

    // Distances from wrist
    final double distThumb = _dist(wrist, thumbTip);
    final double distIndex = _dist(wrist, indexTip);
    final double distMiddle = _dist(wrist, middleTip);
    final double distRing = _dist(wrist, ringTip);
    final double distPinky = _dist(wrist, pinkyTip);

    final double distIndexMcp = _dist(wrist, indexMcp);
    final double distPinkyMcp = _dist(wrist, pinkyMcp);

    // 1. Thumbs Up gesture check: thumb pointing up (-y in screen space) while other fingers are curled
    bool isThumbExtendedUp = (thumbTip.y < wrist.y - 25.0) && (distThumb > distIndex);
    bool areOtherFingersCurled = (distIndex < distIndexMcp * 1.4) &&
        (distMiddle < distIndexMcp * 1.4) &&
        (distRing < distPinkyMcp * 1.4) &&
        (distPinky < distPinkyMcp * 1.4);

    if (isThumbExtendedUp && areOtherFingersCurled) {
      final now = DateTime.now();
      if (_lastThumbsUpTime == null || now.difference(_lastThumbsUpTime!).inMilliseconds > _gestureCooldownMs) {
        _lastThumbsUpTime = now;
        return HandGesture.thumbsUp;
      }
    }

    // 2. Open Palm gesture check: all fingers extended far from wrist
    bool isOpenPalm = distThumb > 35 &&
        distIndex > distIndexMcp * 1.5 &&
        distMiddle > distIndexMcp * 1.6 &&
        distRing > distPinkyMcp * 1.5 &&
        distPinky > distPinkyMcp * 1.4;

    if (isOpenPalm) {
      final now = DateTime.now();
      if (_lastPalmTime == null || now.difference(_lastPalmTime!).inMilliseconds > _gestureCooldownMs) {
        _lastPalmTime = now;
        return HandGesture.openPalm;
      }
    }

    return HandGesture.none;
  }

  /// Calculates wrist rotation angle relative to forearm for form check cues.
  double getWristRotationAngle(HandSkeleton hand, PoseLandmark? elbow) {
    if (hand.landmarks.length < 21 || hand.wrist == null || elbow == null) return 0.0;

    final wrist = hand.wrist!;
    final indexMcp = hand.indexMcp!;

    // Vector along forearm (elbow -> wrist)
    final double armX = wrist.x - elbow.x;
    final double armY = wrist.y - elbow.y;

    // Vector along hand (wrist -> index mcp)
    final double handX = indexMcp.x - wrist.x;
    final double handY = indexMcp.y - wrist.y;

    final double dot = armX * handX + armY * handY;
    final double magArm = sqrt(armX * armX + armY * armY);
    final double magHand = sqrt(handX * handX + handY * handY);

    if (magArm * magHand == 0) return 0.0;
    double cosVal = (dot / (magArm * magHand)).clamp(-1.0, 1.0);
    return acos(cosVal) * 180.0 / pi;
  }

  double _dist(HandLandmarkPoint a, HandLandmarkPoint b) {
    final double dx = a.x - b.x;
    final double dy = a.y - b.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Generates demo hands for simulation mode.
  List<HandSkeleton> generateSimulationHands(Size centerOffset, bool showPalmGesture, bool showThumbsUp) {
    final double cx = centerOffset.width;
    final double cy = centerOffset.height;

    final List<HandLandmarkPoint> points = List.generate(21, (i) {
      if (i == 0) return HandLandmarkPoint(index: 0, x: cx, y: cy);
      if (showThumbsUp) {
        if (i <= 4) return HandLandmarkPoint(index: i, x: cx - 15 - (i * 5), y: cy - 20 - (i * 8));
        return HandLandmarkPoint(index: i, x: cx + (i % 4) * 8, y: cy + 10);
      }
      if (showPalmGesture) {
        final double angle = -pi / 2 + ((i - 10) * 0.15);
        final double dist = 25.0 + (i % 5) * 10;
        return HandLandmarkPoint(index: i, x: cx + cos(angle) * dist, y: cy + sin(angle) * dist);
      }
      // Normal hand position during exercise
      return HandLandmarkPoint(index: i, x: cx + (i - 10) * 4, y: cy - (i % 5) * 8);
    });

    return [HandSkeleton(side: 'right', landmarks: points)];
  }
}
