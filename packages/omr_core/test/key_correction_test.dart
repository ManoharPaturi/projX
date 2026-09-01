/// NTA key-correction states: who gets the award, and who keeps their base
/// outcome — checked per state for attempted and unattempted students.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final KeyCorrectionOverrideStrategy override = KeyCorrectionOverrideStrategy();
  final ScoringRule award4 = ScoringPresets.keyCorrectionAward4;

  /// The base outcome a single-correct strategy would have produced.
  QuestionOutcome baseFor(Set<OptionId> chosen, KeyEntry key) =>
      SingleCorrectStrategy().score(resp(chosen), key, ScoringPresets.neetJeeMain);

  group('multipleCorrectKey (options added after publishing)', () {
    final KeyEntry key = keyFor(
      'q1',
      <OptionId>{'A', 'B'},
      state: KeyEntryState.multipleCorrectKey,
    );

    test('a student who marked any keyed option gets the award', () {
      for (final OptionId option in <OptionId>['A', 'B']) {
        final QuestionOutcome o = override.apply(
          base: baseFor(<OptionId>{option}, key),
          response: resp(<OptionId>{option}),
          key: key,
          rule: award4,
        );
        expect(o.kind, QuestionOutcomeKind.bonus, reason: option);
        expect(marksClose(o.marksAwarded, 4), isTrue, reason: option);
        expect(o.baseKind, QuestionOutcomeKind.wrong, reason: option);
        expect(marksClose(o.baseMarksAwarded!, -1), isTrue, reason: option);
        expect(o.reason, contains('multipleCorrectKey'), reason: option);
      }
    });

    test('a student who marked no keyed option keeps the base outcome', () {
      final QuestionOutcome o = override.apply(
        base: baseFor(<OptionId>{'C'}, key),
        response: resp(<OptionId>{'C'}),
        key: key,
        rule: award4,
      );
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -1), isTrue);
      expect(o.baseKind, isNull);
    });

    test('an unattempted question stays unattempted', () {
      final QuestionOutcome o = override.apply(
        base: baseFor(<OptionId>{}, key),
        response: resp(<OptionId>{}),
        key: key,
        rule: award4,
      );
      expect(o.kind, QuestionOutcomeKind.unattempted);
      expect(marksClose(o.marksAwarded, 0), isTrue);
    });
  });

  group('allOptionsCorrect (every option accepted)', () {
    final KeyEntry key = keyFor(
      'q1',
      <OptionId>{'A', 'B', 'C', 'D'},
      state: KeyEntryState.allOptionsCorrect,
    );

    test('any attempt gets the award, right or wrong', () {
      for (final OptionId option in <OptionId>['A', 'C', 'D']) {
        final QuestionOutcome o = override.apply(
          base: baseFor(<OptionId>{option}, key),
          response: resp(<OptionId>{option}),
          key: key,
          rule: award4,
        );
        expect(o.kind, QuestionOutcomeKind.bonus, reason: option);
        expect(marksClose(o.marksAwarded, 4), isTrue, reason: option);
      }
    });

    test('a blank field keeps the base outcome', () {
      final QuestionOutcome o = override.apply(
        base: baseFor(<OptionId>{}, key),
        response: resp(<OptionId>{}),
        key: key,
        rule: award4,
      );
      expect(o.kind, QuestionOutcomeKind.unattempted);
      expect(marksClose(o.marksAwarded, 0), isTrue);
      expect(o.reason, 'unattempted');
    });
  });

  group('noneCorrect and dropped (question voided)', () {
    for (final KeyEntryState state in <KeyEntryState>[
      KeyEntryState.noneCorrect,
      KeyEntryState.dropped,
    ]) {
      final KeyEntry key = keyFor('q1', <OptionId>{'B'}, state: state);

      test('$state awards everyone, attempted or not', () {
        for (final Set<OptionId> chosen in <Set<OptionId>>{
          <OptionId>{'B'},
          <OptionId>{'C'},
          <OptionId>{},
        }) {
          final QuestionOutcome o = override.apply(
            base: baseFor(chosen, key),
            response: resp(chosen),
            key: key,
            rule: award4,
          );
          expect(o.kind, QuestionOutcomeKind.bonus, reason: '$state $chosen');
          expect(marksClose(o.marksAwarded, 4), isTrue, reason: '$state $chosen');
          expect(o.reason, contains('awarded to all'), reason: '$state $chosen');
        }
      });
    }
  });

  group('configuration', () {
    test('the award amount is a parameter', () {
      final ScoringRule award2 = ScoringRule(
        id: 'award-2',
        name: 'award 2',
        kind: ScoringStrategyKind.singleCorrect,
        params: const <String, Object?>{'award': 2},
      );
      final KeyEntry key = keyFor('q1', <OptionId>{'B'}, state: KeyEntryState.dropped);
      final QuestionOutcome o = override.apply(
        base: baseFor(<OptionId>{}, key),
        response: resp(<OptionId>{}),
        key: key,
        rule: award2,
      );
      expect(marksClose(o.marksAwarded, 2), isTrue);
    });

    test('a non-numeric award is rejected', () {
      const ScoringRule bad = ScoringRule(
        id: 'bad',
        name: 'bad',
        kind: ScoringStrategyKind.singleCorrect,
        params: <String, Object?>{'award': 'four'},
      );
      expect(() => override.validate(bad), throwsArgumentError);
    });

    test('a normal key returns the base outcome untouched', () {
      final KeyEntry key = keyFor('q1', <OptionId>{'B'});
      final QuestionOutcome base = baseFor(<OptionId>{'B'}, key);
      final QuestionOutcome o = override.apply(
        base: base,
        response: resp(<OptionId>{'B'}),
        key: key,
        rule: award4,
      );
      expect(identical(o, base), isTrue);
    });
  });

  group('through the grader', () {
    test('a dropped question awards a student who left it blank', () {
      final ScoringRule rule = ScoringPresets.neetJeeMain;
      final GradingReport report = ExamGrader().grade(
        GradingRequest(
          examId: 'e1',
          keyVersionId: 'v2',
          reads: <String, SheetRead>{
            's1': sheet(<QuestionId, MarkedResponse>{}),
          },
          key: <QuestionId, KeyEntry>{
            'q1': keyFor(
              'q1',
              <OptionId>{'B'},
              state: KeyEntryState.dropped,
            ),
          },
          questionOrder: <QuestionId>['q1'],
          sections: <SectionSpec>[
            SectionSpec(id: 's', questionIds: <QuestionId>['q1']),
          ],
          rules: <String, ScoringRule>{rule.id: rule},
          examDefaultRuleId: rule.id,
        ),
      );
      final ExamResult result = report.resultsByStudent['s1']!;
      expect(marksClose(result.totalMarks, 4), isTrue);
      expect(result.outcomeCounts[QuestionOutcomeKind.bonus], 1);
    });
  });
}
