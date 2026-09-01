part of 'scoring_strategy.dart';

/// Applies an NTA key-correction state on top of the base strategy's outcome.
///
/// Not a [ScoringStrategy]: it never scores a response on its own, it *revises*
/// an outcome the base strategy already produced, and it needs that outcome as
/// an input. Keeping it out of the sealed hierarchy means the rule registry can
/// never resolve a stored `scoring_rules` row to it by mistake.
///
/// Params: `award` (num, default 4) — the full marks handed back. The award is
/// a parameter rather than a read of the base rule's `correct` value because a
/// correction is a published, per-question decision ("+4 to all"), and it must
/// stay identical even when the underlying marking scheme is later retuned.
///
/// Who qualifies, per [KeyEntryState]:
///
/// | state | qualifies | everyone else |
/// |---|---|---|
/// | [KeyEntryState.multipleCorrectKey] | marked **any** keyed option | keeps base outcome — including its negative marks, which is the point: only responses that touched a now-correct option are made whole |
/// | [KeyEntryState.allOptionsCorrect] | attempted (chosen non-empty) | keeps base |
/// | [KeyEntryState.noneCorrect], [KeyEntryState.dropped] | **everyone**, attempted or not | — |
///
/// Awarded outcomes are recorded as [QuestionOutcomeKind.bonus] with the
/// original verdict preserved in `baseKind`, so a marksheet can distinguish
/// marks a student earned from marks an examiner handed back — and a re-grade
/// diff survives.
final class KeyCorrectionOverrideStrategy {
  /// Const singleton.
  const KeyCorrectionOverrideStrategy();

  /// Revises [base] for [key]'s correction state.
  ///
  /// Returns [base] unchanged when [key] is `normal`, so callers never need to
  /// branch on the state themselves.
  QuestionOutcome apply({
    required QuestionOutcome base,
    required MarkedResponse response,
    required KeyEntry key,
    required ScoringRule rule,
  }) {
    final double award = ScoringParams(rule.params).numOr('award', 4);
    final String was = ' — was ${base.kind.name} '
        '(${_formatMarks(base.marksAwarded)})';
    final QuestionOutcome override = switch (key.state) {
      KeyEntryState.normal => base,
      KeyEntryState.multipleCorrectKey when response.chosen.any(
        key.correctOptions.contains,
      ) =>
        QuestionOutcome.of(
          base.questionId,
          QuestionOutcomeKind.bonus,
          award,
          '${key.state.name}: +${_formatMarks(award)} awarded for marking a '
          'keyed option$was',
        ),
      KeyEntryState.allOptionsCorrect when response.chosen.isNotEmpty =>
        QuestionOutcome.of(
          base.questionId,
          QuestionOutcomeKind.bonus,
          award,
          '${key.state.name}: +${_formatMarks(award)} awarded (attempted)$was',
        ),
      KeyEntryState.noneCorrect ||
      KeyEntryState.dropped => QuestionOutcome.of(
        base.questionId,
        QuestionOutcomeKind.bonus,
        award,
        '${key.state.name}: +${_formatMarks(award)} awarded to all$was',
      ),
      _ => base,
    };
    if (identical(override, base)) return base;
    return base.supersededBy(override);
  }

  /// Checks [rule]'s params; throws [ArgumentError] on a bad shape.
  void validate(ScoringRule rule) {
    ScoringParams(rule.params).numOr('award', 4);
  }
}

/// Renders marks without a trailing `.0`, for teacher-facing reason strings.
String _formatMarks(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();
