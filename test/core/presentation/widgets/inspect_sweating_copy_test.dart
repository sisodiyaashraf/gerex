import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Find optimal grid for sweating copy', () async {
    final file = File('assets/images/robot_mascot/gerex_robot_sweating copy.png');
    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width;
    final height = image.height;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = byteData!.buffer.asUint8List();

    final combos = [
      [1, 1], [2, 1], [3, 1], [4, 1], [6, 1],
      [1, 2], [2, 2], [3, 2], [4, 2], [6, 2],
      [1, 3], [2, 3], [3, 3]
    ];

    for (var combo in combos) {
      final cols = combo[0];
      final rows = combo[1];
      final totalFrames = cols * rows;
      final frameW = width / cols;
      final frameH = height / rows;

      int totalBorderBleed = 0;
      for (int i = 0; i < totalFrames; i++) {
        final col = i % cols;
        final row = i ~/ cols;

        final startX = (col * frameW).toInt();
        final endX = ((col + 1) * frameW).toInt();
        final startY = (row * frameH).toInt();
        final endY = ((row + 1) * frameH).toInt();

        for (int y = startY; y < endY; y++) {
          final leftAlpha = rgba[(y * width + startX) * 4 + 3];
          final rightAlpha = rgba[(y * width + (endX - 1)) * 4 + 3];
          if (leftAlpha > 30) totalBorderBleed++;
          if (rightAlpha > 30) totalBorderBleed++;
        }
      }
      print('Combo ${cols}x${rows} (total ${totalFrames} frames): totalBorderBleed = $totalBorderBleed');
    }
  });
}
