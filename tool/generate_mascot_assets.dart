import 'dart:io';
import 'dart:typed_data';

// Helper to construct a minimal valid PNG with colored 32x32 frames
void main() async {
  final dir = Directory('assets/images/robot_mascot');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final states = ['robot_idle', 'robot_walk', 'robot_run', 'robot_wave', 'robot_flex'];
  
  for (final state in states) {
    final filePath = '${dir.path}/$state.png';
    final bytes = generatePlaceholderPng(state);
    File(filePath).writeAsBytesSync(bytes);
    print('Generated placeholder PNG: $filePath (${bytes.length} bytes)');
  }
}

List<int> generatePlaceholderPng(String state) {
  // 128 x 32 PNG (4 frames of 32x32)
  final width = 128;
  final height = 32;
  
  // PNG signature
  final header = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  
  // IHDR chunk: 128x32, 8-bit RGBA (color type 6)
  final ihdrData = ByteData(13);
  ihdrData.setUint32(0, width);
  ihdrData.setUint32(4, height);
  ihdrData.setUint8(8, 8); // bit depth
  ihdrData.setUint8(9, 6); // RGBA
  ihdrData.setUint8(10, 0); // compression
  ihdrData.setUint8(11, 0); // filter
  ihdrData.setUint8(12, 0); // interlace
  
  final ihdrChunk = makeChunk('IHDR', ihdrData.buffer.asUint8List());

  // Generate image raw RGBA scanlines with filter byte (0)
  // Each line has 1 filter byte + 128 * 4 RGBA bytes = 513 bytes per line
  final rawScanlines = BytesBuilder();
  
  int r = 99, g = 102, b = 241; // Indigo default
  if (state.contains('walk')) { r = 16; g = 185; b = 129; } // Emerald
  else if (state.contains('run')) { r = 245; g = 158; b = 11; } // Amber
  else if (state.contains('wave')) { r = 236; g = 72; b = 153; } // Pink
  else if (state.contains('flex')) { r = 139; g = 92; b = 246; } // Purple

  for (int y = 0; y < height; y++) {
    rawScanlines.addByte(0); // None filter
    for (int x = 0; x < width; x++) {
      int frame = x ~/ 32;
      int localX = x % 32;
      int localY = y;
      
      // Draw pixel robot outline (head, eyes, body)
      bool isBorder = (localX == 4 || localX == 27 || localY == 4 || localY == 27);
      bool isEye = (localY >= 8 && localY <= 12) && ((localX >= 8 && localX <= 12) || (localX >= 19 && localX <= 23));
      bool isChestLight = (localY >= 18 && localY <= 22 && localX >= 13 && localX <= 18);
      bool isRobotBody = (localX >= 5 && localX <= 26 && localY >= 5 && localY <= 26);
      
      if (isEye) {
        // Cyan blinking eyes
        if (state.contains('idle') && frame == 2) {
          // Closed eye frame
          if (localY == 10) {
            rawScanlines.add([6, 182, 212, 255]); // Cyan
          } else {
            rawScanlines.add([r, g, b, 255]);
          }
        } else {
          rawScanlines.add([6, 182, 212, 255]);
        }
      } else if (isChestLight) {
        // Bright yellow chest core
        rawScanlines.add([253, 224, 71, 255]);
      } else if (isBorder) {
        // Dark retro border
        rawScanlines.add([15, 23, 42, 255]);
      } else if (isRobotBody) {
        // Body color shift per frame for motion demonstration
        int frameR = (r + frame * 15).clamp(0, 255);
        int frameG = (g + frame * 10).clamp(0, 255);
        int frameB = (b - frame * 10).clamp(0, 255);
        rawScanlines.add([frameR, frameG, frameB, 255]);
      } else {
        // Transparent background
        rawScanlines.add([0, 0, 0, 0]);
      }
    }
  }

  // Compress IDAT using uncompressed deflate blocks (zlib format)
  final idatData = makeZlibUncompressed(rawScanlines.takeBytes());
  final idatChunk = makeChunk('IDAT', idatData);

  // IEND chunk
  final iendChunk = makeChunk('IEND', []);

  final builder = BytesBuilder();
  builder.add(header);
  builder.add(ihdrChunk);
  builder.add(idatChunk);
  builder.add(iendChunk);
  return builder.takeBytes();
}

List<int> makeChunk(String type, List<int> data) {
  final builder = BytesBuilder();
  final len = ByteData(4)..setUint32(0, data.length);
  builder.add(len.buffer.asUint8List());
  
  final typeBytes = type.codeUnits;
  builder.add(typeBytes);
  builder.add(data);
  
  final crc = calculateCrc32([...typeBytes, ...data]);
  final crcData = ByteData(4)..setUint32(0, crc);
  builder.add(crcData.buffer.asUint8List());
  
  return builder.takeBytes();
}

List<int> makeZlibUncompressed(Uint8List uncompressed) {
  final out = BytesBuilder();
  // Zlib header: CMF=0x78 (32K window, deflate), FLG=0x01
  out.add([0x78, 0x01]);
  
  int offset = 0;
  final total = uncompressed.length;
  
  while (offset < total) {
    final chunkSize = (total - offset) > 65535 ? 65535 : (total - offset);
    final isFinal = (offset + chunkSize) >= total ? 1 : 0;
    
    // Deflate non-compressed block header
    out.addByte(isFinal); // BFINAL and BTYPE=00
    final lenBytes = ByteData(2)..setUint16(0, chunkSize, Endian.little);
    final nlenBytes = ByteData(2)..setUint16(0, ~chunkSize & 0xFFFF, Endian.little);
    out.add(lenBytes.buffer.asUint8List());
    out.add(nlenBytes.buffer.asUint8List());
    
    out.add(uncompressed.sublist(offset, offset + chunkSize));
    offset += chunkSize;
  }
  
  // Adler-32 checksum
  int a = 1, b = 0;
  for (int i = 0; i < uncompressed.length; i++) {
    a = (a + uncompressed[i]) % 65521;
    b = (b + a) % 65521;
  }
  final adler = (b << 16) | a;
  final adlerData = ByteData(4)..setUint32(0, adler);
  out.add(adlerData.buffer.asUint8List());
  
  return out.takeBytes();
}

int calculateCrc32(List<int> bytes) {
  int crc = 0xFFFFFFFF;
  for (int b in bytes) {
    crc ^= b;
    for (int i = 0; i < 8; i++) {
      if ((crc & 1) != 0) {
        crc = (crc >> 1) ^ 0xEDB88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc ^ 0xFFFFFFFF;
}
