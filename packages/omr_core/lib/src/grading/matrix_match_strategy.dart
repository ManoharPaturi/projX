part of 'scoring_strategy.dart';

/// Matrix-match (JEE-Adv "match the following") marking.
///
/// Option ids are `'row:col'` pairs — the same shape in the key and in the
/// read — so a row is scored by comparing the columns chosen for that row with
/// the columns keyed for it. `rowCount` comes from the key, which keeps the
/// strategy independent of any layout metadata.
///
/// Params:
/// * `perRowCorrect` (num, default 1) — marks for one correctly matched row.
/// * `perRowWrong` (num, default 0) — marks for an attempted, wrong row; also
///   the penalty under `allOrNothing`.
/// * `unattempted` (num, default 0) — marks for a row left blank.
/// * `allOrNothing` (bool, default false) — `true` scores the question as a
///   whole: every row correct wins `perRowCorrect × rowCount`, anything else
///   scores `perRowWrong`. This is the scheme JEE-Adv used in some years; the
///   per-row scheme is the other. Both exist, so both are parameters.
///
/// Rows the student marked but the key does not list score as wrong rows: a
/// stray mark in a matrix grid is a real attempt at a real row, and swallowing
/// it silently would inflate marks.
final class MatrixMatchStrategy extends ScoringStrategy {
  /// Const singleton.
  const MatrixMatchStrategy();

  @override
  ScoringStrategyKind get kind => ScoringStrategyKind.matrixMatch;

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
        'matrix-match key for "$questionId" has no row:col pairs',
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

    final double perRowCorrect = p.numOr('perRowCorrect', 1);
    final double perRowWrong = p.numOr('perRowWrong', 0);
    final double unattempted = p.numOr('unattempted', 0);
    final int rowCount = _rowsOf(keyed).length;

    if (_boolParam(p, 'allOrNothing')) {
      final bool allCorrect = _setsEqual(chosen, keyed);
      return QuestionOutcome.of(
        questionId,
        allCorrect ? QuestionOutcomeKind.correct : QuestionOutcomeKind.wrong,
        allCorrect ? perRowCorrect * rowCount : perRowWrong,
        allCorrect
            ? 'correct: all $rowCount rows matched (all-or-nothing)'
            : 'wrong: not every row matched (all-or-nothing)',
      );
    }

    final Map<int, Set<String>> keyedRows = _columnsByRow(keyed);
    final Map<int, Set<String>> chosenRows = _columnsByRow(chosen);
    final List<int> orderedRows = keyedRows.keys
        .toSet()
        .union(chosenRows.keys.toSet())
        .toList()
      ..sort();

    int correctRows = 0;
    int attemptedRows = 0;
    double marks = 0;
    for (final int row in orderedRows) {
      final Set<String> keyedCols = keyedRows[row] ?? const <String>{};
      final Set<String> chosenCols = chosenRows[row] ?? const <String>{};
      if (chosenCols.isEmpty) {
        marks += unattempted;
        continue;
      }
      attemptedRows++;
      if (_setsEqual(chosenCols, keyedCols)) {
        correctRows++;
        marks += perRowCorrect;
      } else {
        marks += perRowWrong;
      }
    }

    if (attemptedRows == 0) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.unattempted,
        0,
        'unattempted',
      );
    }
    final QuestionOutcomeKind kind =
        correctRows == rowCount
            ? QuestionOutcomeKind.correct
            : correctRows > 0
            ? QuestionOutcomeKind.partial
            : QuestionOutcomeKind.wrong;
    return QuestionOutcome.of(
      questionId,
      kind,
      marks,
      switch (kind) {
        QuestionOutcomeKind.correct => 'correct: all $rowCount rows matched',
        QuestionOutcomeKind.partial =>
          'partial: $correctRows of $rowCount rows correct',
        _ => 'wrong: $correctRows of $rowCount rows correct',
      },
    );
  }

  @override
  void validate(ScoringRule rule) {
    final ScoringParams p = ScoringParams(rule.params);
    p.numOr('perRowCorrect', 1);
    p.numOr('perRowWrong', 0);
    p.numOr('unattempted', 0);
    if (p.contains('allOrNothing')) _boolParam(p, 'allOrNothing');
  }

  /// Reads a bool param (JSON-portable: accepts `bool`, or `"true"`/`"false"`).
  static bool _boolParam(ScoringParams p, String key) {
    final Object? v = p.raw[key];
    return switch (v) {
      true => true,
      false || null => false,
      'true' => true,
      'false' => false,
      _ => throw ArgumentError('param "$key" must be a bool, got ${v.runtimeType}'),
    };
  }

  /// Distinct row indices present in a `row:col` option set.
  static Set<int> _rowsOf(Set<String> options) => _columnsByRow(options).keys.toSet();

  /// Groups `row:col` options by row, mapping row → set of columns.
  ///
  /// Malformed ids are skipped: a bad option id must not zero out a whole
  /// matrix question, it just contributes nothing (detection flags it upstream).
  static Map<int, Set<String>> _columnsByRow(Set<String> options) {
    final Map<int, Set<String>> byRow = <int, Set<String>>{};
    for (final String id in options) {
      final List<String> parts = id.split(IntegerDigitsCodec.separator);
      if (parts.length != 2) continue;
      final int? row = int.tryParse(parts[0]);
      if (row == null || row < 0) continue;
      byRow.putIfAbsent(row, () => <String>{}).add(parts[1]);
    }
    return byRow;
  }
}
