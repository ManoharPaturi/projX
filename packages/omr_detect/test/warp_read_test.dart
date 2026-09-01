import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart';

/// The M1 spine over one synthetic photo: register the anchors, warp to the
/// canonical canvas, read the bubbles — the three CV-bound stages in
/// sequence, verified against marks placed at known canvas coordinates.
///
/// The photo is an affine (rectangle) placement of the sheet so drawn
/// positions are exact; the registrar's scale-sweep quantization still
/// perturbs the anchor centres by a pixel or two, which is exactly the
/// error budget the assertions encode.
void main() {
  final cv = OpencvDartImpl();
  final template = compileDetectionTemplate(buildStandard90());

  const imgW = 1200, imgH = 1600;
  const qx0 = 130.0, qy0 = 140.0, qx1 = 1070.0, qy1 = 1460.0;

  double ix(double canvasX) => qx0 + canvasX / template.canvasWidth * (qx1 - qx0);
  double iy(double canvasY) => qy0 + canvasY / template.canvasHeight * (qy1 - qy0);

  /// Desk + sheet + anchors + ink marks for [marks] (canvas-space ROIs).
  Uint8List photo(List<({int x, int y, int w, int h})> marks) {
    final bytes = Uint8List(imgW * imgH);
    bytes.fillRange(0, bytes.length, 60);
    for (var y = qy0.toInt(); y < qy1.toInt(); y++) {
      bytes.fillRange(y * imgW + qx0.toInt(), y * imgW + qx1.toInt(), 238);
    }
    final pxPerMm = (qx1 - qx0) / template.canvasWidth * 8.0;
    final edge = (9.0 * pxPerMm).round();
    for (final f in template.fiducials) {
      final cx = ix(f.centerX).round(), cy = iy(f.centerY).round();
      for (var y = cy - edge ~/ 2; y < cy + edge ~/ 2 + edge % 2; y++) {
        bytes.fillRange(y * imgW + cx - edge ~/ 2,
            y * imgW + cx - edge ~/ 2 + edge, 0);
      }
    }
    for (final m in marks) {
      final x0 = ix(m.x.toDouble()).round(),
          y0 = iy(m.y.toDouble()).round();
      final wPx = (m.w / template.canvasWidth * (qx1 - qx0)).round();
      final hPx = (m.h / template.canvasHeight * (qy1 - qy0)).round();
      for (var y = y0; y < y0 + hPx; y++) {
        bytes.fillRange(y * imgW + x0, y * imgW + x0 + wPx, 18);
      }
    }
    return bytes;
  }

  test('register → warp → read lands marks on their canvas bubbles', () {
    // Ink q1='C' and the roll's first two digits.
    final marks = <({int x, int y, int w, int h})>[
      for (final entry in [
        (template.bubbles.firstWhere(
            (b) => b.fieldKey == 'q1' && b.optionValue == 'C')),
        (template.bubbles.firstWhere(
            (b) => b.fieldKey == 'roll1' && b.optionValue == '7')),
        (template.bubbles.firstWhere(
            (b) => b.fieldKey == 'roll2' && b.optionValue == '3')),
      ])
        entry.roi(fraction: 0.72),
    ];
    final gray = cv.grayFromBytes(imgW, imgH, photo(marks));
    addTearDown(() => cv.dispose(gray));

    final plan = fiducialSearchPlan(template, imgW, imgH);
    final reg =
        FiducialRegistrar().register(cv, gray, plan, imageWidth: imgW);
    expect(reg.ok, isTrue,
        reason: 'spine needs all four anchors; got '
            '${reg.matches.map((m) => m?.score.toStringAsFixed(2))}');

    final warped = HomographyWarper().warp(cv, gray, reg, plan, template);
    addTearDown(() => cv.dispose(warped));

    // The anchors must sit at their template positions on the canvas.
    for (final f in template.fiducials) {
      final r = f.size * 0.5; // centre probe, half the anchor
      final mean = cv.roiMean(
        warped,
        CvRectI(
          (f.centerX - r).round(),
          (f.centerY - r).round(),
          (2 * r).round(),
          (2 * r).round(),
        ),
      );
      expect(mean, lessThan(90),
          reason: 'anchor ${f.corner} must land dark at its canvas position '
              '(mean=${mean.toStringAsFixed(1)})');
    }

    final samples = BubbleReader().read(cv, warped, template);
    double meanOf(String key, String value) => samples
        .firstWhere((s) => s.fieldKey == key && s.optionValue == value)
        .meanIntensity;
    expect(meanOf('q1', 'C'), lessThan(60),
        reason: 'inked option must survive the warp dark');
    expect(meanOf('q1', 'A'), greaterThan(190));
    expect(meanOf('roll1', '7'), lessThan(60));
    expect(meanOf('roll2', '3'), lessThan(60));
    expect(meanOf('roll1', '3'), greaterThan(190),
        reason: 'same digit, different column: must stay bright');
  });

  test('warp refuses a partial registration', () {
    final gray = cv.grayFromBytes(imgW, imgH, photo([]));
    addTearDown(() => cv.dispose(gray));
    final plan = fiducialSearchPlan(template, imgW, imgH);
    final reg = FiducialRegistrar(
      // Synthetic anchors are perfect, so even 0.99 clears; 1.5 is beyond
      // TM_CCOEFF_NORMED's range and rejects everything.
      acceptScore: 1.5,
    ).register(cv, gray, plan, imageWidth: imgW);
    expect(reg.ok, isFalse);
    expect(
      () => HomographyWarper().warp(cv, gray, reg, plan, template),
      throwsStateError,
    );
  });
}
