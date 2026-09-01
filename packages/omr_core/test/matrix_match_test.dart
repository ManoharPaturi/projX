/// Matrix-match scoring: per-row partial credit, all-or-nothing mode, and the
/// treatment of stray or multi-marked rows.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// A matrix response in readable form: row index → the columns bubbled for it.
typedef ScoringRow = Map<int, Set<String>>;

void main() {
  final MatrixMatchStrategy strategy = MatrixMatchStrategy();
  final ScoringRule perRow = ScoringPresets.matrixMatchPerRow;

  /// Row → correct column: 4 rows, keyed as r0→2, r1→0, r2→3, r3→1.
  final KeyEntry key = keyFor(
    'q1',
    <OptionId>{'0:2', '1:0', '2:3', '3:1'},
  );

  /// Builds a chosen set from row → bubbled column(s).
  Set<OptionId> marks(Map<int, Set<String>> rows) => <OptionId>{
    for (final MapEntry<int, Set<String>> e in rows.entries)
      for (final String col in e.value) '${e.key}:$col',
  };

  QuestionOutcome score(Map<int, Set<String>> rows, [ScoringRule? rule]) =>
      strategy.score(resp(marks(rows)), key, rule ?? perRow);

  test('every row matched earns the full row sum', () {
    final QuestionOutcome o = score(<int, Set<String>>{
      0: <String>{'2'},
      1: <String>{'0'},
      2: <String>{'3'},
      3: <String>{'1'},
    });
    expect(o.kind, QuestionOutcomeKind.correct);
    expect(marksClose(o.marksAwarded, 4), isTrue);
    expect(o.reason, contains('all 4 rows'));
  });

  test('matched rows are paid individually', () {
    // Rows 0 and 2 correct, row 1 wrong, row 3 left blank (0, not a penalty).
    final QuestionOutcome o = score(<int, Set<String>>{
      0: <String>{'2'},
      1: <String>{'1'},
      2: <String>{'3'},
    });
    expect(o.kind, QuestionOutcomeKind.partial);
    expect(marksClose(o.marksAwarded, 2), isTrue);
    expect(o.reason, 'partial: 2 of 4 rows correct');
  });

  test('a row left blank is worth nothing and costs nothing', () {
    final QuestionOutcome o = score(<int, Set<String>>{
      0: <String>{'2'},
      1: <String>{'0'},
      2: <String>{'3'},
    });
    expect(o.kind, QuestionOutcomeKind.partial);
    expect(marksClose(o.marksAwarded, 3), isTrue);
  });

  test('a wrong row penalty is configurable', () {
    final ScoringRule penalising = ScoringRule(
      id: 'matrix-penal',
      name: 'matrix with row penalty',
      kind: ScoringStrategyKind.matrixMatch,
      params: const <String, Object?>{
        'perRowCorrect': 1,
        'perRowWrong': -1,
      },
    );
    final QuestionOutcome o = score(
      <int, Set<String>>{
        0: <String>{'2'},
        1: <String>{'9'},
      },
      penalising,
    );
    expect(o.kind, QuestionOutcomeKind.partial);
    expect(marksClose(o.marksAwarded, 0), isTrue); // +1 for the hit, -1 for the miss
  });

  test('two columns bubbled in one row make that row wrong, not void', () {
    final QuestionOutcome o = score(<int, Set<String>>{
      0: <String>{'2', '3'},
      1: <String>{'0'},
      2: <String>{'3'},
      3: <String>{'1'},
    });
    expect(o.kind, QuestionOutcomeKind.partial);
    expect(marksClose(o.marksAwarded, 3), isTrue);
  });

  test('a mark in a row the key does not list counts as a wrong row', () {
    final QuestionOutcome o = score(<int, Set<String>>{
      0: <String>{'2'},
      1: <String>{'0'},
      2: <String>{'3'},
      3: <String>{'1'},
      9: <String>{'5'}, // stray row the key never lists
    });
    // All four keyed rows match, so the question is still correct; the stray
    // row costs the (default zero) wrong-row penalty rather than being ignored.
    expect(o.kind, QuestionOutcomeKind.correct);
    expect(marksClose(o.marksAwarded, 4), isTrue);
    expect(o.reason, contains('all 4 rows'));
  });

  test('nothing marked is unattempted', () {
    final QuestionOutcome o = score(<int, Set<String>>{});
    expect(o.kind, QuestionOutcomeKind.unattempted);
    expect(marksClose(o.marksAwarded, 0), isTrue);
  });

  group('all-or-nothing', () {
    final ScoringRule allOrNothing = ScoringRule(
      id: 'matrix-aon',
      name: 'matrix all or nothing',
      kind: ScoringStrategyKind.matrixMatch,
      params: const <String, Object?>{
        'perRowCorrect': 1,
        'perRowWrong': 0,
        'allOrNothing': true,
      },
    );
    final ScoringRow allCorrect = <int, Set<String>>{
      0: <String>{'2'},
      1: <String>{'0'},
      2: <String>{'3'},
      3: <String>{'1'},
    };

    test('a complete match earns perRowCorrect x rowCount', () {
      final QuestionOutcome o = score(allCorrect, allOrNothing);
      expect(o.kind, QuestionOutcomeKind.correct);
      expect(marksClose(o.marksAwarded, 4), isTrue);
      expect(o.reason, contains('all-or-nothing'));
    });

    test('three of four rows still scores nothing', () {
      final QuestionOutcome o = score(
        <int, Set<String>>{...allCorrect, 3: <String>{'2'}},
        allOrNothing,
      );
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, 0), isTrue);
    });

    test('the all-or-nothing penalty is configurable', () {
      final ScoringRule penalising = ScoringRule(
        id: 'matrix-aon-penal',
        name: 'matrix all or nothing with penalty',
        kind: ScoringStrategyKind.matrixMatch,
        params: const <String, Object?>{
          'perRowCorrect': 1,
          'perRowWrong': -2,
          'allOrNothing': true,
        },
      );
      final QuestionOutcome o = score(
        <int, Set<String>>{...allCorrect, 0: <String>{'0'}},
        penalising,
      );
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -2), isTrue);
    });
  });

  test('a key with no row pairs is rejected', () {
    expect(
      () => strategy.score(
        resp(<OptionId>{'0:1'}),
        keyFor('q2', <OptionId>{}),
        perRow,
      ),
      throwsArgumentError,
    );
  });
}
