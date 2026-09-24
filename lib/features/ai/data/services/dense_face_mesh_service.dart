import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class FaceMesh {
  final List<Offset> vertices;
  final List<List<int>> triangles;

  const FaceMesh({required this.vertices, required this.triangles});
}

/// Synthesizes a dense, triangulated 3D face mesh covering forehead, cheeks, jaw, nose, eyes, and mouth.
class DenseFaceMeshService {
  DenseFaceMeshService._();

  static FaceMesh? generateFaceMesh(
    Pose pose,
    Size imageSize,
    bool isFrontCamera,
    Size screenSize,
  ) {
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
      final double imageW = imageSize.width > 0
          ? imageSize.width
          : screenSize.width;
      final double imageH = imageSize.height > 0
          ? imageSize.height
          : screenSize.height;

      final double normX = (lx / imageW).clamp(0.0, 1.0);
      final double normY = (ly / imageH).clamp(0.0, 1.0);

      final double x = isFrontCamera
          ? (1.0 - normX) * screenSize.width
          : normX * screenSize.width;
      final double y = normY * screenSize.height;

      return Offset(x, y);
    }

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

    final Offset eyeCenter = Offset(
      (pLeftEye.dx + pRightEye.dx) / 2,
      (pLeftEye.dy + pRightEye.dy) / 2,
    );
    final Offset mouthCenter = Offset(
      (pLeftMouth.dx + pRightMouth.dx) / 2,
      (pLeftMouth.dy + pRightMouth.dy) / 2,
    );

    final double faceWidth = (pRightEar.dx - pLeftEar.dx).abs().clamp(
      40.0,
      420.0,
    );
    final double faceHeight =
        (mouthCenter.dy - eyeCenter.dy).abs().clamp(20.0, 260.0) * 2.2;

    final Offset chin = Offset(pNose.dx, mouthCenter.dy + faceHeight * 0.35);

    // Angle of rotation (roll)
    final double dx = pRightEye.dx - pLeftEye.dx;
    final double dy = pRightEye.dy - pLeftEye.dy;
    final double angle = atan2(dy, dx);
    final double cosA = cos(angle);
    final double sinA = sin(angle);

    Offset computeVertex(double rx, double ry) {
      final double wx = rx * (faceWidth * 0.5);
      final double wy = ry * (faceHeight * 0.5);
      final double rotX = wx * cosA - wy * sinA;
      final double rotY = wx * sinA + wy * cosA;
      return Offset(
        eyeCenter.dx + rotX,
        eyeCenter.dy + faceHeight * 0.15 + rotY,
      );
    }

    final List<Offset> vertices = [];

    // Row 0: Top Forehead Hairline (5 vertices)
    vertices.add(computeVertex(-0.85, -0.95));
    vertices.add(computeVertex(-0.42, -1.05));
    vertices.add(computeVertex(0.0, -1.10));
    vertices.add(computeVertex(0.42, -1.05));
    vertices.add(computeVertex(0.85, -0.95));

    // Row 1: Mid Forehead (5 vertices)
    vertices.add(computeVertex(-0.80, -0.60));
    vertices.add(computeVertex(-0.40, -0.65));
    vertices.add(computeVertex(0.0, -0.68));
    vertices.add(computeVertex(0.40, -0.65));
    vertices.add(computeVertex(0.80, -0.60));

    // Row 2: Eyebrows Line (5 vertices)
    vertices.add(computeVertex(-0.75, -0.25));
    vertices.add(computeVertex(-0.35, -0.28));
    vertices.add(computeVertex(0.0, -0.30));
    vertices.add(computeVertex(0.35, -0.28));
    vertices.add(computeVertex(0.75, -0.25));

    // Row 3: Eyes & Nose Bridge (5 vertices)
    vertices.add(pLeftEar);
    vertices.add(pLeftEye);
    vertices.add(Offset(pNose.dx, pNose.dy - faceHeight * 0.12));
    vertices.add(pRightEye);
    vertices.add(pRightEar);

    // Row 4: Cheeks & Nose Tip (5 vertices)
    vertices.add(computeVertex(-0.85, 0.20));
    vertices.add(computeVertex(-0.45, 0.22));
    vertices.add(pNose);
    vertices.add(computeVertex(0.45, 0.22));
    vertices.add(computeVertex(0.85, 0.20));

    // Row 5: Mouth Line (5 vertices)
    vertices.add(computeVertex(-0.75, 0.55));
    vertices.add(pLeftMouth);
    vertices.add(mouthCenter);
    vertices.add(pRightMouth);
    vertices.add(computeVertex(0.75, 0.55));

    // Row 6: Lower Jaw & Chin (5 vertices)
    vertices.add(computeVertex(-0.65, 0.85));
    vertices.add(computeVertex(-0.35, 0.95));
    vertices.add(chin);
    vertices.add(computeVertex(0.35, 0.95));
    vertices.add(computeVertex(0.65, 0.85));

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
