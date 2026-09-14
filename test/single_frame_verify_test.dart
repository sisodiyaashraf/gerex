import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify single robot isolation with 4x2 grid', () async {
    final files = [
      'gerex_robot_running.png',
      'gerex_robot_walking.png',
      'gerex_robot_smiling.png',
      'gerex_robot_exercise.png',
      'gerex_robot_sweating.png',
      'gerex_robot_tired.png',
    ];

    for (final fileName in files) {
      final file = File('assets/images/robot_mascot/$fileName');
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) continue;
      final buffer = byteData.buffer.asUint8List();

      const columns = 4;
      const rows = 2;
      final frameW = width / columns;
      final frameH = height / rows;

      // Test frame 0: rect (0, 0, frameW, frameH)
      // Check horizontal profile across x in [0, frameW]
      int leftHalfPixels = 0;
      int rightHalfPixels = 0;

      final halfW = frameW / 2;

      for (int y = 0; y < frameH; y++) {
        for (int x = 0; x < frameW; x++) {
          final idx = (y * width + x) * 4;
          if (buffer[idx + 3] > 30) {
            if (x < halfW) leftHalfPixels++;
            else rightHalfPixels++;
          }
        }
      }

      print('$fileName Frame 0 (384x512): leftHalf=$leftHalfPixels, rightHalf=$rightHalfPixels');
      // If single robot centered in frame 0, pixels are concentrated around center (both left and right half are equal parts of 1 robot)
    }
  });
}
