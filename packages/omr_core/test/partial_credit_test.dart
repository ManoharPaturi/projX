/// Pins the multi-correct partial-credit set function to the published
/// JEE-Advanced worked example, plus the single-correct-key guard.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final ScoringRule rule = ScoringPresets.jeeAdvMultiCorrect2026;
  final KeyEntry key = keyFor('q1', <OptionId>{'A', 'B', 'D'});
  final MultiCorrectPartialStrategy strategy = MultiCorrectPartialStrategy();

  QuestionOutcome score(Set<OptionId> chosen) =>
      strategy.score(resp(chosen), key, rule);

  group('JEE-Adv worked example, K = {A, B, D} (+4 / partial / -1)', () {
    test('all keyed options marked is full marks', () {
      final QuestionOutcome o = score(<OptionId>{'A', 'B', 'D'});
      expect(o.kind, QuestionOutcomeKind.correct);
      expect(marksClose(o.marksAwarded, 4), isTrue);
      expect(o.reason, contains('correct'));
    });

    test('every 2-of-3 subset earns +2', () {
      for (final Set<OptionId> pair in <Set<OptionId>>{
        <OptionId>{'A', 'B'},
        <OptionId>{'A', 'D'},
        <OptionId>{'B', 'D'},
      }) {
        final QuestionOutcome o = score(pair);
        expect(o.kind, QuestionOutcomeKind.partial, reason: '$pair');
        expect(marksClose(o.marksAwarded, 2), isTrue, reason: '$pair');
        expect(o.reason, contains('2 of 3'), reason: '$pair');
      }
    });

    test('each single keyed option earns +1', () {
      for (final OptionId option in <OptionId>['A', 'B', 'D']) {
        final QuestionOutcome o = score(<OptionId>{option});
        expect(o.kind, QuestionOutcomeKind.partial, reason: option);
        expect(marksClose(o.marksAwarded, 1), isTrue, reason: option);
      }
    });

    test('nothing marked is unattempted at 0', () {
      final QuestionOutcome o = score(<OptionId>{});
      expect(o.kind, QuestionOutcomeKind.unattempted);
      expect(marksClose(o.marksAwarded, 0), isTrue);
    });

    test('one wrong option alongside correct ones is the full penalty', () {
      for (final Set<OptionId> chosen in <Set<OptionId>>{
        <OptionId>{'A', 'C'},
        <OptionId>{'A', 'B', 'C'},
        <OptionId>{'C'},
        <OptionId>{'C', 'E'},
      }) {
        final QuestionOutcome o = score(chosen);
        expect(o.kind, QuestionOutcomeKind.wrong, reason: '$chosen');
        expect(marksClose(o.marksAwarded, -1), isTrue, reason: '$chosen');
        expect(o.reason, contains('C'), reason: '$chosen');
      }
    });
  });

  group('guard: a single-option key is never partial', () {
    final KeyEntry singleKey = keyFor('q2', <OptionId>{'C'});

    test('choosing the only keyed option is full marks', () {
      final QuestionOutcome o = strategy.score(
        resp(<OptionId>{'C'}),
        singleKey,
        rule,
      );
      expect(o.kind, QuestionOutcomeKind.correct);
      expect(marksClose(o.marksAwarded, 4), isTrue);
      expect(o.reason, contains('correct'));
    });

    test('anything else is the wrong-option penalty', () {
      final QuestionOutcome o = strategy.score(
        resp(<OptionId>{'A'}),
        singleKey,
        rule,
      );
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -1), isTrue);
    });
  });

  group('partialByCount table lookups', () {
    test('falls back to the largest mapped count <= chosen count', () {
      // No entry for 1; a single correct option must therefore earn nothing
      // rather than crash or guess.
      final ScoringRule gapped = multiRule(
        id: 'gapped',
        partialByCount: <int, num>{2: 2, 3: 3},
      );
      final KeyEntry three = keyFor('q3', <OptionId>{'A', 'B', 'C'});
      final QuestionOutcome one = strategy.score(
        resp(<OptionId>{'A'}),
        three,
        gapped,
      );
      expect(one.kind, QuestionOutcomeKind.partial);
      expect(marksClose(one.marksAwarded, 0), isTrue);

      final QuestionOutcome two = strategy.score(
        resp(<OptionId>{'A', 'B'}),
        three,
        gapped,
      );
      expect(marksClose(two.marksAwarded, 2), isTrue);
    });

    test('a sparse table maps 2 to the largest count <= 2', () {
      final ScoringRule sparse = multiRule(
        id: 'sparse',
        partialByCount: <int, num>{1: 1, 3: 3},
      );
      final KeyEntry three = keyFor('q4', <OptionId>{'A', 'B', 'C'});
      final QuestionOutcome o = strategy.score(
        resp(<OptionId>{'A', 'B'}),
        three,
        sparse,
      );
      expect(marksClose(o.marksAwarded, 1), isTrue);
    });

    test('no table at all means a subset earns nothing but is not penalised', () {
      final ScoringRule noTable = ScoringRule(
        id: 'no-partial',
        name: 'multi without partial credit',
        kind: ScoringStrategyKind.multiCorrectPartial,
        params: const <String, Object?>{'full': 4, 'anyWrong': -2},
      );
      final QuestionOutcome o = strategy.score(
        resp(<OptionId>{'A'}),
        key,
        noTable,
      );
      expect(o.kind, QuestionOutcomeKind.partial);
      expect(marksClose(o.marksAwarded, 0), isTrue);
      expect(o.reason, contains('no partial credit table'));
    });
  });

  group('legacy scheme keeps its own penalty', () {
    test('anyWrong -2 is honoured verbatim', () {
      final QuestionOutcome o = strategy.score(
        resp(<OptionId>{'A', 'C'}),
        key,
        ScoringPresets.jeeAdvMultiCorrectLegacy,
      );
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -2), isTrue);
    });
  });

  group('malformed keys stop the run', () {
    test('an empty correct set is rejected', () {
      expect(
        () => strategy.score(
          resp(<OptionId>{'A'}),
          keyFor('q5', <OptionId>{}),
          rule,
        ),
        throwsArgumentError,
      );
    });
  });
}
