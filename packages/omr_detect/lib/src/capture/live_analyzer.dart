import 'dart:typed_data';

import '../cv/opencv_service.dart'
    show CvMat, CvPointI, CvRectI, OpencvService;
import 'quality_gates.dart' show CaptureQualityGates, GateInput, GateResult;
import 'hysteresis.dart' show HysteresisState, QuadHysteresis;

/// One analysis frame from the capture source: grayscale at the analysis
/// stream's resolution (~640×480 — plan §3's live-loop budget size).
class LiveFrame {
  const LiveFrame({
    required this.width,
    required this.height,
    required this.gray,
  });

  final int width;
  final int height;

  /// Row-major 1 byte/pixel. The analyzer copies it into a mat and releases
  /// the mat before returning, so the source may reuse its buffer.
  final Uint8List gray;
}

/// Everything the scanner overlay needs from one analysis frame: the gate
/// verdicts (first failure's hint included), the hysteresis dwell driving
/// the progress ring, and the quad to draw.
class ScannerTick {
  const ScannerTick({
    required this.gates,
    required this.hysteresis,
    required this.quad,
  });

  /// One [GateResult] per gate, in priority order.
  final List<GateResult> gates;

  final HysteresisState hysteresis;

  /// The quad to overlay: the hysteresis consensus while locked on, the raw
  /// detection while searching, null when nothing was found.
  final List<CvPointI>? quad;

  /// First failed gate's coach hint, null when every gate passes.
  String? get hint {
    for (final g in gates) {
      if (!g.passed) return g.hint;
    }
    return null;
  }

  /// Every gate green — the auto-capture precondition stacked on the dwell.
  bool get allPassed => gates.every((g) => g.passed);

  /// The overlay's colour source: green only when clean AND locked on.
  bool get lockedOn => allPassed && hysteresis.tracking;

  /// The auto-shutter fired on THIS tick (one-shot; the dwell resets with
  /// it). Only a dwell built entirely from gate-passing frames can complete.
  bool get autoShutter => allPassed && hysteresis.triggered;
}

/// The live capture loop (plan §3): one grayscale frame in, one scanner
/// state out — quad detection, the five gates, and the steady-state dwell,
/// composed so the UI stays dumb and the whole loop stays host-testable.
///
/// The dwell is FED ONLY by gate-passing frames: a steady sheet under bad
/// lighting must not accumulate shutter credit, so a failing gate counts as
/// a hysteresis miss (three in a row reset the ring to zero — the honest
/// coaching behaviour, not a bug).
///
/// Pure orchestration over [OpencvService]: sharpness and exposure are
/// measured at the analysis stream's own resolution inside the quad's
/// bounding box; the absolute blur floors are calibration-SOP values to
/// retune per device (plan §9), not derivable constants.
class LiveFrameAnalyzer {
  LiveFrameAnalyzer({
    required OpencvService cv,
    CaptureQualityGates? gates,
    this.stillShortSidePx,
    this.requiredSheetPxOnStill,
  })  : _cv = cv,
        gates = gates ?? CaptureQualityGates(),
        hysteresis = QuadHysteresis();

  final OpencvService _cv;

  /// Gate configuration. Owns the blur history, so it is mutable and shared
  /// with [update] — one analyzer, one rolling window.
  final CaptureQualityGates gates;

  final QuadHysteresis hysteresis;

  /// The still capture's short side in px — the resolution gate's input.
  /// Null disables that gate (it passes silently).
  final double? stillShortSidePx;

  /// Sheet-px the still must carry on its short side for this layout
  /// (`minPxPerMm × sheetShortSideMm`, precomputed by the caller).
  final double? requiredSheetPxOnStill;

  ScannerTick update(LiveFrame frame) {
    final gray =
        _cv.grayFromBytes(frame.width, frame.height, frame.gray);
    try {
      final quad = _cv.detectQuad(gray);
      double? sharpness;
      double? exposureMean;
      if (quad != null) {
        final roi = _boundsOf(quad, frame.width, frame.height);
        sharpness = _cv.laplacianVariance(gray, roi);
        exposureMean = _cv.roiMean(gray, roi);
      }
      final results = gates.evaluate(
        GateInput(
          frameWidth: frame.width,
          frameHeight: frame.height,
          quad: quad,
          sharpness: sharpness,
          exposureMean: exposureMean,
          stillShortSidePx: stillShortSidePx,
          requiredSheetPxOnStill: requiredSheetPxOnStill,
        ),
      );
      final clean = gates.allPassed(results);
      // A gate-failing frame is a hysteresis miss: dwell credit must be
      // EARNED by clean frames (see class doc).
      final dwell = hysteresis.update(clean ? quad : null);
      return ScannerTick(
        gates: results,
        hysteresis: dwell,
        quad: dwell.tracking ? dwell.consensusQuad : quad,
      );
    } finally {
      _cv.dispose(gray);
    }
  }

  /// New sheet, torch toggled, capture session restarted.
  void reset() {
    gates.reset();
    hysteresis.reset();
  }

  static CvRectI _boundsOf(
      List<CvPointI> quad, int width, int height) {
    var minX = quad.first.x, maxX = quad.first.x;
    var minY = quad.first.y, maxY = quad.first.y;
    for (final p in quad.skip(1)) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    return CvRectI(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }
}
