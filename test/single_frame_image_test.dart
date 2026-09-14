import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final configs = [
    {'file': 'gerex_robot_idle.png', 'cols': 2, 'rows': 2, 'frames': 4},
    {'file': 'gerex_robot_running.png', 'cols': 4, 'rows': 2, 'frames': 8},
    {'file': 'gerex_robot_walking.png', 'cols': 4, 'rows': 2, 'frames': 8},
    {'file': 'gerex_robot_smiling.png', 'cols': 4, 'rows': 2, 'frames': 8},
    {'file': 'gerex_robot_exercise.png', 'cols': 4, 'rows': 2, 'frames': 8},
    {'file': 'gerex_robot_sweating.png', 'cols': 4, 'rows': 2, 'frames': 8},
    {'file': 'gerex_robot_sweating_and_tired.png', 'cols': 4, 'rows': 2, 'frames': 8},
    {'file': 'gerex_robot_tired.png', 'cols': 4, 'rows': 2, 'frames': 8},
  ];

  for (final cfg in configs) {
    final filename = cfg['file'] as String;
    final cols = cfg['cols'] as int;
    final rows = cfg['rows'] as int;
    final totalFrames = cfg['frames'] as int;

    test('Detailed frame inspection for $filename ($cols x $rows)', () async {
      final file = File('assets/images/robot_mascot/$filename');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = byteData!.buffer.asUint8List();

      final frameW = width / cols;
      final frameH = height / rows;

      print('=== $filename ($width x $height), frame size: ${frameW.toStringAsFixed(1)} x ${frameH.toStringAsFixed(1)} ===');

      for (int i = 0; i < totalFrames; i++) {
        final col = i % cols;
        final row = i ~/ cols;

        final startX = (col * frameW).toInt();
        final endX = ((col + 1) * frameW).toInt();
        final startY = (row * frameH).toInt();
        final endY = ((row + 1) * frameH).toInt();

        // Find bounding box of non-transparent pixels inside this frame rect
        int minX = endX, maxX = startX, minY = endY, maxY = startY;
        int nonZeroPixels = 0;

        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            final offset = (y * width + x) * 4;
            final alpha = rgba[offset + 3];
            if (alpha > 30) {
              nonZeroPixels++;
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }

        if (nonZeroPixels > 0) {
          final relMinX = minX - startX;
          final relMaxX = maxX - startX;
          final relMinY = minY - startY;
          final relMaxY = maxY - startY;
          final contentW = relMaxX - relMinX + 1;
          final contentH = relMaxY - relMinY + 1;

          print('Frame $i (col $col, row $row): pixels=$nonZeroPixels, bbox: left=$relMinX top=$relMinY right=$relMaxX bottom=$relMaxY (size: ${contentW}x$contentH in frame ${frameW.toInt()}x${frameH.toInt()})');
        } else {
          print('Frame $i (col $col, row $row): EMPTY');
        }
      }
    });
  }
}
