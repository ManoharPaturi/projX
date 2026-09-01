import 'dart:math' as math;

import '../thresholds/threshold_config.dart';

/// Result of the per-strip (per-field) threshold decision.
class StripThreshold {
  const StripThreshold({
    required this.threshold,
    required this.largestGap,
    required this.confident,
    required this.fromGlobal,
    required this.distrusted,
  });

  /// Midpoint of the strip's largest adjacent gap, or the global threshold
  /// when the strip cannot decide for itself.
  final double threshold;

  /// The largest adjacent gap found in this strip's sorted values (0 when
  /// the strip fell back to global).
  final double largestGap;

  /// Whether [largestGap] reached `minJump + confidentSurplus` — a split the
  /// engine trusts outright.
  final bool confident;

  /// Why: fewer than 3 values, or spread ≤ minGap — the strip carries no
  /// empty/filled contrast of its own.
  final bool fromGlobal;

  /// Why: strip std exceeded the global std (all-black/all-white strip) —
  /// its own largest gap would mislead, so the global threshold is used.
  final bool distrusted;

  @override
  String toString() =>
      'StripThreshold(t=$threshold gap=$largestGap'
      '${confident ? ' confident' : ''}${fromGlobal ? ' global' : ''}'
      '${distrusted ? ' distrusted' : ''})';
}

/// Stage-7 output: one threshold per field, plus the global pass they fall
/// back to. Kept as data so it can be persisted with the scan and audited.
class ThresholdResult {
  const ThresholdResult({
    required this.globalThreshold,
    required this.globalLargestGap,
    required this.globalUsedFallback,
    required this.globalStd,
    required this.strips,
  });

  final double globalThreshold;

  /// Largest adjacent gap in the pooled sorted means (0 if the fallback ran).
  final double globalLargestGap;

  /// Whether the global pass found no usable gap and used the
  /// white/black fallback constants (blank or saturated page).
  final bool globalUsedFallback;

  /// Population std of the pooled means — the outlier scale strips are
  /// judged against.
  final double globalStd;

  /// fieldKey → per-strip decision.
  final Map<String, StripThreshold> strips;
}

/// Two-tier largest-gap thresholding (plan §3 stage 7, after OMRChecker).
///
/// Tier 1 pools every bubble mean on the sheet, sorts, and splits at the
/// largest adjacent gap ≥ globalLooseness. Tier 2 re-derives the threshold
/// per strip (one field's option run) where the strip's own contrast allows,
/// falling back to the global threshold when it doesn't. Per-strip recovery
/// is what keeps one shadowed column from dragging every other column's
/// threshold with it.
class ThresholdEngine {
  const ThresholdEngine({this.config = const ThresholdConfig()});

  final ThresholdConfig config;

  /// [strips] maps fieldKey → option means in option-axis order. One pass
  /// over every bubble on the sheet.
  ThresholdResult compute(Map<String, List<double>> strips) {
    final pooled = <double>[
      for (final values in strips.values) ...values,
    ];
    final global = _global(pooled);
    final globalStd = _std(pooled);

    final out = <String, StripThreshold>{};
    strips.forEach((fieldKey, values) {
      out[fieldKey] = _strip(values, global.threshold, globalStd);
    });
    return ThresholdResult(
      globalThreshold: global.threshold,
      globalLargestGap: global.gap,
      globalUsedFallback: global.fallback,
      globalStd: globalStd,
      strips: out,
    );
  }

  ({double threshold, double gap, bool fallback}) _global(List<double> values) {
    if (values.isEmpty) {
      return (threshold: config.fallbackWhite, gap: 0, fallback: true);
    }
    final sorted = [...values]..sort();
    var bestGap = 0.0;
    var bestIndex = -1;
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i] - sorted[i - 1];
      if (gap > bestGap) {
        bestGap = gap;
        bestIndex = i - 1;
      }
    }
    if (bestGap < config.globalLooseness) {
      // Uniform page: either nothing is marked (all light) or everything is
      // (all dark / underexposed). Pick the conservative split.
      final median = sorted[sorted.length ~/ 2];
      return (
        threshold: median > (config.fallbackWhite + config.fallbackBlack) / 2
            ? config.fallbackWhite
            : config.fallbackBlack,
        gap: bestGap,
        fallback: true,
      );
    }
    return (
      threshold: (sorted[bestIndex] + sorted[bestIndex + 1]) / 2,
      gap: bestGap,
      fallback: false,
    );
  }

  StripThreshold _strip(
    List<double> values,
    double global,
    double globalStd,
  ) {
    if (values.length < 3) {
      return StripThreshold(
        threshold: global,
        largestGap: 0,
        confident: false,
        fromGlobal: true,
        distrusted: false,
      );
    }
    final spread =
        values.reduce((a, b) => a > b ? a : b) - values.reduce((a, b) => a < b ? a : b);
    if (spread <= config.minGap) {
      return StripThreshold(
        threshold: global,
        largestGap: 0,
        confident: false,
        fromGlobal: true,
        distrusted: false,
      );
    }
    final stripStd = _std(values);
    if (stripStd > globalStd * config.untrustedStripStdRatio) {
      return StripThreshold(
        threshold: global,
        largestGap: 0,
        confident: false,
        fromGlobal: true,
        distrusted: true,
      );
    }
    final sorted = [...values]..sort();
    var bestGap = 0.0;
    var bestIndex = -1;
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i] - sorted[i - 1];
      if (gap > bestGap) {
        bestGap = gap;
        bestIndex = i - 1;
      }
    }
    return StripThreshold(
      threshold: (sorted[bestIndex] + sorted[bestIndex + 1]) / 2,
      largestGap: bestGap,
      confident: bestGap >= config.confidentJump,
      fromGlobal: false,
      distrusted: false,
    );
  }

  static double _std(List<double> values) {
    if (values.length < 2) return 0;
    var sum = 0.0;
    for (final v in values) {
      sum += v;
    }
    final mean = sum / values.length;
    var acc = 0.0;
    for (final v in values) {
      final d = v - mean;
      acc += d * d;
    }
    return math.sqrt(acc / values.length);
  }
}
