import 'dart:math' as math;

import 'package:omr_spec/omr_spec.dart' show BlockType;

import '../models/bubble_read.dart';
import '../thresholds/threshold_config.dart';

/// Registration-side quality inputs to the sheet confidence.
///
/// Defaults construct an "unknown registration" that contributes no caps, so
/// tests and the golden harness can aggregate fields in isolation.
class RegistrationQuality {
  const RegistrationQuality({
    this.fiducialScores = const <double>[],
    this.timingResidualRatio = 0,
    this.confidenceCap,
  });

  /// Per-corner template-match scores from stage 2, 0..1.
  final List<double> fiducialScores;

  /// Timing-bar residual RMS over tolerance — [CurvatureGate]'s ratio. 0 for
  /// a flat sheet; above 1 means curled.
  final double timingResidualRatio;

  /// Hard cap applied when registration used a fallback (timing-track affine
  /// warp): the read proceeds but is never trusted above this.
  final double? confidenceCap;
}

/// Stage-10 output: the field list with per-bubble and per-field confidence
/// populated, plus the sheet-level number review routing keys on.
class SheetAssessment {
  const SheetAssessment({
    required this.fields,
    required this.sheetConfidence,
    required this.rollConfidence,
  });

  /// Same fields, same order, with [FieldRead.confidence] and every bubble's
  /// [BubbleRead.confidence] filled in.
  final List<FieldRead> fields;

  /// min(0.95, weakest fiducial, 1 − timing residual ratio, median field
  /// confidence, registration cap), clamped to 0..1.
  final double sheetConfidence;

  /// Weakest roll-digit field confidence (1 when the sheet has no roll
  /// block) — a roll number is only as good as its shakiest digit.
  final double rollConfidence;
}

/// Stage 10: turns zones and distances into the numeric confidence model the
/// review router consumes (plan §3).
///
/// A bubble's confidence is how far OUTSIDE the uncertain band its mean
/// sits, normalised by the band width: at the band edge 0, one band beyond
/// 1. Stray marks multiply by the stray penalty; PROBABLE fields lose 0.25,
/// MULTIPLE lose 0.5. Field confidence is the MINIMUM over its bubbles — a
/// field is only as trustworthy as its shakiest bubble — and sheet
/// confidence is the minimum again, over registration quality and the
/// (conservative, lower-median) field confidence.
class ConfidenceAggregator {
  const ConfidenceAggregator({this.config = const ThresholdConfig()});

  final ThresholdConfig config;

  SheetAssessment assess(
    List<FieldRead> fields, {
    RegistrationQuality registration = const RegistrationQuality(),
  }) {
    var rollConfidence = 1.0;
    final fieldConfidences = <double>[];
    final scoredFields = <FieldRead>[];

    for (final field in fields) {
      final scoredBubbles = <BubbleRead>[];
      var weakestBubble = 1.0;
      for (final bubble in field.bubbles) {
        final confidence = bubbleConfidence(bubble);
        if (confidence < weakestBubble) weakestBubble = confidence;
        scoredBubbles.add(bubble.copyWith(confidence: confidence));
      }

      var fieldConfidence = weakestBubble;
      switch (field.markClass) {
        case MarkClass.probable || MarkClass.overfilled:
          fieldConfidence -= 0.25;
        case MarkClass.multiple:
          fieldConfidence -= 0.5;
        case MarkClass.blank || MarkClass.filled:
          break;
      }
      fieldConfidence = _clamp01(fieldConfidence);
      fieldConfidences.add(fieldConfidence);

      if (field.blockType == BlockType.rollDigits &&
          fieldConfidence < rollConfidence) {
        rollConfidence = fieldConfidence;
      }

      scoredFields.add(
        field.copyWith(bubbles: scoredBubbles, confidence: fieldConfidence),
      );
    }

    final candidates = <double>[
      0.95, // detection is never certain — cap below 1 by design
      _lowerMedian(fieldConfidences),
      1 - registration.timingResidualRatio,
      ...registration.fiducialScores,
      ?registration.confidenceCap,
    ];
    final sheetConfidence = _clamp01(candidates.reduce(math.min));

    return SheetAssessment(
      fields: scoredFields,
      sheetConfidence: sheetConfidence,
      rollConfidence: rollConfidence,
    );
  }

  /// 0 at the band edge, 1 one band-width beyond it; stray marks multiply by
  /// the stray penalty.
  double bubbleConfidence(BubbleRead bubble) {
    final distance =
        (bubble.sample.meanIntensity - bubble.thresholdUsed).abs();
    final base = _clamp01((distance - config.zoneBand) / config.zoneBand);
    final stray =
        bubble.sample.strayMark ? 1 - config.strayPenalty : 1.0;
    return _clamp01(base * stray);
  }

  /// Lower median: for an even count this takes the LOWER of the two middle
  /// values — when half the fields are doubtful, the doubtful half wins.
  static double _lowerMedian(List<double> values) {
    if (values.isEmpty) return 1;
    final sorted = [...values]..sort();
    return sorted[(sorted.length - 1) ~/ 2];
  }

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
}
