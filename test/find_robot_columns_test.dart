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
    test('Find exact robot boundaries in $filename', () async {
      final file = File('assets/images/robot_mascot/$filename');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final width = image.width;
      final height = image.height;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = byteData!.buffer.asUint8List();

      print('\n==================================================');
      print('EXACT ANALYSIS: $filename ($width x $height)');
      print('==================================================');

      // Check vertical gaps (rows)
      final rowHasPixels = List<bool>.generate(height, (y) {
        for (int x = 0; x < width; x++) {
          if (rgba[(y * width + x) * 4 + 3] > 30) return true;
        }
        return false;
      });

      final rowBands = <List<int>>[];
      int? rStart;
      for (int y = 0; y < height; y++) {
        if (rowHasPixels[y]) {
          rStart ??= y;
        } else if (rStart != null) {
          rowBands.add([rStart, y - 1]);
          rStart = null;
        }
      }
      if (rStart != null) rowBands.add([rStart, height - 1]);

      print('Number of row bands (horizontal strips): ${rowBands.length}');
      for (int i = 0; i < rowBands.length; i++) {
        print('  Row Band $i: Y = ${rowBands[i][0]} .. ${rowBands[i][1]} (height: ${rowBands[i][1] - rowBands[i][0] + 1})');
      }

      // For each row band, check horizontal gaps (columns)
      int totalRobots = 0;
      for (int b = 0; b < rowBands.length; b++) {
        final minY = rowBands[b][0];
        final maxY = rowBands[b][1];

        final colHasPixels = List<bool>.generate(width, (x) {
          for (int y = minY; y <= maxY; y++) {
            if (rgba[(y * width + x) * 4 + 3] > 30) return true;
          }
          return false;
        });

        final colBands = <List<int>>[];
        int? cStart;
        for (int x = 0; x < width; x++) {
          if (colHasPixels[x]) {
            cStart ??= x;
          } else if (cStart != null) {
            colBands.add([cStart, x - 1]);
            cStart = null;
          }
        }
        if (cStart != null) colBands.add([cStart, width - 1]);

        print('  Row Band $b has ${colBands.length} robots:');
        for (int c = 0; c < colBands.length; c++) {
          totalRobots++;
          final minX = colBands[c][0];
          final maxX = colBands[c][1];
          final w = maxX - minX + 1;
          final h = maxY - minY + 1;
          print('    Robot $totalRobots (Band $b, Col $c): X = $minX..$maxX (width: $w), Y = $minY..$maxY (height: $h)');
        }
      }

      print('TOTAL ROBOT FIGURES FOUND IN $filename: $totalRobots');
    });
  }
}
