import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check border bleed for 3x2 grid on sweating copy', () async {
    final file = File('assets/images/robot_mascot/gerex_robot_sweating copy.png');
    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width;
    final height = image.height;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = byteData!.buffer.asUint8List();

    final cols = 3;
    final rows = 2;
    final frameW = width / cols;
    final frameH = height / rows;

    for (int i = 0; i < 6; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final startX = (col * frameW).toInt();
      final endX = ((col + 1) * frameW).toInt();
      final startY = (row * frameH).toInt();
      final endY = ((row + 1) * frameH).toInt();

      int leftBorderBleed = 0;
      int rightBorderBleed = 0;
      for (int y = startY; y < endY; y++) {
        final leftAlpha = rgba[(y * width + startX) * 4 + 3];
        final rightAlpha = rgba[(y * width + (endX - 1)) * 4 + 3];
        if (leftAlpha > 30) leftBorderBleed++;
        if (rightAlpha > 30) rightBorderBleed++;
      }

      print('Frame $i: leftBleed=$leftBorderBleed, rightBleed=$rightBorderBleed');
    }
  });
}
