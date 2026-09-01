import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_core/omr_core.dart' show SheetReadFlag;
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart';

/// The whole ladder over synthetic photos, always through the public
/// [OmrPipeline.evaluateGray] and asserted on decoded VALUES: the happy
/// path, the displaced-anchor rung, the page-quad rung, outright rejection,
/// and the curl gate.
///
/// The fixture draws the sheet on the DETECTION CANVAS (template
/// coordinates, trivially correct rects) and warps it into the photo
/// through the four anchor correspondences — the exact homography the
/// registrar will invert — so fixture geometry and pipeline estimate cancel
/// and only the measurement chain is under test. Placement is expressed as
/// the four anchors' photo positions; moving them off the default centred
/// layout produces the off-axis captures the fallback ladder exists for.
void main() {
  final cv = OpencvDartImpl();
  final template = compileDetectionTemplate(buildStandard90());

  const imgW = 1200, imgH = 1600;

  /// The centred placement: anchors at their natural offsets inside a
  /// ~940×1260px sheet. [override] wins per corner.
  CvPointI dstFor(String corner, Map<String, CvPointI> override) =>
      override[corner] ??
      switch (corner) {
        'tl' => const CvPointI(250, 200),
        'tr' => const CvPointI(1080, 200),
        'br' => const CvPointI(1080, 1400),
        _ => const CvPointI(170, 1400), // bl
      };

  /// Desk + warped sheet + fiducials (L at the alt corner) + timing track +
  /// ink marks.
  ///
  /// [barShiftMiddleThird] displaces the middle third of the timing track in
  /// canvas px — the synthetic stand-in for a curled sheet. [anchorDst]
  /// repositions anchors (see [dstFor]).
  Uint8List photo({
    List<({int x, int y, int w, int h})> marks = const [],
    double barShiftMiddleThird = 0,
    Map<String, CvPointI> anchorDst = const {},
  }) {
    // 1. The sheet, in template coordinates. Canvas 0 is reserved as the
    //    warp's outside-sheet sentinel, so "black" prints as 4, not 0.
    final cw = template.canvasWidth, ch = template.canvasHeight;
    final canvas = Uint8List(cw * ch);
    canvas.fillRange(0, canvas.length, 238);
    void fill(int x, int y, int w, int h, int g) {
      for (var yy = math.max(0, y); yy < math.min(ch, y + h); yy++) {
        canvas.fillRange(
          yy * cw + math.max(0, x),
          yy * cw + math.min(cw, x + w),
          g,
        );
      }
    }

    for (final f in template.fiducials) {
      final x = (f.centerX - f.size / 2).round();
      final y = (f.centerY - f.size / 2).round();
      final e = f.size.round();
      if (f.isAltAnchor) {
        // As pdf_sheet_compiler prints it: vertical arm full height along
        // the left edge, horizontal arm full width along the bottom.
        const arm = 20; // 2.5 mm × PX_PER_MM
        fill(x, y, arm, e, 4);
        fill(x, y + e - arm, e, arm, 4);
      } else {
        fill(x, y, e, e, 4);
      }
    }
    final third = template.timingBars.length ~/ 3;
    for (var i = 0; i < template.timingBars.length; i++) {
      final t = template.timingBars[i];
      final shift = (i >= third && i < 2 * third) ? barShiftMiddleThird : 0.0;
      fill((t.x + shift).round(), t.y.round(), t.w.round(), t.h.round(), 4);
    }
    for (final m in marks) {
      fill(m.x, m.y, m.w, m.h, 18);
    }

    // 2. Canvas → photo through the anchor correspondences.
    final srcPts = [
      for (final f in template.fiducials)
        CvPointI(f.centerX.round(), f.centerY.round()),
    ];
    final dstPts = [
      for (final f in template.fiducials) dstFor(f.corner, anchorDst),
    ];
    final canvasMat = cv.grayFromBytes(cw, ch, canvas);
    final CvMat warpedMat;
    try {
      warpedMat = cv.warp(canvasMat, srcPts, dstPts, CvSizeI(imgW, imgH));
    } finally {
      cv.dispose(canvasMat);
    }
    final warped = cv.grayBytes(warpedMat);
    cv.dispose(warpedMat);

    // 3. Desk composite: warpPerspective zeroes everything outside the
    //    mapped sheet.
    final bytes = Uint8List(imgW * imgH);
    bytes.fillRange(0, bytes.length, 60);
    for (var i = 0; i < bytes.length; i++) {
      if (warped[i] != 0) bytes[i] = warped[i];
    }
    return bytes;
  }

  /// Ink ROIs for (fieldKey, optionValue) pairs — a deliberate pen-dot
  /// smaller than the outline, as on a real sheet.
  List<({int x, int y, int w, int h})> inkAt(List<(String, String)> pairs) => [
        for (final (key, value) in pairs)
          template.bubbles
              .firstWhere(
                  (b) => b.fieldKey == key && b.optionValue == value)
              .roi(fraction: 0.72),
      ];

  /// q1='C', q2='A', set='B', roll 0000073 with checksum 6
  /// (0·3+0·1+0·3+0·1+0·3+7·1+3·3 = 16 → 6).
  final happyMarks = inkAt([
    ('q1', 'C'),
    ('q2', 'A'),
    ('set', 'B'),
    ('roll1', '0'),
    ('roll2', '0'),
    ('roll3', '0'),
    ('roll4', '0'),
    ('roll5', '0'),
    ('roll6', '7'),
    ('roll7', '3'),
    ('roll8', '6'),
  ]);

  test('happy path: quadrant registration → decoded answers, clean roll', () {
    final result = OmrPipeline(cv: cv, template: template)
        .evaluateGray(imgW, imgH, photo(marks: happyMarks));

    expect(result.rejected, isFalse);
    expect(result.registrationPath, RegistrationPath.fiducialQuadrant);
    expect(result.read.responses['q1']!.chosen, {'C'},
        reason: 'inked option must decode; trace: ${result.trace}');
    expect(result.read.responses['q2']!.chosen, {'A'});
    expect(result.read.rollNoRead, '0000073');
    expect(result.read.setCodeRead, 'B');
    expect(result.read.flags, isEmpty, reason: '${result.read.flags}');
    expect(result.needsReview, isFalse);
    expect(result.read.sheetConfidence, greaterThan(0.90));
    expect(result.curvature, isNotNull);
    expect(result.curvature!.curlDetected, isFalse,
        reason: '${result.curvature}');
    expect(result.curvature!.barsChecked, template.timingBars.length);
  });

  test('trace records each stage with status and timing', () {
    final result = OmrPipeline(cv: cv, template: template)
        .evaluateGray(imgW, imgH, photo(marks: happyMarks));

    final stages = result.trace.map((e) => e.stage).toSet();
    expect(stages, containsAll(['registration', 'curvature', 'read', 'threshold']));
    for (final entry in result.trace) {
      expect(entry.elapsedMicros, greaterThanOrEqualTo(0));
      expect(entry.detail, isNotEmpty);
    }
  });

  test('rung 2: off-centre capture recovers anchors outside their quadrants', () {
    // The photographer stands left of the desk: a ~512px-wide sheet in the
    // right half of the frame (its 0.43 scale lands ON a sweep step, so
    // anchors match at true size), with BOTH left anchors past the vertical
    // midline + bleed — outside the tl/bl quadrant windows — while the right
    // two register normally. The re-search must recover the true pair (not
    // the identical square neighbours, which exclusion suppresses) and warp
    // true.
    final result = OmrPipeline(cv: cv, template: template).evaluateGray(
      imgW,
      imgH,
      photo(
        marks: happyMarks,
        anchorDst: const {
          'tl': CvPointI(704, 487),
          'tr': CvPointI(1151, 487),
          'br': CvPointI(1151, 1113),
          'bl': CvPointI(704, 1113),
        },
      ),
    );

    expect(result.rejected, isFalse);
    expect(result.registrationPath, RegistrationPath.fiducialRelaxed,
        reason: 'out-of-window anchors must fail in-quadrant then recover '
            'unrestricted; trace: ${result.trace}');
    expect(result.read.responses['q1']!.chosen, {'C'},
        reason: 'the recovered correspondences must warp bubbles true; '
            'trace: ${result.trace}');
    expect(result.read.rollNoRead, '0000073');
    expect(result.read.setCodeRead, 'B');
    // A capture this small and off-centre legitimately routes to review: the
    // binding term is curvature (1 − rms/tol ≈ 0.84 — the ~8.6px-tall timing
    // bars soften under double resampling), NOT the anchors (all ≈0.95). A
    // real still warps DOWN to canvas, where interpolation costs far less.
    // What distinguishes this rung from the page-quad one below is the
    // absence of the 0.75 trust cap: this confidence was measured, not
    // clamped by distrust of the registration path.
    expect(result.read.sheetConfidence, greaterThan(0.80));
    expect(
        result.read.flags, contains(SheetReadFlag.lowConfidence),
        reason: '${result.read.flags}');
    expect(result.needsReview, isTrue);
  });

  test('rung 3: anchors unusable → page-quad warp, capped confidence', () {
    final result = OmrPipeline(
      cv: cv,
      template: template,
      // Beyond TM_CCOEFF_NORMED's range: every anchor match is rejected, so
      // the ladder falls to the page outline.
      registrar: FiducialRegistrar(acceptScore: 1.5),
    ).evaluateGray(imgW, imgH, photo(marks: happyMarks));

    expect(result.rejected, isFalse);
    expect(result.registrationPath, RegistrationPath.pageQuad);
    expect(result.read.responses['q1']!.chosen, {'C'},
        reason: 'page-quad warp must still land the bubbles; '
            'trace: ${result.trace}');
    expect(result.read.rollNoRead, '0000073');
    expect(result.read.setCodeRead, 'B');
    expect(result.read.sheetConfidence, lessThanOrEqualTo(0.75));
    expect(result.read.flags, contains(SheetReadFlag.lowConfidence));
    expect(result.needsReview, isTrue);
  });

  test('rung 4: nothing registerable → rejected with a reason code', () {
    final blank = Uint8List(imgW * imgH);
    blank.fillRange(0, blank.length, 60);
    final result =
        OmrPipeline(cv: cv, template: template).evaluateGray(imgW, imgH, blank);

    expect(result.rejected, isTrue);
    expect(result.rejection, RejectionReason.noRegistration);
    expect(result.registrationPath, RegistrationPath.none);
    expect(result.read.responses, isEmpty);
    expect(result.read.sheetConfidence, 0);
    expect(result.needsReview, isTrue);
  });

  test('curl: displaced timing bars flag the sheet for review', () {
    final result = OmrPipeline(cv: cv, template: template).evaluateGray(
      imgW,
      imgH,
      photo(marks: happyMarks, barShiftMiddleThird: 30),
    );

    expect(result.curvature, isNotNull);
    expect(result.curvature!.curlDetected, isTrue,
        reason: 'middle-third bars displaced 30 canvas px must exceed the '
            'tolerance; report: ${result.curvature}');
    expect(result.read.flags, contains(SheetReadFlag.curlDetected));
    expect(result.needsReview, isTrue);
  });

  test('reSearch recovers an anchor parked outside its quadrant', () {
    // One perfect anchor, deliberately sitting in the bottom-left quadrant
    // while the plan looks for the top-left one — the strong-perspective
    // case the quadrant restriction exists to constrain. 40px sits mid-range
    // of the sweep over a 1200px frame for this template.
    final bytes = Uint8List(imgW * imgH);
    bytes.fillRange(0, bytes.length, 60);
    const size = 40, ax = 300, ay = 1000;
    for (var y = ay; y < ay + size; y++) {
      bytes.fillRange(y * imgW + ax, y * imgW + ax + size, 0);
    }
    final gray = cv.grayFromBytes(imgW, imgH, bytes);
    addTearDown(() => cv.dispose(gray));

    final plan = fiducialSearchPlan(template, imgW, imgH);
    final tlSearch = plan.firstWhere((s) => s.corner == 'tl');
    final registrar = FiducialRegistrar();

    final quadrant =
        registrar.register(cv, gray, [tlSearch], imageWidth: imgW);
    expect(quadrant.ok, isFalse,
        reason: 'the quadrant window must miss the anchor entirely');

    final recovered = registrar.reSearch(
      cv,
      gray,
      tlSearch,
      imageWidth: imgW,
      imageHeight: imgH,
    );
    expect(recovered, isNotNull);
    expect(recovered!.score, greaterThan(0.8));
    expect(
      recovered.center,
      CvPointI(ax + size ~/ 2, ay + size ~/ 2),
      reason: 'unrestricted search must centre on the true anchor',
    );
  });
}
