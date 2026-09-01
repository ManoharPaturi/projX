import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_detect/testing.dart'
    show exifOrientationOf, withExifOrientation;

/// Plan §3 stage 1: the decode seam. JPEG bytes in, EXIF-oriented
/// grayscale out — the exact contract `takePicture`'s output meets before
/// `evaluateGray` ever runs.
///
/// The codec applies the EXIF tag itself; these tests PIN that (a codec
/// bump that drops it must fail here, not mis-grade an exam), prove the
/// parser on hand-built segments (the encoder emits none), and round-trip
/// synthetic pixels through real JPEG bytes.
void main() {
  final cv = OpencvDartImpl();

  /// A checker pattern: survives JPEG, differs under any transform.
  Uint8List pattern(int width, int height) => Uint8List.fromList([
        for (var y = 0; y < height; y++)
          for (var x = 0; x < width; x++)
            ((x + y) % 2 == 0 ? 40 : 215) + (y * 3) % 60,
      ]);

  group('exifOrientationOf (fixture tooling)', () {
    Uint8List jpegWithApp1(List<int> app1Payload) => Uint8List.fromList([
          0xff, 0xd8, // SOI
          0xff, 0xe1, ..._u16be(app1Payload.length), ...app1Payload,
          0xff, 0xd9, // EOI
        ]);

    List<int> exifSegment({required int orientation, bool bigEndian = false}) {
      List<int> u16(int v) =>
          bigEndian ? [(v >> 8) & 0xff, v & 0xff] : [v & 0xff, (v >> 8) & 0xff];
      List<int> u32(int v) => bigEndian
          ? [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff]
          : [v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff];
      return [
        0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // 'Exif\0\0'
        ...bigEndian ? [0x4d, 0x4d, 0x00, 0x2a] : [0x49, 0x49, 0x2a, 0x00],
        ...u32(8), // IFD0 right after the header
        ...u16(1), // one entry
        ...bigEndian ? [0x01, 0x12] : [0x12, 0x01], // tag 0x0112
        ...bigEndian ? [0x00, 0x03] : [0x03, 0x00], // SHORT
        ...u32(1), // count
        ...u16(orientation), ...u16(0), // value + padding
        ...u32(0), // next-IFD
      ];
    }

    test('reads orientation from a little-endian APP1', () {
      final jpeg = jpegWithApp1(exifSegment(orientation: 6));
      expect(exifOrientationOf(jpeg), 6);
    });

    test('reads orientation from a big-endian APP1', () {
      final jpeg = jpegWithApp1(exifSegment(orientation: 6, bigEndian: true));
      expect(exifOrientationOf(jpeg), 6);
    });

    test('a non-Exif APP1 and no APP1 at all both read as upright', () {
      expect(exifOrientationOf(jpegWithApp1([1, 2, 3, 4, 5, 6, 7, 8])), 1);
      expect(
        exifOrientationOf(Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9])),
        1,
      );
    });

    test('withExifOrientation round-trips through the parser', () {
      final base = cv.encodeGrayJpeg(16, 16, pattern(16, 16));
      expect(exifOrientationOf(base), 1, reason: 'encoder emits no EXIF');
      expect(exifOrientationOf(withExifOrientation(base, 8)), 8);
    });
  });

  group('decodeStill', () {
    test('encode → decode round-trips dimensions and pixels', () {
      const w = 97, h = 41; // odd sizes catch row/column swaps
      final jpeg = cv.encodeGrayJpeg(w, h, pattern(w, h));
      final decoded = cv.decodeStill(jpeg);

      expect(decoded.width, w);
      expect(decoded.height, h);
      expect(decoded.gray.length, w * h);
      // JPEG is lossy — assert the pattern's contrast survived, not exact.
      final bright = decoded.gray.where((v) => v > 150).length;
      final dark = decoded.gray.where((v) => v < 110).length;
      expect(bright + dark, greaterThan(decoded.gray.length ~/ 2),
          reason: 'contrast survived');
    });

    test('undecodable bytes throw, not zero-fill', () {
      expect(
        () => cv.decodeStill(Uint8List.fromList([1, 2, 3])),
        throwsStateError,
      );
    });

    test('the codec applies EXIF orientation — portrait stays upright', () {
      // A 33×17 (landscape) frame tagged as each orientation: the side-
      // swapping values must come back transposed, the others unchanged.
      // This pins the codec behaviour the pipeline leans on; a codec bump
        // that drops EXIF fails here instead of registering tipped sheets.
      const w = 33, h = 17;
      final base = cv.encodeGrayJpeg(w, h, pattern(w, h));

      final expectDims = {
        1: (w, h), // upright
        2: (w, h), // mirrored horizontally
        3: (w, h), // 180°
        4: (w, h), // mirrored vertically
        5: (h, w), // transpose + mirror
        6: (h, w), // 90° CW
        7: (h, w), // anti-transpose + mirror
        8: (h, w), // 90° CCW
      };
      for (final entry in expectDims.entries) {
        final decoded = cv.decodeStill(withExifOrientation(base, entry.key));
        expect(
          decoded.width,
          entry.value.$1,
          reason: 'orientation ${entry.key}: width',
        );
        expect(
          decoded.height,
          entry.value.$2,
          reason: 'orientation ${entry.key}: height',
        );
      }
    });
  });
}

List<int> _u16be(int v) => [(v >> 8) & 0xff, v & 0xff];
