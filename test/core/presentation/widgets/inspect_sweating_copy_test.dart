import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Compare 2x2 vs 2x3 vs 4x1 for sweating copy image', () async {
    final file = File('assets/images/robot_mascot/gerex_robot_sweating copy.png');
    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width;
    final height = image.height;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = byteData!.buffer.asUint8List();

    print('--- 2x2 Grid (2 cols x 2 rows = 4 frames) ---');
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 2; c++) {
        final fw = width / 2;
        final fh = height / 2;
        int activePx = 0;
        for (int y = (r * fh).toInt(); y < ((r + 1) * fh).toInt(); y++) {
          for (int x = (c * fw).toInt(); x < ((c + 1) * fw).toInt(); x++) {
            if (rgba[(y * width + x) * 4 + 3] > 10) activePx++;
          }
        }
        print('2x2 Cell ($r, $c): $activePx active pixels');
      }
    }

    print('--- 2x3 Grid (2 cols x 3 rows = 6 frames) ---');
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 2; c++) {
        final fw = width / 2;
        final fh = height / 3;
        int activePx = 0;
        for (int y = (r * fh).toInt(); y < ((r + 1) * fh).toInt(); y++) {
          for (int x = (c * fw).toInt(); x < ((c + 1) * fw).toInt(); x++) {
            if (rgba[(y * width + x) * 4 + 3] > 10) activePx++;
          }
        }
        print('2x3 Cell ($r, $c): $activePx active pixels');
      }
    }

    print('--- 4x1 Grid (4 cols x 1 row = 4 frames) ---');
    for (int c = 0; c < 4; c++) {
      final fw = width / 4;
      final fh = height / 1;
      int activePx = 0;
      for (int y = 0; y < fh.toInt(); y++) {
        for (int x = (c * fw).toInt(); x < ((c + 1) * fw).toInt(); x++) {
          if (rgba[(y * width + x) * 4 + 3] > 10) activePx++;
        }
      }
      print('4x1 Cell (0, $c): $activePx active pixels');
    }
  });
}
