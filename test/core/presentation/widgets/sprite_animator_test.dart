import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:gerex/core/presentation/providers/mascot_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mascot Sprite Sheet Asset Frame Boundary Tests', () {
    for (final state in MascotState.values) {
      test(
        'Verify zero frame border bleed for ${state.name} (${state.assetPath})',
        () async {
          final file = File(state.assetPath);
          if (!file.existsSync()) return;

          final bytes = file.readAsBytesSync();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final image = frame.image;

          final width = image.width;
          final height = image.height;
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final rgba = byteData!.buffer.asUint8List();

          final cols = state.columns;
          final rows = state.rows;
          final frameW = width / cols;
          final frameH = height / rows;

          for (int i = 0; i < state.frameCount; i++) {
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

            expect(
              leftBorderBleed,
              0,
              reason:
                  'Frame $i in ${state.name} has left border bleed ($leftBorderBleed px)',
            );
            expect(
              rightBorderBleed,
              0,
              reason:
                  'Frame $i in ${state.name} has right border bleed ($rightBorderBleed px)',
            );
          }
        },
      );
    }
  });
}
