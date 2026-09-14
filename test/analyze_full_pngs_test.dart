import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final files = [
    'gerex_robot_idle.png',
    'gerex_robot_exercise.png',
    'gerex_robot_running.png',
    'gerex_robot_smiling.png',
    'gerex_robot_sweating.png',
    'gerex_robot_sweating_and_tired.png',
    'gerex_robot_tired.png',
    'gerex_robot_walking.png',
  ];

  for (final filename in files) {
    test('Analyze connected components / figures in $filename', () async {
      final file = File('assets/images/robot_mascot/$filename');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = byteData!.buffer.asUint8List();

      print('\n========================================');
      print('FILE: $filename ($width x $height)');
      print('========================================');

      // Check horizontal density profile (y-axis slice density across height)
      final rowDensity = List<int>.filled(height, 0);
      final colDensity = List<int>.filled(width, 0);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final alpha = rgba[(y * width + x) * 4 + 3];
          if (alpha > 30) {
            rowDensity[y]++;
            colDensity[x]++;
          }
        }
      }

      // Find vertical gaps (empty rows) to determine if image has stacked rows of robots
      final emptyRows = <int>[];
      for (int y = 0; y < height; y++) {
        if (rowDensity[y] == 0) emptyRows.add(y);
      }

      // Find vertical gaps in col density
      final emptyCols = <int>[];
      for (int x = 0; x < width; x++) {
        if (colDensity[x] == 0) emptyCols.add(x);
      }

      print('Empty row ranges (vertical gaps):');
      _printRanges(emptyRows, height);

      print('Empty col ranges (horizontal gaps):');
      _printRanges(emptyCols, width);

      // Now check if horizontal slicing into N frames (rows=1 vs rows=2) works better
      // Let's test 4x1 vs 2x1 vs 8x1 vs 4x2
      for (int cols in [1, 2, 4, 8]) {
        for (int rows in [1, 2]) {
          final cellW = width / cols;
          final cellH = height / rows;
          print('--- Grid ${cols}x$rows (frame: ${cellW.toStringAsFixed(1)} x ${cellH.toStringAsFixed(1)}) ---');
          for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
              int nonZero = 0;
              final startX = (c * cellW).toInt();
              final endX = ((c + 1) * cellW).toInt();
              final startY = (r * cellH).toInt();
              final endY = ((r + 1) * cellH).toInt();

              int minX = endX, maxX = startX, minY = endY, maxY = startY;
              for (int y = startY; y < endY; y++) {
                for (int x = startX; x < endX; x++) {
                  final alpha = rgba[(y * width + x) * 4 + 3];
                  if (alpha > 30) {
                    nonZero++;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                  }
                }
              }
              if (nonZero > 0) {
                print('  R$r C$c: pixels=$nonZero bbox=[L:${minX - startX}, T:${minY - startY}, R:${maxX - startX}, B:${maxY - startY}] (content: ${maxX - minX + 1}x${maxY - minY + 1})');
              } else {
                print('  R$r C$c: EMPTY');
              }
            }
          }
        }
      }
    });
  }
}

void _printRanges(List<int> gaps, int maxLen) {
  if (gaps.isEmpty) {
    print('  None (continuous opaque content from 0 to ${maxLen - 1})');
    return;
  }
  int start = gaps.first;
  int prev = gaps.first;
  for (int i = 1; i < gaps.length; i++) {
    if (gaps[i] == prev + 1) {
      prev = gaps[i];
    } else {
      print('  [$start .. $prev]');
      start = gaps[i];
      prev = gaps[i];
    }
  }
  print('  [$start .. $prev]');
}
