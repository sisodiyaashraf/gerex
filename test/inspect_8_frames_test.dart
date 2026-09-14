import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check all 8 frames for 4x2 grid assets', () async {
    final files = [
      'gerex_robot_walking.png',
      'gerex_robot_running.png',
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
      final w = image.width;
      final h = image.height;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) continue;
      final buffer = byteData.buffer.asUint8List();

      final fw = w / 4;
      final fh = h / 2;

      print('=== $fileName ===');
      for (int i = 0; i < 8; i++) {
        final col = i % 4;
        final row = i ~/ 4;
        int pixels = 0;
        for (int y = (row * fh).toInt(); y < ((row + 1) * fh).toInt(); y++) {
          for (int x = (col * fw).toInt(); x < ((col + 1) * fw).toInt(); x++) {
            final idx = (y * w + x) * 4;
            if (buffer[idx + 3] > 30) pixels++;
          }
        }
        print('  Frame $i (col $col, row $row): $pixels opaque pixels');
      }
    }
  });
}
