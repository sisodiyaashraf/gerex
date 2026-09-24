import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Single unified utility for computing camera input image rotation and mapping 2D landmark coordinates to screen canvas space.
class CameraRotationHelper {
  CameraRotationHelper._();

  /// Computes ML Kit InputImageRotation from CameraDescription.
  static InputImageRotation computeInputImageRotation(CameraDescription? camera) {
    if (camera == null) return InputImageRotation.rotation270deg;
    final sensorOrientation = camera.sensorOrientation;
    final int rotationCompensation = sensorOrientation % 360;
    return InputImageRotationValue.fromRawValue(rotationCompensation) ??
        InputImageRotation.rotation270deg;
  }

  /// Transforms ML Kit landmark coordinates (lx, ly) in image space to display canvas coordinates Offset(x, y).
  static Offset transformPoint({
    required double lx,
    required double ly,
    required Size imageSize,
    required Size screenSize,
    required bool isFrontCamera,
    InputImageRotation rotation = InputImageRotation.rotation270deg,
  }) {
    final double imageW = imageSize.width > 0 ? imageSize.width : screenSize.width;
    final double imageH = imageSize.height > 0 ? imageSize.height : screenSize.height;

    final double normX = (lx / imageW).clamp(0.0, 1.0);
    final double normY = (ly / imageH).clamp(0.0, 1.0);

    double x;
    double y;

    switch (rotation) {
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        x = isFrontCamera ? (1.0 - normY) * screenSize.width : normY * screenSize.width;
        y = normX * screenSize.height;
        break;
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
      default:
        x = isFrontCamera ? (1.0 - normX) * screenSize.width : normX * screenSize.width;
        y = normY * screenSize.height;
        break;
    }

    return Offset(x, y);
  }
}
