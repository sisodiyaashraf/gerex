import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect gerex_robot_sweating copy.png grid details', () async {
    final file = File('assets/images/robot_mascot/gerex_robot_sweating copy.png');
    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width;
    final height = image.height;
    print('Image dimensions: ${width}x${height}');

    // Test 3x2 grid (204x204 frames)
    final cols3 = 3;
    final rows2 = 2;
    final fw3 = width / cols3;
    final fh2 = height / rows2;
    print('3x2 Grid frame dimensions: ${fw3}x${fh2}');

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgba = byteData!.buffer.asUint8List();

    for (int r = 0; r < rows2; r++) {
      for (int c = 0; c < cols3; c++) {
        int nonZeroAlpha = 0;
        final startX = (c * fw3).toInt();
        final endX = ((c + 1) * fw3).toInt();
        final startY = (r * fh2).toInt();
        final endY = ((r + 1) * fh2).toInt();

        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            final alpha = rgba[(y * width + x) * 4 + 3];
            if (alpha > 10) nonZeroAlpha++;
          }
        }
        print('Cell ($r, $c): nonZeroAlpha pixels = $nonZeroAlpha');
      }
    }
  });
}
