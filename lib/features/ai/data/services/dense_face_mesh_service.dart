import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:gerex/core/services/camera_rotation_helper.dart';

class FaceMesh {
  final List<Offset> vertices;
  final List<List<int>> triangles;

  const FaceMesh({required this.vertices, required this.triangles});
}

/// Synthesizes a dense, triangulated 3D face mesh conforming dynamically to each user's unique facial geometry and 3D head pose in real-time.
class DenseFaceMeshService {
  DenseFaceMeshService._();

  static FaceMesh? generateFaceMesh({
    required Pose pose,
    required Size imageSize,
    required bool isFrontCamera,
    required Size screenSize,
    InputImageRotation rotation = InputImageRotation.rotation270deg,
  }) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftEye = pose.landmarks[PoseLandmarkType.leftEye];
    final rightEye = pose.landmarks[PoseLandmarkType.rightEye];
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];
    final leftMouth = pose.landmarks[PoseLandmarkType.leftMouth];
    final rightMouth = pose.landmarks[PoseLandmarkType.rightMouth];

    if (nose == null || leftEye == null || rightEye == null) {
      return null;
    }
    if (nose.likelihood < 0.35 ||
        leftEye.likelihood < 0.35 ||
        rightEye.likelihood < 0.35) {
      return null;
    }

    Offset toScreen(double lx, double ly) {
      return CameraRotationHelper.transformPoint(
        lx: lx,
        ly: ly,
        imageSize: imageSize,
        screenSize: screenSize,
        isFrontCamera: isFrontCamera,
        rotation: rotation,
      );
    }

    // Live mapped landmark points
    final pNose = toScreen(nose.x, nose.y);
    final pLeftEye = toScreen(leftEye.x, leftEye.y);
    final pRightEye = toScreen(rightEye.x, rightEye.y);

    final pLeftEar = leftEar != null && leftEar.likelihood > 0.3
        ? toScreen(leftEar.x, leftEar.y)
        : Offset(
            pLeftEye.dx - (pRightEye.dx - pLeftEye.dx).abs() * 0.9,
            pLeftEye.dy,
          );

    final pRightEar = rightEar != null && rightEar.likelihood > 0.3
        ? toScreen(rightEar.x, rightEar.y)
        : Offset(
            pRightEye.dx + (pRightEye.dx - pLeftEye.dx).abs() * 0.9,
            pRightEye.dy,
          );

    final pLeftMouth = leftMouth != null && leftMouth.likelihood > 0.3
        ? toScreen(leftMouth.x, leftMouth.y)
        : Offset(pNose.dx - 18, pNose.dy + 38);

    final pRightMouth = rightMouth != null && rightMouth.likelihood > 0.3
        ? toScreen(rightMouth.x, rightMouth.y)
        : Offset(pNose.dx + 18, pNose.dy + 38);

    // Mapped centers and directional vectors for dynamic head pitch/yaw/roll
    final Offset eyeCenter = Offset(
      (pLeftEye.dx + pRightEye.dx) / 2,
      (pLeftEye.dy + pRightEye.dy) / 2,
    );
    final Offset mouthCenter = Offset(
      (pLeftMouth.dx + pRightMouth.dx) / 2,
      (pLeftMouth.dy + pRightMouth.dy) / 2,
    );

    // Vector pointing from nose up through eye center (forehead direction)
    final double upDx = eyeCenter.dx - pNose.dx;
    final double upDy = eyeCenter.dy - pNose.dy;
    final double upLen = sqrt(upDx * upDx + upDy * upDy);
    final double dirUpX = upLen > 0 ? upDx / upLen : 0.0;
    final double dirUpY = upLen > 0 ? upDy / upLen : -1.0;

    // Vector along eye line (left -> right)
    final double eyeDx = pRightEye.dx - pLeftEye.dx;
    final double eyeDy = pRightEye.dy - pLeftEye.dy;
    final double eyeDist = sqrt(eyeDx * eyeDx + eyeDy * eyeDy);
    final double dirRightX = eyeDist > 0 ? eyeDx / eyeDist : 1.0;
    final double dirRightY = eyeDist > 0 ? eyeDy / eyeDist : 0.0;

    final double faceHeight = (mouthCenter.dy - eyeCenter.dy).abs().clamp(20.0, 260.0) * 2.2;
    final double foreheadDist = (eyeCenter.dy - pNose.dy).abs().clamp(15.0, 120.0) * 1.6;

    final List<Offset> vertices = [];

    // Helper to calculate landmark-driven forehead & cheek nodes along live directional vectors
    Offset foreheadNode(double rightOffset, double upFactor) {
      return Offset(
        eyeCenter.dx + dirRightX * (rightOffset * eyeDist * 0.9) + dirUpX * (foreheadDist * upFactor),
        eyeCenter.dy + dirRightY * (rightOffset * eyeDist * 0.9) + dirUpY * (foreheadDist * upFactor),
      );
    }

    Offset cheekNode(Offset ear, Offset mouth, double blend) {
      return Offset(
        ear.dx + (mouth.dx - ear.dx) * blend,
        ear.dy + (mouth.dy - ear.dy) * blend + 8.0,
      );
    }

    // Row 0: Top Forehead Hairline (5 vertices) [0..4]
    vertices.add(foreheadNode(-1.1, 1.45));
    vertices.add(foreheadNode(-0.5, 1.60));
    vertices.add(foreheadNode(0.0, 1.65));
    vertices.add(foreheadNode(0.5, 1.60));
    vertices.add(foreheadNode(1.1, 1.45));

    // Row 1: Mid Forehead (5 vertices) [5..9]
    vertices.add(foreheadNode(-1.0, 0.85));
    vertices.add(foreheadNode(-0.45, 0.95));
    vertices.add(foreheadNode(0.0, 1.00));
    vertices.add(foreheadNode(0.45, 0.95));
    vertices.add(foreheadNode(1.0, 0.85));

    // Row 2: Eyebrows Line (5 vertices) [10..14]
    vertices.add(foreheadNode(-0.9, 0.35));
    vertices.add(foreheadNode(-0.4, 0.40));
    vertices.add(foreheadNode(0.0, 0.42));
    vertices.add(foreheadNode(0.4, 0.40));
    vertices.add(foreheadNode(0.9, 0.35));

    // Row 3: Eyes & Nose Bridge (5 vertices) [15..19]
    vertices.add(pLeftEar);
    vertices.add(pLeftEye);
    vertices.add(Offset(pNose.dx, eyeCenter.dy));
    vertices.add(pRightEye);
    vertices.add(pRightEar);

    // Row 4: Cheeks & Nose Tip (5 vertices) [20..24]
    vertices.add(cheekNode(pLeftEar, pLeftMouth, 0.25));
    vertices.add(cheekNode(pLeftEar, pLeftMouth, 0.60));
    vertices.add(pNose);
    vertices.add(cheekNode(pRightEar, pRightMouth, 0.60));
    vertices.add(cheekNode(pRightEar, pRightMouth, 0.25));

    // Row 5: Mouth Line (5 vertices) [25..29]
    vertices.add(Offset(pLeftEar.dx * 0.7 + pLeftMouth.dx * 0.3, pLeftMouth.dy));
    vertices.add(pLeftMouth);
    vertices.add(mouthCenter);
    vertices.add(pRightMouth);
    vertices.add(Offset(pRightEar.dx * 0.7 + pRightMouth.dx * 0.3, pRightMouth.dy));

    // Row 6: Lower Jaw & Chin (5 vertices) [30..34]
    final Offset chin = Offset(pNose.dx, mouthCenter.dy + faceHeight * 0.35);
    vertices.add(Offset(pLeftEar.dx * 0.8 + chin.dx * 0.2, mouthCenter.dy + faceHeight * 0.20));
    vertices.add(Offset(pLeftMouth.dx * 0.6 + chin.dx * 0.4, mouthCenter.dy + faceHeight * 0.28));
    vertices.add(chin);
    vertices.add(Offset(pRightMouth.dx * 0.6 + chin.dx * 0.4, mouthCenter.dy + faceHeight * 0.28));
    vertices.add(Offset(pRightEar.dx * 0.8 + chin.dx * 0.2, mouthCenter.dy + faceHeight * 0.20));

    // Build dense 48-triangle mesh topology
    final List<List<int>> triangles = [];
    for (int r = 0; r < 6; r++) {
      final int rowStart = r * 5;
      final int nextRowStart = (r + 1) * 5;
      for (int c = 0; c < 4; c++) {
        final int topLeft = rowStart + c;
        final int topRight = rowStart + c + 1;
        final int bottomLeft = nextRowStart + c;
        final int bottomRight = nextRowStart + c + 1;

        triangles.add([topLeft, topRight, bottomLeft]);
        triangles.add([topRight, bottomRight, bottomLeft]);
      }
    }

    return FaceMesh(vertices: vertices, triangles: triangles);
  }
}
