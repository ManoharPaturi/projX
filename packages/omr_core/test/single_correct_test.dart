/// Single-correct marking: every outcome, all three multi-mark actions, and the
/// parameter validation contract.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final KeyEntry key = keyFor('q1', <OptionId>{'B'});
  final SingleCorrectStrategy strategy = SingleCorrectStrategy();

  QuestionOutcome score(
    Set<OptionId> chosen,
    ScoringRule rule,
  ) => strategy.score(resp(chosen), key, rule);

  group('base outcomes (NEET / JEE-Main preset)', () {
    final ScoringRule rule = ScoringPresets.neetJeeMain;

    test('right answer earns full marks', () {
      final QuestionOutcome o = score(<OptionId>{'B'}, rule);
      expect(o.kind, QuestionOutcomeKind.correct);
      expect(marksClose(o.marksAwarded, 4), isTrue);
      expect(o.reason, 'correct: B');
    });

    test('a blank field is unattempted at zero', () {
      final QuestionOutcome o = score(<OptionId>{}, rule);
      expect(o.kind, QuestionOutcomeKind.unattempted);
      expect(marksClose(o.marksAwarded, 0), isTrue);
      expect(o.reason, 'unattempted');
    });

    test('a wrong single choice attracts the negative mark', () {
      final QuestionOutcome o = score(<OptionId>{'C'}, rule);
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -1), isTrue);
      expect(o.reason, contains('marked C'));
      expect(o.reason, contains('key B'));
    });
  });

  group('multiMarkAction', () {
    final Set<OptionId> multi = <OptionId>{'B', 'C'};

    test("'invalid' voids the question at zero marks", () {
      final QuestionOutcome o = score(
        multi,
        singleRule(multiMarkAction: 'invalid'),
      );
      expect(o.kind, QuestionOutcomeKind.invalidated);
      expect(marksClose(o.marksAwarded, 0), isTrue);
      expect(o.reason, contains('multi-marked'));
      expect(o.reason, contains('invalid'));
    });

    test("'wrong' scores it as an ordinary wrong answer", () {
      final QuestionOutcome o = score(
        multi,
        singleRule(multiMarkAction: 'wrong'),
      );
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -1), isTrue);
    });

    test("'zero' records a wrong verdict with no penalty", () {
      final QuestionOutcome o = score(
        multi,
        singleRule(multiMarkAction: 'zero'),
      );
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, 0), isTrue);
      expect(o.reason, contains('no penalty'));
    });

    test('a multi-mark including the keyed option is not correct', () {
      // Under every action the question fails to earn credit; the student
      // cannot rescue a stray mark by also bubbling the right answer.
      for (final String action in <String>['invalid', 'wrong', 'zero']) {
        final QuestionOutcome o = score(
          multi,
          singleRule(multiMarkAction: action),
        );
        expect(o.kind, isNot(QuestionOutcomeKind.correct), reason: action);
      }
    });
  });

  group('tuned parameters are honoured verbatim', () {
    test('a third-of-a-mark scheme keeps its fractions', () {
      final ScoringRule fractional = singleRule(correct: 4.5, wrong: -1.25);
      expect(
        marksClose(score(<OptionId>{'B'}, fractional).marksAwarded, 4.5),
        isTrue,
      );
      expect(
        marksClose(score(<OptionId>{'A'}, fractional).marksAwarded, -1.25),
        isTrue,
      );
    });
  });

  group('validation', () {
    test('a well-formed rule passes', () {
      expect(() => validateScoringRule(ScoringPresets.neetJeeMain), returnsNormally);
    });

    test('a non-numeric marks parameter is rejected', () {
      const ScoringRule bad = ScoringRule(
        id: 'bad',
        name: 'bad',
        kind: ScoringStrategyKind.singleCorrect,
        params: <String, Object?>{'correct': 'four'},
      );
      expect(() => validateScoringRule(bad), throwsArgumentError);
    });

    test('an unknown multiMarkAction is rejected', () {
      final ScoringRule bad = singleRule(multiMarkAction: 'ignore');
      expect(() => validateScoringRule(bad), throwsArgumentError);
    });

    test('a key row with no correct option is rejected at score time', () {
      expect(
        () => strategy.score(
          resp(<OptionId>{'A'}),
          keyFor('q2', <OptionId>{}),
          ScoringPresets.neetJeeMain,
        ),
        throwsArgumentError,
      );
    });
  });

  group('registry', () {
    test('every strategy kind resolves to a matching implementation', () {
      for (final ScoringStrategyKind kind in ScoringStrategyKind.values) {
        expect(ScoringStrategies.forKind(kind).kind, kind);
      }
    });

    test('forRule validates before returning', () {
      const ScoringRule bad = ScoringRule(
        id: 'bad',
        name: 'bad',
        kind: ScoringStrategyKind.integerDigits,
        params: <String, Object?>{'correct': true},
      );
      expect(() => ScoringStrategies.forRule(bad), throwsArgumentError);
    });
  });
}
