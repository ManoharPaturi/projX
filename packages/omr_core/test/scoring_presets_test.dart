/// Presets are referenced by stored ids, so their ids must be stable and their
/// parameters must validate — this file pins both.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('every preset validates against its own strategy', () {
    for (final ScoringRule rule in ScoringPresets.all) {
      expect(() => validateScoringRule(rule), returnsNormally, reason: rule.id);
      expect(
        ScoringStrategies.forKind(rule.kind).kind,
        rule.kind,
        reason: rule.id,
      );
    }
  });

  test('preset ids are unique', () {
    final Set<String> ids = <String>{
      for (final ScoringRule rule in ScoringPresets.all) rule.id,
    };
    expect(ids.length, ScoringPresets.all.length);
  });

  test('the key-correction rule is usable as an override rule', () {
    expect(
      () => const KeyCorrectionOverrideStrategy().validate(
        ScoringPresets.keyCorrectionAward4,
      ),
      returnsNormally,
    );
  });

  test('NEET / JEE-Main single correct is +4 / -1 / 0 with wrong multi-marks', () {
    final ScoringRule rule = ScoringPresets.neetJeeMain;
    final KeyEntry key = keyFor('q1', <OptionId>{'B'});

    QuestionOutcome score(Set<OptionId> chosen) =>
        SingleCorrectStrategy().score(resp(chosen), key, rule);

    expect(marksClose(score(<OptionId>{'B'}).marksAwarded, 4), isTrue);
    expect(marksClose(score(<OptionId>{'C'}).marksAwarded, -1), isTrue);
    expect(marksClose(score(<OptionId>{}).marksAwarded, 0), isTrue);
    expect(
      score(<OptionId>{'B', 'C'}).kind,
      QuestionOutcomeKind.wrong,
    );
  });

  test('the integer preset scores a clean numeric answer', () {
    final KeyEntry key = keyFor('q1', <OptionId>{}, integer: 75);
    final QuestionOutcome o = IntegerDigitsStrategy().score(
      resp(digits(75, 2)),
      key,
      ScoringPresets.integerJeeMain2026,
    );
    expect(o.kind, QuestionOutcomeKind.correct);
    expect(marksClose(o.marksAwarded, 4), isTrue);
  });

  test('legacy and current multi-correct presets differ only in anyWrong', () {
    final KeyEntry key = keyFor('q1', <OptionId>{'A', 'B'});
    final MultiCorrectPartialStrategy strategy = MultiCorrectPartialStrategy();

    // A clean subset is worth the same in both years.
    expect(
      marksClose(
        strategy
            .score(resp(<OptionId>{'A'}), key, ScoringPresets.jeeAdvMultiCorrect2026)
            .marksAwarded,
        1,
      ),
      isTrue,
    );
    expect(
      marksClose(
        strategy
            .score(resp(<OptionId>{'A'}), key, ScoringPresets.jeeAdvMultiCorrectLegacy)
            .marksAwarded,
        1,
      ),
      isTrue,
    );

    // The penalty for a wrong option is what changed.
    expect(
      marksClose(
        strategy
            .score(
              resp(<OptionId>{'A', 'C'}),
              key,
              ScoringPresets.jeeAdvMultiCorrect2026,
            )
            .marksAwarded,
        -1,
      ),
      isTrue,
    );
    expect(
      marksClose(
        strategy
            .score(
              resp(<OptionId>{'A', 'C'}),
              key,
              ScoringPresets.jeeAdvMultiCorrectLegacy,
            )
            .marksAwarded,
        -2,
      ),
      isTrue,
    );
  });

  group('param reader strictness', () {
    test('rejects a string where a number is required', () {
      const ScoringParams p = ScoringParams(<String, Object?>{'correct': '4'});
      expect(() => p.numParam('correct'), throwsArgumentError);
    });

    test('rejects a fractional value where a count is required', () {
      const ScoringParams p = ScoringParams(<String, Object?>{'digits': 2.5});
      expect(() => p.intParam('digits'), throwsArgumentError);
    });

    test('accepts an integer where a count is required', () {
      const ScoringParams p = ScoringParams(<String, Object?>{'digits': 2});
      expect(p.intParam('digits'), 2);
    });

    test('accepts string keys in a partial table, as JSON delivers them', () {
      const ScoringParams p = ScoringParams(
        <String, Object?>{'partialByCount': <String, Object?>{'1': 1, '2': 2}},
      );
      expect(p.marksByCount('partialByCount'), <int, double>{1: 1, 2: 2});
    });

    test('rejects a non-positive count in a partial table', () {
      const ScoringParams p = ScoringParams(
        <String, Object?>{'partialByCount': <int, int>{0: 1}},
      );
      expect(() => p.marksByCount('partialByCount'), throwsArgumentError);
    });

    test('distinguishes an absent param from one set to zero', () {
      const ScoringParams p = ScoringParams(<String, Object?>{'wrong': 0});
      expect(p.contains('wrong'), isTrue);
      expect(p.contains('correct'), isFalse);
      expect(p.numOr('correct', 4), 4);
      expect(p.numOr('wrong', -1), 0);
    });
  });
}
