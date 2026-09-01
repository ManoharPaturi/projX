import 'dart:typed_data';

/// Reads a JPEG's EXIF orientation (tag 0x0112).
///
/// The codec itself applies the tag when decoding (see
/// `OpencvDartImpl.decodeStill`), so this parser is FIXTURE TOOLING, not a
/// production stage: tests splice segments with [withExifOrientation] and
/// verify what came back through the decode seam. Returns 1..8 (1 =
/// upright, tag absent, or bytes not a JPEG we can walk).
int exifOrientationOf(Uint8List jpeg) {
  // Too short for SOI + one segment header.
  if (jpeg.length < 4) return 1;
  if (jpeg[0] != 0xff || jpeg[1] != 0xd8) return 1;

  var i = 2;
  while (i + 4 <= jpeg.length) {
    if (jpeg[i] != 0xff) return 1; // desynced — not a segment walk we trust
    final marker = jpeg[i + 1];
    // Standalone markers without a length field (restart markers, fill bytes).
    if (marker == 0xd8 || (marker >= 0xd0 && marker <= 0xd7) || marker == 0x01) {
      i += 2;
      continue;
    }
    // SOS/EOI: no APP1 carrying EXIF beyond this point.
    if (marker == 0xda || marker == 0xd9) return 1;

    final segmentLength = (jpeg[i + 2] << 8) | jpeg[i + 3];
    if (segmentLength < 2) return 1;

    if (marker == 0xe1 && // APP1
        i + 4 + 6 <= jpeg.length &&
        jpeg[i + 4] == 0x45 && jpeg[i + 5] == 0x78 && // 'E','x'
        jpeg[i + 6] == 0x69 && jpeg[i + 7] == 0x66 && // 'i','f'
        jpeg[i + 8] == 0x00 && jpeg[i + 9] == 0x00) {
      return _orientationFromTiff(jpeg, i + 4 + 6) ?? 1;
    }
    i += 2 + segmentLength;
  }
  return 1;
}

/// Parses the TIFF header + IFD0 beginning at [tiff], returning the
/// orientation tag's value or null when the structure is unusable.
int? _orientationFromTiff(Uint8List b, int tiff) {
  if (tiff + 8 > b.length) return null;
  final littleEndian = b[tiff] == 0x49 && b[tiff + 1] == 0x49;
  final bigEndian = b[tiff] == 0x4d && b[tiff + 1] == 0x4d;
  if (!littleEndian && !bigEndian) return null;

  int u16(int at) => littleEndian
      ? b[at] | (b[at + 1] << 8)
      : (b[at] << 8) | b[at + 1];
  int u32(int at) => littleEndian
      ? b[at] | (b[at + 1] << 8) | (b[at + 2] << 16) | (b[at + 3] << 24)
      : (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];

  if (u16(tiff + 2) != 42) return null; // TIFF magic
  final ifd0 = tiff + u32(tiff + 4);
  if (ifd0 + 2 > b.length) return null;
  final count = u16(ifd0);
  for (var e = 0; e < count; e++) {
    final entry = ifd0 + 2 + e * 12;
    if (entry + 12 > b.length) return null;
    if (u16(entry) == 0x0112) {
      final value = u16(entry + 8);
      return (value >= 1 && value <= 8) ? value : 1;
    }
  }
  return null;
}

/// Splices an EXIF APP1 segment carrying [orientation] into [jpeg], right
/// after SOI — the writer the decode tests use to build rotated fixtures
/// (imencode emits no EXIF, so the splice is the only source of the tag).
Uint8List withExifOrientation(Uint8List jpeg, int orientation) {
  // Minimal TIFF: II, 42, IFD0 at offset 8; one SHORT entry; next-IFD 0.
  final tiff = <int>[
    0x49, 0x49, 0x2a, 0x00, 0x08, 0x00, 0x00, 0x00, // header
    0x01, 0x00, // one entry
    0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, // tag 0x0112, SHORT×1
    orientation, 0x00, 0x00, 0x00, // value, padding, next-IFD offset
  ];
  final app1 = <int>[
    0xff, 0xe1, ..._u16be(2 + 6 + tiff.length), //
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // 'Exif\0\0'
    ...tiff,
  ];
  return Uint8List.fromList(
    [...jpeg.sublist(0, 2), ...app1, ...jpeg.sublist(2)],
  );
}

List<int> _u16be(int v) => [(v >> 8) & 0xff, v & 0xff];
