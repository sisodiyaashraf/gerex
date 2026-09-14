import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final configs = [
    {'file': 'gerex_robot_idle.png', 'cols': 1, 'rows': 1, 'frames': 1},
    {'file': 'gerex_robot_walking.png', 'cols': 3, 'rows': 2, 'frames': 6},
    {'file': 'gerex_robot_running.png', 'cols': 4, 'rows': 2, 'frames': 8},
    {'file': 'gerex_robot_smiling.png', 'cols': 4, 'rows': 1, 'frames': 4},
    {'file': 'gerex_robot_exercise.png', 'cols': 3, 'rows': 2, 'frames': 6},
    {'file': 'gerex_robot_sweating.png', 'cols': 4, 'rows': 1, 'frames': 4},
    {'file': 'gerex_robot_sweating_and_tired.png', 'cols': 6, 'rows': 1, 'frames': 6},
    {'file': 'gerex_robot_tired.png', 'cols': 1, 'rows': 1, 'frames': 1},
  ];

  for (final cfg in configs) {
    final filename = cfg['file'] as String;
    final cols = cfg['cols'] as int;
    final rows = cfg['rows'] as int;
    final totalFrames = cfg['frames'] as int;

    test('Verify clean single robot per frame for $filename', () async {
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

      print('Testing $filename ($width x $height): $cols cols x $rows rows ($totalFrames frames), frame: ${frameW.toStringAsFixed(1)} x ${frameH.toStringAsFixed(1)}');

      for (int i = 0; i < totalFrames; i++) {
        final col = i % cols;
        final row = i ~/ cols;

        final startX = (col * frameW).toInt();
        final endX = ((col + 1) * frameW).toInt();
        final startY = (row * frameH).toInt();
        final endY = ((row + 1) * frameH).toInt();

        // Check left and right borders of this frame rect for bleeding pixels
        int leftBorderBleed = 0;
        int rightBorderBleed = 0;
        for (int y = startY; y < endY; y++) {
          final leftAlpha = rgba[(y * width + startX) * 4 + 3];
          final rightAlpha = rgba[(y * width + (endX - 1)) * 4 + 3];
          if (leftAlpha > 30) leftBorderBleed++;
          if (rightAlpha > 30) rightBorderBleed++;
        }

        // Expect ZERO border bleed across frame boundaries
        expect(leftBorderBleed, 0, reason: 'Frame $i in $filename has left border bleed ($leftBorderBleed px)');
        expect(rightBorderBleed, 0, reason: 'Frame $i in $filename has right border bleed ($rightBorderBleed px)');
      }
    });
  }
}
