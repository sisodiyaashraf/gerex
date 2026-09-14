import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Analyze sprite sheet pixel distribution', () async {
    final dir = Directory('assets/images/robot_mascot');
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.png')) continue;
      final fileName = file.uri.pathSegments.last;
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) continue;
      final buffer = byteData.buffer.asUint8List();

      // Check density across 4 quadrants, 4 horizontal slices, 4 vertical slices
      // 1. Grid 2x2 density
      int qTopLeft = 0, qTopRight = 0, qBottomLeft = 0, qBottomRight = 0;
      // 2. Horiz 4x1 density (col 0, 1, 2, 3)
      List<int> hCols = [0, 0, 0, 0];
      // 3. Vert 1x4 density (row 0, 1, 2, 3)
      List<int> vRows = [0, 0, 0, 0];

      final halfW = width ~/ 2;
      final halfH = height ~/ 2;
      final sliceW = width ~/ 4;
      final sliceH = height ~/ 4;

      for (int y = 0; y < height; y += 4) {
        for (int x = 0; x < width; x += 4) {
          final index = (y * width + x) * 4;
          final alpha = buffer[index + 3];
          if (alpha > 30) {
            // Non-transparent pixel
            if (x < halfW && y < halfH) qTopLeft++;
            else if (x >= halfW && y < halfH) qTopRight++;
            else if (x < halfW && y >= halfH) qBottomLeft++;
            else if (x >= halfW && y >= halfH) qBottomRight++;

            if (sliceW > 0) {
              int c = (x ~/ sliceW).clamp(0, 3);
              hCols[c]++;
            }
            if (sliceH > 0) {
              int r = (y ~/ sliceH).clamp(0, 3);
              vRows[r]++;
            }
          }
        }
      }

      print('=== $fileName (${width}x${height}) ===');
      print('Grid 2x2 opaque pixels: TL:$qTopLeft, TR:$qTopRight, BL:$qBottomLeft, BR:$qBottomRight');
      print('Horiz 4x1 opaque pixels: C0:${hCols[0]}, C1:${hCols[1]}, C2:${hCols[2]}, C3:${hCols[3]}');
      print('Vert 1x4 opaque pixels: R0:${vRows[0]}, R1:${vRows[1]}, R2:${vRows[2]}, R3:${vRows[3]}');
    }
  });
}
