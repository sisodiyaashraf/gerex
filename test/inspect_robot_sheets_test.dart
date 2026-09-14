import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final assetFiles = [
    'gerex_robot_idle.png',
    'gerex_robot_exercise.png',
    'gerex_robot_running.png',
    'gerex_robot_smiling.png',
    'gerex_robot_sweating.png',
    'gerex_robot_sweating_and_tired.png',
    'gerex_robot_tired.png',
    'gerex_robot_walking.png',
  ];

  for (final filename in assetFiles) {
    test('Analyze PNG layout for $filename', () async {
      final file = File('assets/images/robot_mascot/$filename');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = byteData!.buffer.asUint8List();

      print('=== $filename ($width x $height) ===');

      // Test different grid divisions: 1x1, 2x1, 4x1, 2x2, 4x2, 8x1, 1x8
      for (final grid in [
        [1, 1],
        [2, 1],
        [4, 1],
        [2, 2],
        [4, 2],
        [8, 1],
        [1, 8]
      ]) {
        final cols = grid[0];
        final rows = grid[1];
        final cellW = width / cols;
        final cellH = height / rows;

        int activeCells = 0;
        final cellCounts = <int>[];

        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            // Count non-transparent pixels in cell (col c, row r)
            int nonAlpha = 0;
            final startX = (c * cellW).toInt();
            final endX = ((c + 1) * cellW).toInt();
            final startY = (r * cellH).toInt();
            final endY = ((r + 1) * cellH).toInt();

            // Sample every 4th pixel for speed
            for (int y = startY; y < endY; y += 4) {
              for (int x = startX; x < endX; x += 4) {
                final offset = (y * width + x) * 4;
                final alpha = rgba[offset + 3];
                if (alpha > 30) {
                  nonAlpha++;
                }
              }
            }
            if (nonAlpha > 50) activeCells++;
            cellCounts.add(nonAlpha);
          }
        }

        print('Grid ${cols}x$rows: $activeCells active cells / ${cols * rows}. Counts per cell: $cellCounts');
      }
    });
  }
}
