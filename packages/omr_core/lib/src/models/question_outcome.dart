library;

import 'ids.dart';

/// Verdict for one question, in the vocabulary teachers already use.
///
/// `invalidated` is reserved for responses that must not attract marks or
/// penalty: N-of-M overflow (beyond the section cap) and multi-marked single
/// bubbles under `multiMarkAction: 'invalid'`. `bonus` is reserved for
/// key-correction awards, so a teacher can always tell "the student earned
/// this" from "the examiner gave this back".
enum QuestionOutcomeKind {
  correct,
  wrong,
  unattempted,
  partial,
  invalidated,
  bonus,
}

/// The scored result of one question: verdict, marks and a human-readable rule.
///
/// The [reason] string is the audit trail. Grading semantics are reviewed by
/// teachers who do not read Dart, so every non-obvious path emits *why* (e.g.
/// `'partial: 2 of 3 correct options'`), not just what.
final class QuestionOutcome {
  /// Creates an outcome.
  const QuestionOutcome({
    required this.questionId,
    required this.kind,
    required this.marksAwarded,
    required this.reason,
    this.baseKind,
    this.baseMarksAwarded,
  });

  /// Convenience for strategies building the common cases.
  const QuestionOutcome.of(
    this.questionId,
    this.kind,
    this.marksAwarded,
    this.reason,
  ) : baseKind = null, baseMarksAwarded = null;

  /// The question this outcome belongs to.
  final QuestionId questionId;

  /// Verdict category.
  final QuestionOutcomeKind kind;

  /// Marks awarded (may be negative). Fractional values are legitimate:
  /// partial credit and parameterised presets are both `num`-friendly.
  final double marksAwarded;

  /// Human-readable, teacher-facing explanation of how marks were derived.
  final String reason;

  /// Verdict before a key-correction override was applied, `null` when no
  /// override ran. Kept so a re-grade diff can show "was wrong -1, now bonus +4".
  final QuestionOutcomeKind? baseKind;

  /// Marks before a key-correction override, `null` when no override ran.
  final double? baseMarksAwarded;

  /// Copies, wrapping this outcome as the base of a key-correction override.
  QuestionOutcome supersededBy(QuestionOutcome override) => QuestionOutcome(
    questionId: questionId,
    kind: override.kind,
    marksAwarded: override.marksAwarded,
    reason: override.reason,
    baseKind: kind,
    baseMarksAwarded: marksAwarded,
  );

  @override
  String toString() =>
      'QuestionOutcome($questionId, $kind, $marksAwarded, '
      "'$reason')";
}
