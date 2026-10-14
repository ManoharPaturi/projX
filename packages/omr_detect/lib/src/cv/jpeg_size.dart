import 'dart:typed_data';

/// Pixel size from a JPEG's frame header (SOFn), without decoding — so the
/// caller can pick a reduced decode for an oversized still before paying
/// for the full one. Stored (pre-EXIF-rotation) size; the short side is the
/// same either way. Null when [bytes] is not a JPEG this scan understands.
({int width, int height})? jpegSize(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var i = 2;
  while (i + 9 < bytes.length) {
    if (bytes[i] != 0xFF) return null;
    final marker = bytes[i + 1];
    if (marker == 0xFF) {
      i++; // fill byte
      continue;
    }
    // Standalone markers carry no length.
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      i += 2;
      continue;
    }
    final length = (bytes[i + 2] << 8) | bytes[i + 3];
    final isFrame =
        marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isFrame) {
      final height = (bytes[i + 5] << 8) | bytes[i + 6];
      final width = (bytes[i + 7] << 8) | bytes[i + 8];
      if (width == 0 || height == 0) return null;
      return (width: width, height: height);
    }
    if (marker == 0xDA) return null; // scan data before any frame header
    i += 2 + length;
  }
  return null;
}
