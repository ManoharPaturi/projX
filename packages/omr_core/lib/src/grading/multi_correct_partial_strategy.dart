part of 'scoring_strategy.dart';

/// JEE-Advanced-style multi-correct marking with partial credit.
///
/// Params:
/// * `full` (num, default 4)
/// * `partialByCount` (map count → marks, default absent = no partial credit)
/// * `anyWrong` (num, default −1)
/// * `unattempted` (num, default 0)
///
/// The score is a **pure set function** of the chosen set `C` against the key
/// set `K` — no order, no weighting, no detection confidence. That is what makes
/// it auditable against the published worked examples and reproducible on
/// re-grade:
///
/// | `C` | verdict | marks |
/// |---|---|---|
/// | `∅` | unattempted | 0 |
/// | `C = K` | correct | `full` |
/// | `C ⊂ K` (strict) | partial | `partialByCount[\|C\|]` |
/// | any element of `C` outside `K` | wrong | `anyWrong` |
///
/// `partialByCount[\|C\|]` falls back to the largest mapped count `≤ \|C\|`, so
/// a table written for three keyed options still answers a two-option key
/// sensibly. If the table has no count `≤ \|C\|` the fallback is 0 — a gap in
/// the table must cost the institute money, never silently award it.
///
/// Guard: when `|K| == 1` choosing that option is `C = K`, hence **full** marks
/// — never the `partialByCount[1]` value. A single-correct key row that has
/// wandered into a partial-credit rule must not pay out 1 of 4.
final class MultiCorrectPartialStrategy extends ScoringStrategy {
  /// Const singleton.
  const MultiCorrectPartialStrategy();

  @override
  ScoringStrategyKind get kind => ScoringStrategyKind.multiCorrectPartial;

  @override
  QuestionOutcome score(
    MarkedResponse response,
    KeyEntry key,
    ScoringRule rule,
  ) {
    final ScoringParams p = ScoringParams(rule.params);
    final String questionId = key.questionId;
    final Set<String> keyed = key.correctOptions;

    if (keyed.isEmpty) {
      throw ArgumentError(
        'multi-correct key for "$questionId" has an empty correct set; a '
        'dropped question must use KeyEntryState.dropped',
      );
    }

    final Set<String> chosen = response.chosen;
    if (chosen.isEmpty) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.unattempted,
        p.numOr('unattempted', 0),
        'unattempted',
      );
    }

    if (_setsEqual(chosen, keyed)) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.correct,
        p.numOr('full', 4),
        'correct: all ${keyed.length} keyed options (${_labelOptions(keyed)})',
      );
    }

    final Set<String> outsideKey = chosen
        .where((String o) => !keyed.contains(o))
        .toSet();
    if (outsideKey.isNotEmpty) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.wrong,
        p.numOr('anyWrong', -1),
        'wrong: marked unkeyed option(s) ${_labelOptions(outsideKey)} of '
        'key ${_labelOptions(keyed)}',
      );
    }

    // Remaining case: a strict subset of the key.
    assert(
      _isStrictSubset(chosen, keyed),
      'multi-correct: unreachable unless chosen is a strict subset of the key',
    );
    final Map<int, double> table = p.contains('partialByCount')
        ? p.marksByCount('partialByCount')
        : const <int, double>{};
    final double marks = _marksForCount(chosen.length, table);
    return QuestionOutcome.of(
      questionId,
      QuestionOutcomeKind.partial,
      marks,
      'partial: ${chosen.length} of ${keyed.length} correct options '
      '(${_labelOptions(chosen)})${table.isEmpty ? ' — no partial credit table' : ''}',
    );
  }

  @override
  void validate(ScoringRule rule) {
    final ScoringParams p = ScoringParams(rule.params);
    p.numOr('full', 4);
    p.numOr('anyWrong', -1);
    p.numOr('unattempted', 0);
    if (p.contains('partialByCount')) p.marksByCount('partialByCount');
  }

  /// Largest mapped count `≤ [count]`, else 0 (see class docs).
  static double _marksForCount(int count, Map<int, double> table) {
    final List<int> counts = table.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    for (final int c in counts) {
      if (c <= count) return table[c]!;
    }
    return 0;
  }
}
