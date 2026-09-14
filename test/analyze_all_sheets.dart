import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Comprehensive grid analysis for all mascot PNG assets', () async {
    final dir = Directory('assets/images/robot_mascot');
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList();

    for (final file in files) {
      final fileName = file.uri.pathSegments.last;
      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final w = image.width;
      final h = image.height;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) continue;
      final buffer = byteData.buffer.asUint8List();

      print('\n========================================');
      print('ASSET: $fileName (${w}x${h})');

      // Test 4x2 grid (cols: 4, rows: 2) -> frame 384x512 or 153x204
      // Test 2x2 grid (cols: 2, rows: 2) -> frame 768x512 or 306x204
      // Test 4x1 grid (cols: 4, rows: 1) -> frame 384x1024 or 153x408
      // Test 2x1 grid (cols: 2, rows: 1) -> frame 768x1024 or 306x408

      final configs = [
        {'cols': 4, 'rows': 2, 'name': '4 cols x 2 rows (8 frames)'},
        {'cols': 2, 'rows': 2, 'name': '2 cols x 2 rows (4 frames)'},
        {'cols': 4, 'rows': 1, 'name': '4 cols x 1 row (4 frames)'},
        {'cols': 2, 'rows': 1, 'name': '2 cols x 1 row (2 frames)'},
        {'cols': 1, 'rows': 2, 'name': '1 col x 2 rows (2 frames)'},
      ];

      for (final cfg in configs) {
        final cols = cfg['cols'] as int;
        final rows = cfg['rows'] as int;
        final name = cfg['name'] as String;

        final fw = w / cols;
        final fh = h / rows;

        // Count robots inside frame 0: check top half vs bottom half of frame 0, and left vs right half of frame 0
        int topHalf = 0;
        int botHalf = 0;
        int midGap = 0;

        final fHalfH = fh / 2;
        final gapTop = fHalfH - (fh * 0.1);
        final gapBot = fHalfH + (fh * 0.1);

        for (int y = 0; y < fh; y++) {
          for (int x = 0; x < fw; x++) {
            final idx = ((y.toInt()) * w + (x.toInt())) * 4;
            if (buffer[idx + 3] > 30) {
              if (y < gapTop) topHalf++;
              else if (y > gapBot) botHalf++;
              else midGap++;
            }
          }
        }

        print('  Layout [$name]: fw=${fw.toStringAsFixed(0)}, fh=${fh.toStringAsFixed(0)}');
        print('    Frame 0 pixel counts -> TopHalf: $topHalf, MidGap: $midGap, BotHalf: $botHalf');
        if (topHalf > 500 && botHalf > 500 && midGap < (topHalf + botHalf) / 8) {
          print('    ⚠️  WARNING: Frame 0 STILL HAS 2 VERTICALLY STACKED FIGURES! (TopHalf: $topHalf, BotHalf: $botHalf)');
        } else {
          print('    ✅  CLEAN SINGLE FIGURE IN FRAME 0!');
        }
      }
    }
  });
}
