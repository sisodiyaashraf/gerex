// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect all sprite sheet frames for transparency and grid layout', () async {
    final filenames = [
      'gerex_robot_idle.png',
      'gerex_robot_smiling.png',
      'gerex_robot_walking.png',
      'gerex_robot_running.png',
      'gerex_robot_exercise.png',
      'gerex_robot_sweating.png',
      'gerex_robot_sweating_and_tired.png',
      'gerex_robot_tired.png',
      'gerex_robot_pushup.png',
    ];

    for (final filename in filenames) {
      final file = File('assets/images/robot_mascot/$filename');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) continue;

      print('\n========================================');
      print('IMAGE: $filename (${image.width}x${image.height})');
      print('========================================');

      // Test 3x2 grid layout (cols: 3, rows: 2)
      const int numCols = 3;
      const int numRows = 2;
      final double frameW = image.width / numCols;
      final double frameH = image.height / numRows;

      for (int row = 0; row < numRows; row++) {
        for (int col = 0; col < numCols; col++) {
          final int frameIdx = row * numCols + col;
          final int startX = (col * frameW).toInt();
          final int startY = (row * frameH).toInt();
          final int endX = ((col + 1) * frameW).toInt();
          final int endY = ((row + 1) * frameH).toInt();

          int nonAlphaPixels = 0;
          int minX = endX, maxX = startX, minY = endY, maxY = startY;

          for (int y = startY; y < endY; y++) {
            for (int x = startX; x < endX; x++) {
              final int offset = (y * image.width + x) * 4;
              final int alpha = byteData.getUint8(offset + 3);
              if (alpha > 20) {
                nonAlphaPixels++;
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
              }
            }
          }

          final int localMinX = minX - startX;
          final int localMaxX = maxX - startX;
          final int localMinY = minY - startY;
          final int localMaxY = maxY - startY;

          print('  Frame $frameIdx (row $row, col $col): $nonAlphaPixels pixels. Bounds in frame: X=[$localMinX..$localMaxX] / ${frameW.toInt()}, Y=[$localMinY..$localMaxY] / ${frameH.toInt()}');
        }
      }
    }
  });
}
