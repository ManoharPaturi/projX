import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_detect/testing.dart';
import 'package:omr_spec/omr_spec.dart';

/// O3 speed-ups must not move a single read: registration on a downscaled
/// copy with full-resolution refinement, and the codec's reduced decode for
/// oversized stills.
void main() {
  final cv = OpencvDartImpl();
  final template = compileDetectionTemplate(buildStandard90());

  // A perspective capture at 2400×3200: every anchor somewhere other than
  // the centred default, so refinement has real work to do.
  const w = 2400, h = 3200;
  const anchors = {
    'tl': CvPointI(520, 460),
    'tr': CvPointI(1960, 420),
    'br': CvPointI(2060, 2780),
    'bl': CvPointI(380, 2840),
  };
  final marks = [
    inkAt(template, 'q1', 'C'),
    inkAt(template, 'q2', 'A'),
    inkAt(template, 'q45', 'D'),
    inkAt(template, 'q90', 'B'),
  ];
  final photo = renderSheetPhoto(
    cv,
    template,
    imageWidth: w,
    imageHeight: h,
    marks: marks,
    anchorDst: anchors,
  );

  void expectReads(StillEvaluation r) {
    expect(r.rejected, isFalse, reason: '${r.trace}');
    expect(r.registrationPath, RegistrationPath.fiducialQuadrant);
    expect(r.read.responses['q1']!.chosen, {'C'});
    expect(r.read.responses['q2']!.chosen, {'A'});
    expect(r.read.responses['q45']!.chosen, {'D'});
    expect(r.read.responses['q90']!.chosen, {'B'});
    expect(r.read.responses['q3']!.chosen, isEmpty);
  }

  test('downscaled registration reads the same as full-resolution', () {
    final coarse = OmrPipeline(
      cv: cv,
      template: template,
    ).evaluateGray(w, h, photo);
    final full = OmrPipeline(
      cv: cv,
      template: template,
      registrationWidth: w, // no downscale: the original behaviour
    ).evaluateGray(w, h, photo);

    expectReads(coarse);
    expectReads(full);
    expect(coarse.read.sheetConfidence, greaterThan(0.9));
  });

  test('refined anchor centres land on the true anchors', () {
    final r = OmrPipeline(cv: cv, template: template).evaluateGray(w, h, photo);
    final plan = fiducialSearchPlan(template, w, h);
    for (var i = 0; i < plan.length; i++) {
      final found = r.registration!.matches[i]!.center;
      final truth = anchors[plan[i].corner]!;
      // A coarse-only centre would be off by up to ~4 px at this size.
      expect(
        (found.x - truth.x).abs(),
        lessThanOrEqualTo(2),
        reason: '${plan[i].corner}: $found vs $truth',
      );
      expect(
        (found.y - truth.y).abs(),
        lessThanOrEqualTo(2),
        reason: '${plan[i].corner}: $found vs $truth',
      );
    }
  });

  test('evaluateStill decodes oversized stills reduced, same answers', () {
    final jpeg = cv.encodeGrayJpeg(w, h, photo);
    final pipeline = OmrPipeline(cv: cv, template: template);

    final full = pipeline.evaluateStill(jpeg);
    // 2400 short side ≥ 2 × 1200 → decoded at 1/2.
    final reduced = pipeline.evaluateStill(jpeg, maxShortSide: 1200);

    expectReads(full);
    expectReads(reduced);
    final decode = reduced.trace.firstWhere((t) => t.stage == 'decode');
    expect(decode.detail, startsWith('1200x1600 (1/2 of 2400x3200)'));
    expect(
      full.trace.firstWhere((t) => t.stage == 'decode').detail,
      '2400x3200',
    );
  });

  group('jpegSize', () {
    test('reads the frame header without decoding', () {
      final jpeg = cv.encodeGrayJpeg(33, 17, Uint8List(33 * 17));
      expect(jpegSize(jpeg), (width: 33, height: 17));
      // An EXIF segment before the frame header is skipped over.
      expect(jpegSize(withExifOrientation(jpeg, 6)), (width: 33, height: 17));
    });

    test('null for bytes that are not a JPEG', () {
      expect(jpegSize(Uint8List.fromList([1, 2, 3, 4])), isNull);
      expect(jpegSize(Uint8List(0)), isNull);
    });
  });

  test('decodeGray at 1/2 keeps EXIF orientation', () {
    const sw = 64, sh = 32;
    final jpeg = withExifOrientation(
      cv.encodeGrayJpeg(sw, sh, Uint8List(sw * sh)),
      6,
    );
    final half = cv.decodeGray(jpeg, reduction: 2);
    addTearDown(() => cv.dispose(half));
    final size = cv.sizeOf(half);
    expect((size.width, size.height), (sh ~/ 2, sw ~/ 2));
  });
}
