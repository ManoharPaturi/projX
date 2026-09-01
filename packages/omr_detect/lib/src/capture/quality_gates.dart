import 'dart:math' as math;

import '../cv/opencv_service.dart' show CvPointI;
import '../thresholds/threshold_config.dart' show Strictness;

/// What one capture-quality gate measured on the current analysis frame.
class GateResult {
  const GateResult({
    required this.type,
    required this.passed,
    required this.hint,
    this.measured,
    this.required,
  });

  final GateType type;
  final bool passed;

  /// Coach hint shown when this gate FAILS. The scanner overlay displays
  /// the first failed gate's hint in [GateType] declaration order.
  final String hint;

  final double? measured;
  final double? required;

  @override
  String toString() => '${type.name}: ${passed ? 'pass' : 'FAIL'} '
      '(${measured?.toStringAsFixed(1)} vs ${required?.toStringAsFixed(1)})';
}

/// The five live gates (plan §3). Declaration order = hint priority.
enum GateType {
  /// Sheet visible and well-framed: area fraction within bounds, no corner
  /// clipped by the frame edge.
  area('align the sheet inside the frame'),

  /// Flat and square: max interior-angle cosine below the threshold.
  angle('hold the phone flat over the sheet'),

  /// Sharp enough: variance-of-Laplacian vs the rolling percentile and the
  /// absolute floor for the strictness preset.
  blur('hold still — sheet is not sharp'),

  /// Exposure inside the usable band.
  exposure('adjust lighting'),

  /// The still this frame would capture resolves the layout's smallest
  /// bubble on its minor axis (≥40 px, plan §2).
  resolution('move closer — sheet too small in frame');

  const GateType(this.hint);

  /// Default failing hint; some gates substitute a directional one
  /// (closer/away, darker/brighter) at evaluation time.
  final String hint;
}

/// Per-frame inputs to the gates. Nulls mean "not measurable this frame";
/// a gate whose subject is null passes SILENTLY (it is not its call yet)
/// except [GateType.area], which fails when there is no quad at all.
class GateInput {
  const GateInput({
    required this.frameWidth,
    required this.frameHeight,
    this.quad,
    this.sharpness,
    this.exposureMean,
    this.stillShortSidePx,
    this.requiredSheetPxOnStill,
  });

  final int frameWidth;
  final int frameHeight;

  /// Detected sheet quad in analysis-stream px (tl, tr, br, bl), null when
  /// none found.
  final List<CvPointI>? quad;

  /// Variance of the Laplacian inside the quad at ~320 px long side.
  final double? sharpness;

  /// Mean gray inside the quad.
  final double? exposureMean;

  /// The still capture's short side in px (what a trigger would deliver) —
  /// only needed for the resolution gate.
  final double? stillShortSidePx;

  /// Sheet-px the still must carry on its short side to resolve this
  /// layout: `minPxPerMmOnCapture × sheetShortSideMm`, precomputed by the
  /// caller from the bound template.
  final double? requiredSheetPxOnStill;
}

/// The five capture gates (plan §3): pure functions of [GateInput] plus the
/// blur gate's rolling history — the only stateful gate, because its test is
/// RELATIVE (current sharpness vs the recent 75th percentile), which is what
/// makes it calibration-free across devices and lighting.
class CaptureQualityGates {
  CaptureQualityGates({
    this.minAreaFraction = 0.20,
    this.maxAreaFraction = 0.95,
    this.edgeMarginPx = 4,
    this.maxInteriorCosine = 0.085,
    this.exposureMin = 60,
    this.exposureMax = 200,
    this.strictness = Strictness.normal,
    this.blurRelativeFactor = 0.55,
    this.blurWindowCapacity = 24,
  }) : _blurWindow = <double>[];

  final double minAreaFraction;
  final double maxAreaFraction;

  /// A quad corner this close to the frame edge means the sheet is clipped:
  /// the warp would invent content for the missing band.
  final int edgeMarginPx;
  final double maxInteriorCosine;
  final double exposureMin;
  final double exposureMax;
  final Strictness strictness;

  /// Current sharpness must stay above this fraction of the rolling 75th
  /// percentile — a hand tremor dips below the recent norm, not below any
  /// absolute number.
  final double blurRelativeFactor;

  /// Rolling sharpness history length (~1 s at 24 fps analysis).
  final int blurWindowCapacity;

  final List<double> _blurWindow;

  /// Absolute variance-of-Laplacian floors at ~320 px long side, per
  /// strictness preset. Out-of-the-box values; the M4 calibration SOP can
  /// retune them per printer/device and persist a config row.
  static const Map<Strictness, double> blurAbsoluteFloor = {
    Strictness.strict: 120,
    Strictness.normal: 80,
    Strictness.relaxed: 50,
  };

  /// Evaluates all gates, feeding [GateInput.sharpness] into the blur
  /// history. Returns one result per [GateType] in priority order.
  List<GateResult> evaluate(GateInput input) {
    return [
      _areaGate(input),
      _angleGate(input),
      _blurGate(input),
      _exposureGate(input),
      _resolutionGate(input),
    ];
  }

  /// The first failed gate's hint, or null when all pass.
  String? hintFor(List<GateResult> results) {
    for (final r in results) {
      if (!r.passed) return r.hint;
    }
    return null;
  }

  /// Whether every gate passed — the auto-capture precondition stacked on
  /// hysteresis stability.
  bool allPassed(List<GateResult> results) =>
      results.every((r) => r.passed);

  /// Clears the blur history (new capture session, or torch toggled).
  void reset() => _blurWindow.clear();

  // ------------------------------------------------------------------ gates

  GateResult _areaGate(GateInput input) {
    final quad = input.quad;
    if (quad == null || quad.length != 4) {
      return GateResult(
        type: GateType.area,
        passed: false,
        hint: GateType.area.hint,
      );
    }
    final frameArea = input.frameWidth * input.frameHeight;
    final fraction = _polygonArea(quad) / frameArea;
    final clipped = quad.any((p) =>
        p.x < edgeMarginPx ||
        p.y < edgeMarginPx ||
        p.x > input.frameWidth - edgeMarginPx ||
        p.y > input.frameHeight - edgeMarginPx);
    final passed =
        fraction >= minAreaFraction && fraction <= maxAreaFraction && !clipped;
    return GateResult(
      type: GateType.area,
      passed: passed,
      hint: fraction < minAreaFraction
          ? 'move closer — sheet too small in frame'
          : (fraction > 0.75 || clipped)
              ? 'move away — sheet touches the frame edge'
              : GateType.area.hint,
      measured: fraction,
      required: minAreaFraction,
    );
  }

  GateResult _angleGate(GateInput input) {
    final quad = input.quad;
    if (quad == null || quad.length != 4) {
      return GateResult(
        type: GateType.angle,
        passed: false,
        hint: GateType.angle.hint,
      );
    }
    final worst = _maxInteriorCosine(quad);
    return GateResult(
      type: GateType.angle,
      passed: worst < maxInteriorCosine,
      hint: GateType.angle.hint,
      measured: worst,
      required: maxInteriorCosine,
    );
  }

  GateResult _blurGate(GateInput input) {
    final sharpness = input.sharpness;
    if (sharpness == null || !_hasQuad(input)) {
      return GateResult(type: GateType.blur, passed: true, hint: '');
    }
    _blurWindow.add(sharpness);
    if (_blurWindow.length > blurWindowCapacity) {
      _blurWindow.removeRange(0, _blurWindow.length - blurWindowCapacity);
    }

    final floor = blurAbsoluteFloor[strictness]!;
    var passed = sharpness >= floor;
    var required = floor;
    if (_blurWindow.length >= 4) {
      // Rolling 75th percentile: a few readings establish the recent norm.
      final p75 = _percentile(_blurWindow, 0.75);
      final relative = p75 * blurRelativeFactor;
      if (relative > required) required = relative;
      if (sharpness < required) passed = false;
    }
    return GateResult(
      type: GateType.blur,
      passed: passed,
      hint: GateType.blur.hint,
      measured: sharpness,
      required: required,
    );
  }

  GateResult _exposureGate(GateInput input) {
    final mean = input.exposureMean;
    if (mean == null || !_hasQuad(input)) {
      return GateResult(type: GateType.exposure, passed: true, hint: '');
    }
    final passed = mean >= exposureMin && mean <= exposureMax;
    return GateResult(
      type: GateType.exposure,
      passed: passed,
      hint: mean < exposureMin
          ? 'too dark — find brighter light'
          : 'too bright — avoid direct light on the sheet',
      measured: mean,
      required: exposureMin,
    );
  }

  GateResult _resolutionGate(GateInput input) {
    final quad = input.quad;
    final still = input.stillShortSidePx;
    final requiredPx = input.requiredSheetPxOnStill;
    if (quad == null || quad.length != 4 || still == null || requiredPx == null) {
      return GateResult(type: GateType.resolution, passed: true, hint: '');
    }
    // The sheet's share of the frame is the same in the still as in the
    // analysis stream (plan §3: quadShortSidePx / analysisShortSide ≥
    // requiredPxPerSheetShortSide / stillShortSide).
    final analysisShort =
        math.min(input.frameWidth, input.frameHeight).toDouble();
    final fractionOfFrame = _shortSide(quad) / analysisShort;
    final requiredFraction = requiredPx / still;
    return GateResult(
      type: GateType.resolution,
      passed: fractionOfFrame >= requiredFraction,
      hint: GateType.resolution.hint,
      measured: fractionOfFrame,
      required: requiredFraction,
    );
  }

  static bool _hasQuad(GateInput input) =>
      input.quad != null && input.quad!.length == 4;

  // ---------------------------------------------------------------- helpers

  static double _polygonArea(List<CvPointI> pts) {
    var acc = 0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      acc += a.x * b.y - b.x * a.y;
    }
    return acc.abs() / 2;
  }

  /// Largest |cos| of the four interior angles: 0 for a perfect rectangle,
  /// →1 as a corner collapses. Tilted-phone perspective bows this first.
  static double _maxInteriorCosine(List<CvPointI> quad) {
    var worst = 0.0;
    for (var i = 0; i < 4; i++) {
      final prev = quad[(i + 3) % 4];
      final cur = quad[i];
      final next = quad[(i + 1) % 4];
      final ax = prev.x - cur.x, ay = prev.y - cur.y;
      final bx = next.x - cur.x, by = next.y - cur.y;
      final denom = math.sqrt((ax * ax + ay * ay) * (bx * bx + by * by));
      if (denom == 0) return 1; // degenerate corner
      final cos = (ax * bx + ay * by) / denom;
      if (cos.abs() > worst) worst = cos.abs();
    }
    return worst;
  }

  static double _shortSide(List<CvPointI> quad) {
    var min = double.maxFinite;
    for (var i = 0; i < 4; i++) {
      final a = quad[i];
      final b = quad[(i + 1) % 4];
      final len = math
          .sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y));
      if (len < min) min = len;
    }
    return min;
  }

  static double _percentile(List<double> values, double p) {
    final sorted = [...values]..sort();
    return sorted[(p * (sorted.length - 1)).round()];
  }
}
