// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Find exact grid layout for all 9 sprite sheets', () async {
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

      print('\n----------------------------------------');
      print('FILE: $filename (${image.width}x${image.height})');

      final gridCandidates = [
        {'cols': 1, 'rows': 1, 'count': 1},
        {'cols': 4, 'rows': 1, 'count': 4},
        {'cols': 2, 'rows': 2, 'count': 4},
        {'cols': 3, 'rows': 2, 'count': 6},
        {'cols': 4, 'rows': 2, 'count': 8},
      ];

      for (final cand in gridCandidates) {
        final cols = cand['cols']!;
        final rows = cand['rows']!;
        final frameW = image.width / cols;
        final frameH = image.height / rows;

        List<int> framePixels = [];

        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final startX = (c * frameW).toInt();
            final startY = (r * frameH).toInt();
            final endX = ((c + 1) * frameW).toInt();
            final endY = ((r + 1) * frameH).toInt();

            int px = 0;
            for (int y = startY; y < endY; y++) {
              for (int x = startX; x < endX; x++) {
                final offset = (y * image.width + x) * 4;
                if (byteData.getUint8(offset + 3) > 20) px++;
              }
            }
            framePixels.add(px);
          }
        }

        final mean = framePixels.reduce((a, b) => a + b) / framePixels.length;
        if (mean > 0) {
          final stdDev = List<double>.from(framePixels.map((p) => (p - mean).abs())).reduce((a, b) => a > b ? a : b);
          final stdDevPercent = (stdDev / mean) * 100;

          print('  Grid ${cols}x$rows (${frameW.toInt()}x${frameH.toInt()} per frame): max deviation from mean = ${stdDevPercent.toStringAsFixed(1)}%. Frames pixel counts: $framePixels');
        }
      }
    }
  });
}
