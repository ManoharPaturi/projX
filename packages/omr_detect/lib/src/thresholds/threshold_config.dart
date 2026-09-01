import 'dart:convert';

/// Tunable detection thresholds — DATA, not code.
///
/// Every constant the pipeline depends on for a marking decision lives here,
/// versioned and serialized, so a threshold change is a new config row (kept
/// per layout version and per printer calibration), never a code change, and
/// every scan records which config read it. Constants come from the OMRChecker
/// study and the golden-harness tuning in M1.
class ThresholdConfig {
  const ThresholdConfig({
    this.version = 1,
    this.minJump = 25,
    this.confidentSurplus = 5,
    this.minGap = 30,
    this.globalLooseness = 4,
    this.fallbackWhite = 200,
    this.fallbackBlack = 100,
    this.zoneBand = 12,
    this.overfillRatio = 0.95,
    this.strayPenalty = 0.3,
    this.morphThresholdCamera = 60,
    this.morphThresholdScan = 40,
    this.curlBubbleHeightFraction = 0.30,
    this.untrustedStripStdRatio = 1.0,
    this.reviewConfidenceFloor = 0.90,
    this.strictness = Strictness.normal,
  });

  final int version;

  /// Per-strip: the smallest adjacent gap that can split empty from filled.
  final double minJump;

  /// Added to [minJump] for a *confident* split (25 + 5 = 30 in OMRChecker).
  final double confidentSurplus;
  double get confidentJump => minJump + confidentSurplus;

  /// Below this spread a strip cannot decide and falls back to the global
  /// threshold.
  final double minGap;

  /// Global pass: gaps smaller than this are ignored (paper-noise immunity).
  final double globalLooseness;

  /// Degenerate fallbacks: page reads mostly-white (nothing marked) →
  /// threshold 200; mostly-dark (everything marked) → threshold 100.
  final double fallbackWhite;
  final double fallbackBlack;

  /// Three-zone half-band (grey levels) around the strip threshold: inside
  /// the band is PROBABLE, outside is EMPTY/FILLED. Half of [minJump].
  final double zoneBand;

  /// Fill ratio above which a mark is OVERFILLED (pen gone through / scribble
  /// — the ROI saturates and its reading is suspect).
  final double overfillRatio;

  /// Confidence multiplier applied to bubbles with a detected stray mark
  /// overlapping the ROI.
  final double strayPenalty;

  /// Morphology copy threshold (stray-mark detection): camera photos vs scans
  /// need different levels — CLAHE never touches the measurement path.
  final int morphThresholdCamera;
  final int morphThresholdScan;

  /// Curl gate: timing-bar residual RMS beyond this fraction of the bubble
  /// height flags the sheet for review instead of trusting the homography.
  final double curlBubbleHeightFraction;

  /// A strip whose value std exceeds the GLOBAL std by this ratio is
  /// distrusted (all-black / all-white strips mislead largest-gap).
  final double untrustedStripStdRatio;

  /// Sheet confidence below this routes the whole sheet to human review.
  final double reviewConfidenceFloor;

  /// Capture-strictness preset: shifts the quality gates, not the marking
  /// decisions.
  final Strictness strictness;

  static const ThresholdConfig camera = ThresholdConfig();
  static const ThresholdConfig scan = ThresholdConfig(
    morphThresholdScan: 40,
  );

  ThresholdConfig copyWith({
    int? version,
    double? minJump,
    double? confidentSurplus,
    double? minGap,
    double? globalLooseness,
    double? fallbackWhite,
    double? fallbackBlack,
    double? zoneBand,
    double? overfillRatio,
    double? strayPenalty,
    int? morphThresholdCamera,
    int? morphThresholdScan,
    double? curlBubbleHeightFraction,
    double? untrustedStripStdRatio,
    double? reviewConfidenceFloor,
    Strictness? strictness,
  }) =>
      ThresholdConfig(
        version: version ?? this.version,
        minJump: minJump ?? this.minJump,
        confidentSurplus: confidentSurplus ?? this.confidentSurplus,
        minGap: minGap ?? this.minGap,
        globalLooseness: globalLooseness ?? this.globalLooseness,
        fallbackWhite: fallbackWhite ?? this.fallbackWhite,
        fallbackBlack: fallbackBlack ?? this.fallbackBlack,
        zoneBand: zoneBand ?? this.zoneBand,
        overfillRatio: overfillRatio ?? this.overfillRatio,
        strayPenalty: strayPenalty ?? this.strayPenalty,
        morphThresholdCamera: morphThresholdCamera ?? this.morphThresholdCamera,
        morphThresholdScan: morphThresholdScan ?? this.morphThresholdScan,
        curlBubbleHeightFraction:
            curlBubbleHeightFraction ?? this.curlBubbleHeightFraction,
        untrustedStripStdRatio:
            untrustedStripStdRatio ?? this.untrustedStripStdRatio,
        reviewConfidenceFloor:
            reviewConfidenceFloor ?? this.reviewConfidenceFloor,
        strictness: strictness ?? this.strictness,
      );

  Map<String, Object?> toJson() => {
        'version': version,
        'minJump': minJump,
        'confidentSurplus': confidentSurplus,
        'minGap': minGap,
        'globalLooseness': globalLooseness,
        'fallbackWhite': fallbackWhite,
        'fallbackBlack': fallbackBlack,
        'zoneBand': zoneBand,
        'overfillRatio': overfillRatio,
        'strayPenalty': strayPenalty,
        'morphThresholdCamera': morphThresholdCamera,
        'morphThresholdScan': morphThresholdScan,
        'curlBubbleHeightFraction': curlBubbleHeightFraction,
        'untrustedStripStdRatio': untrustedStripStdRatio,
        'reviewConfidenceFloor': reviewConfidenceFloor,
        'strictness': strictness.name,
      };

  static ThresholdConfig fromJson(Map<String, Object?> j) => ThresholdConfig(
        version: j['version'] as int? ?? 1,
        minJump: (j['minJump'] as num?)?.toDouble() ?? 25,
        confidentSurplus: (j['confidentSurplus'] as num?)?.toDouble() ?? 5,
        minGap: (j['minGap'] as num?)?.toDouble() ?? 30,
        globalLooseness: (j['globalLooseness'] as num?)?.toDouble() ?? 4,
        fallbackWhite: (j['fallbackWhite'] as num?)?.toDouble() ?? 200,
        fallbackBlack: (j['fallbackBlack'] as num?)?.toDouble() ?? 100,
        zoneBand: (j['zoneBand'] as num?)?.toDouble() ?? 12,
        overfillRatio: (j['overfillRatio'] as num?)?.toDouble() ?? 0.95,
        strayPenalty: (j['strayPenalty'] as num?)?.toDouble() ?? 0.3,
        morphThresholdCamera: j['morphThresholdCamera'] as int? ?? 60,
        morphThresholdScan: j['morphThresholdScan'] as int? ?? 40,
        curlBubbleHeightFraction:
            (j['curlBubbleHeightFraction'] as num?)?.toDouble() ?? 0.30,
        untrustedStripStdRatio:
            (j['untrustedStripStdRatio'] as num?)?.toDouble() ?? 1.0,
        reviewConfidenceFloor:
            (j['reviewConfidenceFloor'] as num?)?.toDouble() ?? 0.90,
        strictness:
            Strictness.values.byName(j['strictness'] as String? ?? 'normal'),
      );

  String toJsonString() => jsonEncode(toJson());

  static ThresholdConfig fromJsonString(String s) =>
      fromJson(jsonDecode(s) as Map<String, Object?>);
}

/// Capture-strictness presets (quality gates only; marking thresholds are
/// identical across presets so scores stay comparable).
enum Strictness { strict, normal, relaxed }
