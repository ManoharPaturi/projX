/// What the detection layer believes a student marked on one question field.
library;

import 'ids.dart';

/// Trust level of a single field read, as classified on-device.
///
/// `probable` and `multiMarked` never change marks by themselves — they route
/// the sheet to human review. Marks change only through the scoring strategies,
/// which are pure functions of the chosen set. This separation is deliberate:
/// a review overlay must be able to *change* `chosen`, not merely re-weight it.
enum ResponseValidity { valid, multiMarked, probable }

/// One student's marks on one question, after any human review overlay.
///
/// `humanCorrected` records that a reviewer (not the camera) decided this
/// field. Overlays are merged into `chosen` before grading, so the grader is
/// deterministic and never re-reads pixels; the flag survives so audit trails
/// and confidence reports can distinguish machine reads from human ones.
///
/// `confidence` is the weakest bubble confidence in the field (0..1) — the
/// minimum, not the average, because a field is only as trustworthy as its
/// shakiest bubble.
final class MarkedResponse {
  /// Creates a field read.
  const MarkedResponse({
    required this.chosen,
    this.humanCorrected = false,
    this.confidence = 1,
    this.validity = ResponseValidity.valid,
  });

  /// Options the student marked; empty means unattempted.
  final Set<OptionId> chosen;

  /// Whether a human reviewer finalised this field (supersedes the raw read).
  final bool humanCorrected;

  /// Weakest bubble confidence in this field, 0..1.
  final double confidence;

  /// Detection trust level; routing signal only, never a marks input.
  final ResponseValidity validity;

  /// Convenience view of [chosen] for call sites that prefer `contains`.
  bool get isAttempted => chosen.isNotEmpty;

  /// Copies with any of the fields replaced.
  MarkedResponse copyWith({
    Set<OptionId>? chosen,
    bool? humanCorrected,
    double? confidence,
    ResponseValidity? validity,
  }) => MarkedResponse(
    chosen: chosen ?? this.chosen,
    humanCorrected: humanCorrected ?? this.humanCorrected,
    confidence: confidence ?? this.confidence,
    validity: validity ?? this.validity,
  );

  @override
  String toString() =>
      'MarkedResponse($chosen, corrected: $humanCorrected, '
      'conf: $confidence, validity: $validity)';
}
