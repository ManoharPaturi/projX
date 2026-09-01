import 'dart:math' as math;
import 'dart:typed_data';

import 'opencv_service.dart';

/// One go/no-go criterion from the M0 gate (plan §8c): [name] names the
/// pipeline symbol family it pins; [passed]/[detail] carry the verdict.
class SmokeCheck {
  const SmokeCheck(this.name, this.passed, this.detail);

  final String name;
  final bool passed;
  final String detail;

  @override
  String toString() => '${passed ? 'PASS' : 'FAIL'}  $name — $detail';
}

/// Result of [runCvSmokeProbe]: the per-family checks plus the timed
/// quad-detect frame rate (informational on host, judged against the
/// ≤32 ms budget on the low-end device).
class SmokeReport {
  const SmokeReport(this.checks, this.quadDetectUsPerFrame, this.framesTimed);

  final List<SmokeCheck> checks;
  final double quadDetectUsPerFrame;
  final int framesTimed;

  bool get allPassed => checks.every((c) => c.passed);
}

/// The M0 probe: exercises every cv call family the detection pipeline
/// ships — excluded modules throw at RUNTIME, not build time, so each family
/// must actually be called — and times a 640×480 quad-detect frame.
///
/// Runs identically on host (`flutter test` in omr_detect) and on-device
/// (`flutter test integration_test` in app), so the gate criteria live in
/// exactly one place.
SmokeReport runCvSmokeProbe(OpencvService cv, {int timingFrames = 30}) {
  return SmokeReport(
    [
      _cvtColorAndMean(cv),
      _matchTemplate(cv),
      _warpToCanvas(cv),
      _laplacianVariance(cv),
      _detectQuad(cv),
    ],
    _quadTiming(cv, timingFrames),
    timingFrames,
  );
}

SmokeCheck _cvtColorAndMean(OpencvService cv) {
  const w = 200, h = 100;
  // Left half black, right half white, in BGR (3 bytes/pixel).
  final bgr = Uint8List(w * h * 3);
  for (var i = 0; i < w * h; i++) {
    final v = (i % w) < w ~/ 2 ? 0 : 255;
    bgr[3 * i] = v;
    bgr[3 * i + 1] = v;
    bgr[3 * i + 2] = v;
  }
  final mat = cv.bgrFromBytes(w, h, bgr);
  final gray = cv.toGray(mat);
  try {
    final left = cv.roiMean(gray, CvRectI(0, 0, w ~/ 2, h));
    final right = cv.roiMean(gray, CvRectI(w ~/ 2, 0, w ~/ 2, h));
    final ok = left < 5 && right > 250;
    return SmokeCheck(
      'cvtColor + mean: half-black/half-white BGR averages to gray',
      ok,
      'left=$left right=$right (want <5 / >250)',
    );
  } finally {
    cv.dispose(gray);
    cv.dispose(mat);
  }
}

SmokeCheck _matchTemplate(OpencvService cv) {
  const w = 400, h = 400;
  // Diagonal gradient with a high-contrast 40×40 checkerboard stamped at
  // (120, 90) — the "fiducial" the registration stage hunts for.
  const fx = 120, fy = 90, fs = 40;
  final image = _grayImage(w, h, (x, y) => (x + y) % 64);
  for (var y = 0; y < fs; y++) {
    for (var x = 0; x < fs; x++) {
      image[(fy + y) * w + (fx + x)] = ((x ~/ 8 + y ~/ 8) % 2) * 255;
    }
  }
  final mat = cv.grayFromBytes(w, h, image);
  final templ = cv.crop(mat, CvRectI(fx, fy, fs, fs));
  try {
    final match = cv.matchTemplate(mat, CvRectI(0, 0, w, h), templ);
    // Quadrant restriction: searching only the top-left quadrant still finds
    // it (it lies inside), reporting coordinates in IMAGE space.
    final tl = cv.matchTemplate(mat, CvRectI(0, 0, w ~/ 2, h ~/ 2), templ);
    final ok = match.score > 0.7 &&
        match.at.x == fx &&
        match.at.y == fy &&
        tl.at.x == fx &&
        tl.at.y == fy;
    return SmokeCheck(
      'matchTemplate finds a distinctive patch at its true location',
      ok,
      'score=${match.score.toStringAsFixed(3)} at=${match.at} '
      'quadrant=${tl.at} (want >0.7 at ($fx,$fy))',
    );
  } finally {
    cv.dispose(templ);
    cv.dispose(mat);
  }
}

SmokeCheck _warpToCanvas(OpencvService cv) {
  // A white "sheet" tilted by a known projective corner set, one black
  // marker square at its top-left inside corner.
  const w = 640, h = 480;
  final image = _grayImage(w, h, (_, _) => 40); // dark desk
  const tl = CvPointI(80, 60), tr = CvPointI(590, 90), br = CvPointI(560, 430),
      bl = CvPointI(110, 400);
  _fillQuad(image, w, tl, tr, br, bl, 235);
  // Marker: 20×20 black square at ~8% into the sheet from tl along both
  // edges (inside the warp's inner-70% zone, away from borders).
  final p = _bilinear(tl, tr, br, bl, 0.08, 0.08);
  _fillRect(image, w, p.x, p.y, 20, 20, 0);

  final mat = cv.grayFromBytes(w, h, image);
  const cw = 320, ch = 400;
  final warped = cv.warpToCanvas(mat, [tl, tr, br, bl], CvSizeI(cw, ch));
  try {
    // The quad maps onto the WHOLE canvas (the inverse homography always
    // lands inside the source image), so even the canvas corner is page
    // surface — slightly darkened by the bilinear edge at the exact corner.
    final corner = cv.roiMean(warped, CvRectI(0, 0, 8, 8));
    final interior = cv.roiMean(warped, CvRectI(cw ~/ 2 - 20, ch ~/ 2 - 20, 40, 40));
    // The marker lands at its canonical canvas position. The quad
    // (~510×340 px) maps onto 320×400, so the 20px marker becomes ~12×24 px
    // on canvas — probe its CENTRE with a 6×6 window (any misplacement >3px
    // pulls in white page), and a window 15px to the right (clear of the
    // marker) as the bright counterpart.
    final cx = (0.08 * cw + 6).round(), cy = (0.08 * ch + 12).round();
    final marker = cv.roiMean(warped, CvRectI(cx - 3, cy - 3, 6, 6));
    final beside = cv.roiMean(warped, CvRectI(cx + 12, cy - 3, 6, 6));
    final ok = corner > 150 && interior > 200 && marker < 60 && beside > 150;
    return SmokeCheck(
      'getPerspectiveTransform + warpPerspective straightens a tilted page',
      ok,
      'corner=${corner.toStringAsFixed(1)} interior=${interior.toStringAsFixed(1)} '
      'marker=${marker.toStringAsFixed(1)} beside=${beside.toStringAsFixed(1)} '
      '(want >150 / >200 / <60 / >150)',
    );
  } finally {
    cv.dispose(warped);
    cv.dispose(mat);
  }
}

SmokeCheck _laplacianVariance(OpencvService cv) {
  const w = 320, h = 240;
  final flat = cv.grayFromBytes(
      w, h, Uint8List.fromList(List<int>.filled(w * h, 128)));
  final rng = math.Random(7);
  final noise = cv.grayFromBytes(w, h, _grayImage(w, h, (_, _) => rng.nextInt(256)));
  // Noise only on the left half, for the ROI check.
  final halfNoise =
      cv.grayFromBytes(w, h, _grayImage(w, h, (x, _) => x < w ~/ 2 ? rng.nextInt(256) : 128));
  try {
    final flatVar = cv.laplacianVariance(flat, null);
    final sharpVar = cv.laplacianVariance(noise, null);
    final leftVar = cv.laplacianVariance(halfNoise, CvRectI(0, 0, w ~/ 2, h));
    final rightVar = cv.laplacianVariance(halfNoise, CvRectI(w ~/ 2, 0, w ~/ 2, h));
    final ok = flatVar < 1 && sharpVar > 500 && leftVar > rightVar * 10;
    return SmokeCheck(
      'Laplacian variance separates sharp from flat regions',
      ok,
      'flat=${flatVar.toStringAsFixed(1)} noise=${sharpVar.toStringAsFixed(1)} '
      'left=${leftVar.toStringAsFixed(1)} right=${rightVar.toStringAsFixed(1)} '
      '(want <1 / >500 / left>10×right)',
    );
  } finally {
    cv.dispose(flat);
    cv.dispose(noise);
    cv.dispose(halfNoise);
  }
}

SmokeCheck _detectQuad(OpencvService cv) {
  const w = 640, h = 480;
  final image = _grayImage(w, h, (_, _) => 60);
  const tl = CvPointI(90, 70), tr = CvPointI(560, 100), br = CvPointI(530, 420),
      bl = CvPointI(120, 390);
  _fillQuad(image, w, tl, tr, br, bl, 220);

  final mat = cv.grayFromBytes(w, h, image);
  final none = cv.grayFromBytes(
      w, h, Uint8List.fromList(List<int>.filled(w * h, 90)));
  try {
    final quad = cv.detectQuad(mat);
    // No quad on a flat frame: returns null rather than a junk quad.
    final noneQuad = cv.detectQuad(none);
    var ok = quad != null && noneQuad == null;
    var detail = 'flat-frame quad=$noneQuad (want null)';
    if (quad != null) {
      // Ordered tl, tr, br, bl within a tolerance set by blur + approx.
      const expected = [tl, tr, br, bl];
      var worst = 0.0;
      for (var i = 0; i < 4; i++) {
        worst = math.max(
          worst,
          math.max(
            (quad[i].x - expected[i].x).abs().toDouble(),
            (quad[i].y - expected[i].y).abs().toDouble(),
          ),
        );
      }
      ok = ok && worst < 12;
      detail = 'worst corner error=${worst.toStringAsFixed(1)}px '
          '(want <12); $detail';
    }
    return SmokeCheck(
      'detectQuad returns the ordered corners of the largest quad',
      ok,
      detail,
    );
  } finally {
    cv.dispose(mat);
    cv.dispose(none);
  }
}

double _quadTiming(OpencvService cv, int frames) {
  const w = 640, h = 480;
  var seed = 41;
  // Deterministic pseudo-noise background so the timing includes real edge
  // work, without Random() in the hot loop.
  final image = _grayImage(w, h, (x, y) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return 60 + (seed >> 16) % 30 + ((x * 7 + y * 13) % 10);
  });
  const tl = CvPointI(80, 60), tr = CvPointI(580, 80), br = CvPointI(560, 430),
      bl = CvPointI(100, 410);
  _fillQuad(image, w, tl, tr, br, bl, 215);
  final mat = cv.grayFromBytes(w, h, image);
  try {
    // Warm-up (first call pays any lazy symbol binding).
    cv.detectQuad(mat);
    final sw = Stopwatch()..start();
    for (var i = 0; i < frames; i++) {
      cv.detectQuad(mat);
    }
    sw.stop();
    return sw.elapsedMicroseconds / frames;
  } finally {
    cv.dispose(mat);
  }
}

Uint8List _grayImage(int width, int height, int Function(int x, int y) fn) {
  final bytes = Uint8List(width * height);
  var i = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      bytes[i++] = fn(x, y).clamp(0, 255);
    }
  }
  return bytes;
}

/// Fills a convex quad via point-in-polygon over the bounding box — fine for
/// synthetic fixtures.
void _fillQuad(Uint8List image, int width, CvPointI a, CvPointI b, CvPointI c,
    CvPointI d, int value) {
  final xs = [a.x, b.x, c.x, d.x], ys = [a.y, b.y, c.y, d.y];
  final poly = [a, b, c, d];
  for (var y = ys.reduce(math.min); y <= ys.reduce(math.max); y++) {
    for (var x = xs.reduce(math.min); x <= xs.reduce(math.max); x++) {
      if (_inPoly(CvPointI(x, y), poly)) {
        image[y * width + x] = value;
      }
    }
  }
}

void _fillRect(
    Uint8List image, int width, int x0, int y0, int w, int h, int value) {
  for (var y = y0; y < y0 + h; y++) {
    for (var x = x0; x < x0 + w; x++) {
      image[y * width + x] = value;
    }
  }
}

CvPointI _bilinear(CvPointI tl, CvPointI tr, CvPointI br, CvPointI bl,
    double u, double v) {
  final top = CvPointI(
    (tl.x + u * (tr.x - tl.x)).round(),
    (tl.y + u * (tr.y - tl.y)).round(),
  );
  final bottom = CvPointI(
    (bl.x + u * (br.x - bl.x)).round(),
    (bl.y + u * (br.y - bl.y)).round(),
  );
  return CvPointI(
    (top.x + v * (bottom.x - top.x)).round(),
    (top.y + v * (bottom.y - top.y)).round(),
  );
}

bool _inPoly(CvPointI p, List<CvPointI> poly) {
  var inside = false;
  var j = poly.length - 1;
  for (var i = 0; i < poly.length; i++) {
    final xi = poly[i].x, yi = poly[i].y, xj = poly[j].x, yj = poly[j].y;
    final intersects = (yi > p.y) != (yj > p.y) &&
        p.x < (xj - xi) * (p.y - yi) / (yj - yi + 0.0) + xi;
    if (intersects) inside = !inside;
    j = i;
  }
  return inside;
}
