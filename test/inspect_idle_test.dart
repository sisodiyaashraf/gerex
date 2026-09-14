import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Inspect gerex_robot_idle.png layout', () async {
    final file = File('assets/images/robot_mascot/gerex_robot_idle.png');
    final bytes = file.readAsBytesSync();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    print('idle image size: ${image.width}x${image.height}');

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;
    final buffer = byteData.buffer.asUint8List();

    // Check if idle has 4 columns x 2 rows, or 2x2 grid, or single image
    final w = image.width;
    final h = image.height;

    // Check 2x2 quadrants
    int tl = 0, tr = 0, bl = 0, br = 0;
    for (int y = 0; y < h; y += 4) {
      for (int x = 0; x < w; x += 4) {
        final idx = (y * w + x) * 4;
        if (buffer[idx + 3] > 30) {
          if (x < w / 2 && y < h / 2) tl++;
          else if (x >= w / 2 && y < h / 2) tr++;
          else if (x < w / 2 && y >= h / 2) bl++;
          else br++;
        }
      }
    }
    print('Idle 2x2 counts: TL:$tl, TR:$tr, BL:$bl, BR:$br');
  });
}
