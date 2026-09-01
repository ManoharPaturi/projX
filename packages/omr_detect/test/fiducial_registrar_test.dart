import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart';

/// Stage-2 registration against a synthetic photo: a white sheet on a dark
/// desk, four black-square anchors at the sheet corners, searched by
/// quadrant with the plan's scale sweep. The tolerance is generous (±10 px)
/// because the swept scale quantizes the anchor size — the warp absorbs
/// sub-pixel centre error, the gate only needs coarse corners.
void main() {
  final cv = OpencvDartImpl();

  // A portrait "photo" with the sheet as a centered rectangle — a pure
  // scale+translate of the canvas, so drawn positions are exact.
  const imgW = 1200, imgH = 1600;
  const qx0 = 130.0, qy0 = 140.0, qx1 = 1070.0, qy1 = 1460.0;

  DetectionTemplate template() =>
      compileDetectionTemplate(buildStandard90());

  ({double x, double y}) canvasToImage(double cx, double cy) => (
        x: qx0 + cx / template().canvasWidth * (qx1 - qx0),
        y: qy0 + cy / template().canvasHeight * (qy1 - qy0),
      );

  /// Photo with the sheet, anchors, and (optionally) one anchor missing.
  ({Uint8List bytes, List<({double x, double y})> centers}) photo(
      {String? dropCorner}) {
    final bytes = Uint8List(imgW * imgH);
    bytes.fillRange(0, bytes.length, 60); // dark desk
    final centers = <({double x, double y})>[];
    final t = template();
    // Sheet body: 130,140 → 1070,1460.
    for (var y = qy0.toInt(); y < qy1.toInt(); y++) {
      bytes.fillRange(y * imgW + qx0.toInt(), y * imgW + qx1.toInt(), 238);
    }
    final anchorMm = 9.0; // spec fiducial sizeMm
    final pxPerMmImage = (qx1 - qx0) / t.canvasWidth * 8.0; // canvas 8px/mm
    final edge = (anchorMm * pxPerMmImage).round();
    for (final f in t.fiducials) {
      if (f.corner == dropCorner) continue;
      final c = canvasToImage(f.centerX, f.centerY);
      centers.add(c);
      final x0 = (c.x - edge / 2).round(), y0 = (c.y - edge / 2).round();
      for (var y = y0; y < y0 + edge; y++) {
        bytes.fillRange(y * imgW + x0, y * imgW + x0 + edge, 0);
      }
    }
    return (bytes: bytes, centers: centers);
  }

  test('all four anchors register inside their quadrants', () {
    final t = template();
    final p = photo();
    final gray = cv.grayFromBytes(imgW, imgH, p.bytes);
    addTearDown(() => cv.dispose(gray));

    final plan = fiducialSearchPlan(t, imgW, imgH);
    final report = FiducialRegistrar().register(cv, gray, plan, imageWidth: imgW);

    expect(report.ok, isTrue,
        reason: 'clean anchors must all be accepted '
            '(scores: ${report.matches.map((m) => m?.score.toStringAsFixed(2))})');
    expect(report.accepted.length, t.fiducials.length);
    for (var i = 0; i < report.matches.length; i++) {
      final m = report.matches[i]!;
      final want = p.centers[i];
      expect((m.center.x - want.x).abs(), lessThan(10),
          reason: 'anchor $i x: ${m.center.x} vs ${want.x.toStringAsFixed(1)}');
      expect((m.center.y - want.y).abs(), lessThan(10),
          reason: 'anchor $i y: ${m.center.y} vs ${want.y.toStringAsFixed(1)}');
    }
  });

  test('an occluded anchor is rejected, not mis-located', () {
    final t = template();
    final p = photo(dropCorner: 'br');
    final gray = cv.grayFromBytes(imgW, imgH, p.bytes);
    addTearDown(() => cv.dispose(gray));

    final plan = fiducialSearchPlan(t, imgW, imgH);
    final report = FiducialRegistrar().register(cv, gray, plan, imageWidth: imgW);

    // The missing anchor's quadrant has nothing better than desk texture:
    // either its score collapses (deviation gate) or it never clears
    // acceptScore. Either way the report must NOT claim all four.
    expect(report.ok, isFalse,
        reason: 'a missing anchor must not fabricate a match '
            '(scores: ${report.matches.map((m) => m?.score.toStringAsFixed(2))})');
    expect(report.accepted, isNot(contains(t.fiducials.indexWhere(
            (f) => f.corner == 'br'))),
        reason: 'the occluded quadrant specifically must be rejected');
  });

  test('the search plan keeps each anchor inside its own quadrant', () {
    final t = template();
    final plan = fiducialSearchPlan(t, imgW, imgH);
    expect(plan.length, 4);
    for (final s in plan) {
      // Quadrant covers its quarter of the frame plus the bleed, and never
      // crosses the far midline.
      expect(s.quadrant.width, lessThanOrEqualTo(imgW ~/ 2 + imgW * 0.08));
      final c = canvasToImage(s.canvasX, s.canvasY);
      final inside = c.x >= s.quadrant.x &&
          c.x < s.quadrant.x + s.quadrant.width &&
          c.y >= s.quadrant.y &&
          c.y < s.quadrant.y + s.quadrant.height;
      expect(inside, isTrue,
          reason: '${s.corner} anchor at (${c.x.toStringAsFixed(0)}, '
              '${c.y.toStringAsFixed(0)}) escapes rect ${s.quadrant}');
    }
  });
}
