part of 'scoring_strategy.dart';

/// Classic one-right-answer marking: `+correct` / `−wrong` / `0` unattempted.
///
/// Params:
/// * `correct` (num, default 4)
/// * `wrong` (num, default −1)
/// * `unattempted` (num, default 0)
/// * `multiMarkAction` (`invalid` | `wrong` | `zero`, default `wrong`)
///
/// A multi-marked bubble is *not* automatically a wrong answer: a stray pen
/// mark next to a clear choice is the single most common detection dispute, so
/// what happens to it is an explicit, per-question decision. The three actions
/// mean, for a response with more than one option chosen:
/// * `invalid` — [QuestionOutcomeKind.invalidated], 0 marks. The question is
///   void for this student; it must not drag the total down on what may be a
///   detection artifact.
/// * `wrong` — scored as a wrong answer (attracts `wrong`, i.e. negative).
/// * `zero` — verdict [QuestionOutcomeKind.wrong] (it did not earn credit) but
///   0 marks, so it counts as an attempt in analytics without penalising.
final class SingleCorrectStrategy extends ScoringStrategy {
  /// Const singleton.
  const SingleCorrectStrategy();

  @override
  ScoringStrategyKind get kind => ScoringStrategyKind.singleCorrect;

  @override
  QuestionOutcome score(
    MarkedResponse response,
    KeyEntry key,
    ScoringRule rule,
  ) {
    final ScoringParams p = ScoringParams(rule.params);
    final String questionId = key.questionId;

    if (key.correctOptions.isEmpty) {
      throw ArgumentError(
        'single-correct key for "$questionId" has no correct option; use a '
        'key-correction state such as dropped instead',
      );
    }
    if (response.chosen.isEmpty) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.unattempted,
        p.numOr('unattempted', 0),
        'unattempted',
      );
    }

    final String action = p.enumOr(
      'multiMarkAction',
      const <String>{'invalid', 'wrong', 'zero'},
      'wrong',
    );
    final String marked = _labelOptions(response.chosen);

    if (response.chosen.length > 1) {
      return switch (action) {
        'invalid' => QuestionOutcome.of(
          questionId,
          QuestionOutcomeKind.invalidated,
          0,
          'invalidated: multi-marked ($marked) — multiMarkAction invalid',
        ),
        'zero' => QuestionOutcome.of(
          questionId,
          QuestionOutcomeKind.wrong,
          0,
          'wrong, no penalty: multi-marked ($marked) — multiMarkAction zero',
        ),
        _ => QuestionOutcome.of(
          questionId,
          QuestionOutcomeKind.wrong,
          p.numOr('wrong', -1),
          'wrong: multi-marked ($marked) — multiMarkAction wrong',
        ),
      };
    }

    if (_setsEqual(response.chosen, key.correctOptions)) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.correct,
        p.numOr('correct', 4),
        'correct: $marked',
      );
    }
    return QuestionOutcome.of(
      questionId,
      QuestionOutcomeKind.wrong,
      p.numOr('wrong', -1),
      'wrong: marked $marked, key ${_labelOptions(key.correctOptions)}',
    );
  }

  @override
  void validate(ScoringRule rule) {
    final ScoringParams p = ScoringParams(rule.params);
    p.numOr('correct', 4);
    p.numOr('wrong', -1);
    p.numOr('unattempted', 0);
    p.enumOr(
      'multiMarkAction',
      const <String>{'invalid', 'wrong', 'zero'},
      'wrong',
    );
  }
}
