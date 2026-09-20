// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Find robot bounding boxes in all images', () async {
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
      print('EXAMINING: $filename (${image.width}x${image.height})');
      print('========================================');

      // Let's check vertical projection (non-alpha pixels per X column) to find column gaps!
      List<int> colPixels = List.filled(image.width, 0);
      List<int> rowPixels = List.filled(image.height, 0);

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final int offset = (y * image.width + x) * 4;
          final int alpha = byteData.getUint8(offset + 3);
          if (alpha > 20) {
            colPixels[x]++;
            rowPixels[y]++;
          }
        }
      }

      // Find zero/low alpha columns (gaps between figures)
      List<int> colGaps = [];
      for (int x = 0; x < image.width; x++) {
        if (colPixels[x] == 0) {
          colGaps.add(x);
        }
      }

      // Find zero/low alpha rows (gaps between figure rows)
      List<int> rowGaps = [];
      for (int y = 0; y < image.height; y++) {
        if (rowPixels[y] == 0) {
          rowGaps.add(y);
        }
      }

      print('  Transparent column gaps count: ${colGaps.length}');
      print('  Transparent row gaps count: ${rowGaps.length}');

      // Let's sample 10 points along width and height to see non-alpha distribution
      for (int g = 2; g <= 4; g++) {
        final w = image.width / g;
        print('  If divided into $g columns (width ${w.toStringAsFixed(1)}):');
        for (int c = 0; c < g; c++) {
          final startX = (c * w).toInt();
          final endX = ((c + 1) * w).toInt();
          int count = 0;
          for (int x = startX; x < endX; x++) {
            count += colPixels[x];
          }
          print('    Col $c [$startX..$endX]: $count non-alpha pixels');
        }
      }

      for (int g = 1; g <= 3; g++) {
        final h = image.height / g;
        print('  If divided into $g rows (height ${h.toStringAsFixed(1)}):');
        for (int r = 0; r < g; r++) {
          final startY = (r * h).toInt();
          final endY = ((r + 1) * h).toInt();
          int count = 0;
          for (int y = startY; y < endY; y++) {
            count += rowPixels[y];
          }
          print('    Row $r [$startY..$endY]: $count non-alpha pixels');
        }
      }
    }
  });
}
