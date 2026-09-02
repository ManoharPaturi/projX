import 'dart:typed_data';

import 'package:omr_spec/omr_spec.dart' show DetectionTemplate;

import '../../omr_detect.dart';

/// One band's margin numbers (plan §9 calibration workflow): how the EMPTY
/// and FILLED reference populations separated on THIS printer/paper/phone,
/// and where the faint reference landed relative to the split.
class CalibrationRegionReport {
  const CalibrationRegionReport({
    required this.band,
    required this.emptyMin,
    required this.fullMax,
    required this.faintMean,
    required this.midMean,
    required this.samples,
  });

  final String band;

  /// Brightest (highest-mean) empty bubble — the empty population's worst
  /// case is its DARKEST member, so the margin uses the minimum.
  final double emptyMin;

  /// Darkest filled reference bubble (the `full` level's darkest sample).
  final double fullMax;

  /// Mean of the faint-level references; the SOP compares it to [threshold].
  final double faintMean;

  /// Mean of the mid-level references.
  final double midMean;

  final int samples;

  /// The margin this band is judged on: worst-case distance between the
  /// populations. Positive = separable; the verdict compares it to the
  /// threshold engine's jump family.
  double get separation => emptyMin - fullMax;

  /// Midpoint split — where largest-gap thresholding would land between the
  /// two populations.
  double get threshold => (emptyMin + fullMax) / 2;

  CalibrationVerdict verdict(ThresholdConfig config) {
    if (separation >= config.confidentJump) {
      return CalibrationVerdict.comfortable;
    }
    if (separation >= config.minJump) {
      return CalibrationVerdict.tight;
    }
    return CalibrationVerdict.failed;
  }
}

/// Comfortable = full confident-jump margin; tight = minimum-jump only
/// (workable, but one photocopy generation from misreads); failed = the
/// populations are not reliably separable on this printer/paper/phone combo.
enum CalibrationVerdict { comfortable, tight, failed }

/// The whole calibration pass: per-band margins, registration quality, and
/// the operator-facing recommendation.
class CalibrationReport {
  const CalibrationReport({
    required this.registrationOk,
    required this.fiducialScores,
    required this.regions,
  });

  /// False ⇒ no verdict at all — the capture could not be registered and
  /// must be retaken; margins from an unwarped sheet would be fiction.
  final bool registrationOk;
  final List<double> fiducialScores;
  final List<CalibrationRegionReport> regions;

  CalibrationVerdict get overall {
    if (!registrationOk || regions.isEmpty) {
      return CalibrationVerdict.failed;
    }
    // The worst band is the sheet's verdict — a margin report that averaged
    // away a bad corner would greenlight exactly the sheets that misread.
    return regions
        .map((r) => r.verdict(const ThresholdConfig()))
        .reduce((a, b) => a.index > b.index ? a : b);
  }

  /// The settings preset the SOP tells the operator to switch to.
  String get suggestedStrictness => overall == CalibrationVerdict.comfortable
      ? 'normal'
      : 'strict';

  /// Human-readable one-liner for the CLI / app card.
  String get summary {
    if (!registrationOk) {
      return 'registration failed - retake the calibration photo (fiducials '
          'not found; flat, evenly lit, whole sheet in frame)';
    }
    final sep = regions
        .map((r) => r.separation)
        .reduce((a, b) => a < b ? a : b)
        .toStringAsFixed(0);
    return switch (overall) {
      CalibrationVerdict.comfortable =>
        'PASS - min band margin $sep grey levels (>= 30)',
      CalibrationVerdict.tight =>
        'TIGHT - min band margin $sep (>= 25 but < 30): usable, switch to '
            'the Strict preset and re-test after any photocopy generation',
      CalibrationVerdict.failed =>
        'FAIL - min band margin $sep (< 25): re-print at 100% scale on '
            'fresh paper, or reject this printer/paper stock',
    };
  }
}

/// Reads a captured photo of the printed calibration sheet and produces the
/// margin report (plan §9 / M4).
///
/// Stages are the production spine minus decode/classification: register the
/// SAME fiducials, warp to the SAME canvas, measure the SAME bubble ROIs —
/// so a passing calibration is evidence about the production read path, not
/// a parallel implementation that could disagree with it.
class CalibrationAnalyzer {
  const CalibrationAnalyzer({
    this.config = const ThresholdConfig(),
    this.filledOptions = calibrationFilledOptions,
  });

  final ThresholdConfig config;

  /// fieldKey → option indexes that carry reference ink on the printed
  /// calibration sheet (the mid level deliberately leaves one option bare).
  final Map<String, Set<int>> filledOptions;

  /// The printed fills as the analyzer understands them — kept in one place
  /// with omr_spec's `calibrationFills()` as the single source (same levels,
  /// same option indexes; duplicated as plain data so this package stays
  /// importable without the spec's PDF machinery).
  // Written out (not computed): const map keys cannot interpolate, and the
  // constructor needs this as a const default. omr_spec's calibrationFills()
  // remains the authored source; this mirrors it as plain data.
  static const Map<String, Set<int>> calibrationFilledOptions = {
    'cal_c1_t_full': {0, 1, 2, 3},
    'cal_c1_t_faint': {0, 1, 2, 3},
    'cal_c1_t_mid': {0, 1, 2},
    'cal_c1_m_full': {0, 1, 2, 3},
    'cal_c1_m_faint': {0, 1, 2, 3},
    'cal_c1_m_mid': {0, 1, 2},
    'cal_c1_b_full': {0, 1, 2, 3},
    'cal_c1_b_faint': {0, 1, 2, 3},
    'cal_c1_b_mid': {0, 1, 2},
    'cal_c2_t_full': {0, 1, 2, 3},
    'cal_c2_t_faint': {0, 1, 2, 3},
    'cal_c2_t_mid': {0, 1, 2},
    'cal_c2_m_full': {0, 1, 2, 3},
    'cal_c2_m_faint': {0, 1, 2, 3},
    'cal_c2_m_mid': {0, 1, 2},
    'cal_c2_b_full': {0, 1, 2, 3},
    'cal_c2_b_faint': {0, 1, 2, 3},
    'cal_c2_b_mid': {0, 1, 2},
    'cal_c3_t_full': {0, 1, 2, 3},
    'cal_c3_t_faint': {0, 1, 2, 3},
    'cal_c3_t_mid': {0, 1, 2},
    'cal_c3_m_full': {0, 1, 2, 3},
    'cal_c3_m_faint': {0, 1, 2, 3},
    'cal_c3_m_mid': {0, 1, 2},
    'cal_c3_b_full': {0, 1, 2, 3},
    'cal_c3_b_faint': {0, 1, 2, 3},
    'cal_c3_b_mid': {0, 1, 2},
  };

  static final RegExp _keyPattern =
      RegExp(r'^cal_c[123]_([tmb])_(full|faint|mid|empty)$');

  CalibrationReport analyze({
    required OpencvService cv,
    required DetectionTemplate template,
    required int imageWidth,
    required int imageHeight,
    required Uint8List grayBytes,
  }) {
    final gray = cv.grayFromBytes(imageWidth, imageHeight, grayBytes);
    try {
      return _analyze(cv, template, gray, imageWidth, imageHeight);
    } finally {
      cv.dispose(gray);
    }
  }

  CalibrationReport _analyze(
    OpencvService cv,
    DetectionTemplate template,
    CvMat gray,
    int imageWidth,
    int imageHeight,
  ) {
    final plan = fiducialSearchPlan(template, imageWidth, imageHeight);
    final registration = FiducialRegistrar().register(
      cv,
      gray,
      plan,
      imageWidth: imageWidth,
    );
    if (!registration.ok) {
      return CalibrationReport(
        registrationOk: false,
        fiducialScores: const [],
        regions: const [],
      );
    }
    final warped = HomographyWarper().warp(cv, gray, registration, plan, template);
    try {
      final samples = BubbleReader().read(cv, warped, template);
      return _report(registration.matches
          .whereType<FiducialMatch>()
          .map((m) => m.score)
          .toList(), samples);
    } finally {
      cv.dispose(warped);
    }
  }

  /// Pools bubble means by (band, level) and computes each band's margin.
  CalibrationReport _report(
    List<double> fiducialScores,
    List<BubbleSample> samples,
  ) {
    final empties = <String, List<double>>{};
    final fulls = <String, List<double>>{};
    final faints = <String, List<double>>{};
    final mids = <String, List<double>>{};

    for (final s in samples) {
      final match = _keyPattern.firstMatch(s.fieldKey);
      if (match == null) continue; // roll/set rows: not calibration data
      final band = match.group(1)!;
      final level = match.group(2)!;
      final filled = filledOptions[s.fieldKey] ?? const <int>{};
      final isInked = filled.contains(s.optionIndex);
      if (level == 'empty' || !isInked) {
        empties.putIfAbsent(band, () => []).add(s.meanIntensity);
      } else {
        switch (level) {
          case 'full':
            fulls.putIfAbsent(band, () => []).add(s.meanIntensity);
          case 'faint':
            faints.putIfAbsent(band, () => []).add(s.meanIntensity);
          case 'mid':
            mids.putIfAbsent(band, () => []).add(s.meanIntensity);
        }
      }
    }

    double minOf(List<double> xs) => xs.reduce((a, b) => a < b ? a : b);
    double maxOf(List<double> xs) => xs.reduce((a, b) => a > b ? a : b);
    double meanOf(List<double> xs) =>
        xs.reduce((a, b) => a + b) / xs.length;

    final regions = <CalibrationRegionReport>[];
    for (final band in ['t', 'm', 'b']) {
      final e = empties[band], f = fulls[band];
      if (e == null || e.isEmpty || f == null || f.isEmpty) continue;
      regions.add(CalibrationRegionReport(
        band: band,
        emptyMin: minOf(e),
        fullMax: maxOf(f),
        faintMean: faints[band] == null || faints[band]!.isEmpty
            ? double.nan
            : meanOf(faints[band]!),
        midMean: mids[band] == null || mids[band]!.isEmpty
            ? double.nan
            : meanOf(mids[band]!),
        samples: e.length + f.length,
      ));
    }
    return CalibrationReport(
      registrationOk: true,
      fiducialScores: fiducialScores,
      regions: regions,
    );
  }
}
