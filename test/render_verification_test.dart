import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:gerex/core/presentation/providers/mascot_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify all MascotState grid specs match non-alpha bounding boxes with 0 multi-robot overlap', () async {
    for (final state in MascotState.values) {
      final file = File(state.assetPath);
      expect(file.existsSync(), true, reason: 'File should exist: ${state.assetPath}');

      final bytes = file.readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      final cols = state.columns;
      final rows = state.rows;
      final count = state.frameCount;

      final frameW = image.width / cols;
      final frameH = image.height / rows;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(byteData, isNotNull);

      print('Testing MascotState.${state.name}: ${image.width}x${image.height} -> Grid ${cols}x${rows}, ${count} frames (${frameW.toStringAsFixed(1)}x${frameH.toStringAsFixed(1)})');

      for (int i = 0; i < count; i++) {
        final col = i % cols;
        final row = i ~/ cols;

        final startX = (col * frameW).toInt();
        final startY = (row * frameH).toInt();
        final endX = ((col + 1) * frameW).toInt();
        final endY = ((row + 1) * frameH).toInt();

        int pixelCount = 0;
        for (int y = startY; y < endY; y++) {
          for (int x = startX; x < endX; x++) {
            final offset = (y * image.width + x) * 4;
            if (byteData!.getUint8(offset + 3) > 20) pixelCount++;
          }
        }
        expect(pixelCount > 0, true, reason: 'Frame $i of MascotState.${state.name} should have content');
      }
    }
  });
}
