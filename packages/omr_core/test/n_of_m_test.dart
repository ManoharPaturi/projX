/// N-of-M sections: only the first `maxCounted` responses in sheet serial order
/// count, and the overflow is voided without penalty.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  // Seven questions, serial order q1..q7, cap of five.
  final List<QuestionId> order = <QuestionId>[
    'q1',
    'q2',
    'q3',
    'q4',
    'q5',
    'q6',
    'q7',
  ];
  final Map<QuestionId, KeyEntry> key = <QuestionId, KeyEntry>{
    // Every keyed option is A, so a student choosing A is right, B is wrong.
    for (final QuestionId q in order) q: keyFor(q, <OptionId>{'A'}),
  };
  final ScoringRule rule = ScoringPresets.neetJeeMain;

  GradingReport grade(Map<QuestionId, MarkedResponse> responses) =>
      ExamGrader().grade(
        GradingRequest(
          examId: 'e1',
          keyVersionId: 'v1',
          reads: <String, SheetRead>{'s1': sheet(responses)},
          key: key,
          questionOrder: order,
          sections: <SectionSpec>[
            SectionSpec(
              id: 'sec2',
              subject: 'physics',
              maxCounted: 5,
              questionIds: order,
            ),
          ],
          rules: <String, ScoringRule>{rule.id: rule},
          examDefaultRuleId: rule.id,
        ),
      );

  test('only the first five attempts count, in sheet serial order', () {
    // Six attempts (q1, q2, q3, q4, q6, q7) with two blanks in between: the
    // blanks consume no slot, so the sixth attempt — q7 in serial order — is
    // the one that overflows.
    final GradingReport report = grade(<QuestionId, MarkedResponse>{
      'q1': resp(<OptionId>{'A'}),
      'q2': resp(<OptionId>{'A'}),
      'q3': resp(<OptionId>{'B'}),
      'q4': resp(<OptionId>{'A'}),
      'q5': resp(<OptionId>{}), // not attempted
      'q6': resp(<OptionId>{'A'}),
      'q7': resp(<OptionId>{'A'}), // sixth attempt -> beyond the cap
    });
    final ExamResult result = report.resultsByStudent['s1']!;

    expect(result.outcomeFor('q1')!.kind, QuestionOutcomeKind.correct);
    expect(result.outcomeFor('q2')!.kind, QuestionOutcomeKind.correct);
    expect(result.outcomeFor('q3')!.kind, QuestionOutcomeKind.wrong);
    expect(result.outcomeFor('q4')!.kind, QuestionOutcomeKind.correct);
    expect(result.outcomeFor('q5')!.kind, QuestionOutcomeKind.unattempted);
    expect(result.outcomeFor('q6')!.kind, QuestionOutcomeKind.correct);
    expect(result.outcomeFor('q7')!.kind, QuestionOutcomeKind.invalidated);

    // q7 would have earned +4; being voided it must earn nothing at all.
    expect(marksClose(result.outcomeFor('q7')!.marksAwarded, 0), isTrue);
    expect(result.outcomeFor('q7')!.reason, contains('section cap'));

    // Four correct at +4, one wrong at -1, the overflow voided at 0.
    expect(marksClose(result.totalMarks, 15), isTrue);
  });

  test('unattempted questions never consume a slot', () {
    // Five attempts spread across the section with blanks in between: all five
    // count, and the last two questions stay unattempted at zero.
    final GradingReport report = grade(<QuestionId, MarkedResponse>{
      'q1': resp(<OptionId>{'B'}),
      'q2': resp(<OptionId>{}),
      'q3': resp(<OptionId>{'B'}),
      'q4': resp(<OptionId>{}),
      'q5': resp(<OptionId>{'B'}),
      'q6': resp(<OptionId>{'B'}),
      'q7': resp(<OptionId>{'B'}),
    });
    final ExamResult result = report.resultsByStudent['s1']!;
    expect(result.outcomeCounts[QuestionOutcomeKind.wrong], 5);
    expect(result.outcomeCounts[QuestionOutcomeKind.unattempted], 2);
    expect(result.outcomeCounts[QuestionOutcomeKind.invalidated], 0);
    expect(marksClose(result.totalMarks, -5), isTrue);
  });

  test('overflow is voided without penalty, even when it was a wrong answer', () {
    // Six wrong attempts: the sixth must cost nothing.
    final GradingReport report = grade(<QuestionId, MarkedResponse>{
      for (final QuestionId q in order) q: resp(<OptionId>{'B'}),
    });
    final ExamResult result = report.resultsByStudent['s1']!;
    expect(result.outcomeCounts[QuestionOutcomeKind.wrong], 5);
    expect(result.outcomeCounts[QuestionOutcomeKind.invalidated], 2);
    // Five wrongs at -1; the sixth and seventh are voided at 0.
    expect(marksClose(result.totalMarks, -5), isTrue);
  });

  test('selection follows sheet serial order, not section list order', () {
    // The section lists questions in reverse; serial order still decides.
    final GradingReport report = ExamGrader().grade(
      GradingRequest(
        examId: 'e1',
        keyVersionId: 'v1',
        reads: <String, SheetRead>{
          's1': sheet(<QuestionId, MarkedResponse>{
            for (final QuestionId q in order) q: resp(<OptionId>{'A'}),
          }),
        },
        key: key,
        questionOrder: order,
        sections: <SectionSpec>[
          SectionSpec(
            id: 'sec2',
            maxCounted: 2,
            questionIds: order.reversed.toList(),
          ),
        ],
        rules: <String, ScoringRule>{rule.id: rule},
        examDefaultRuleId: rule.id,
      ),
    );
    final ExamResult result = report.resultsByStudent['s1']!;
    expect(result.outcomeFor('q1')!.kind, QuestionOutcomeKind.correct);
    expect(result.outcomeFor('q2')!.kind, QuestionOutcomeKind.correct);
    expect(result.outcomeFor('q3')!.kind, QuestionOutcomeKind.invalidated);
    expect(marksClose(result.totalMarks, 8), isTrue);
  });

  test('a voided question keeps no record of what it would have scored', () {
    final GradingReport report = grade(<QuestionId, MarkedResponse>{
      for (final QuestionId q in order) q: resp(<OptionId>{'A'}),
    });
    final QuestionOutcome outcome = report.resultsByStudent['s1']!.outcomeFor(
      'q7',
    )!;
    expect(outcome.kind, QuestionOutcomeKind.invalidated);
    expect(marksClose(outcome.marksAwarded, 0), isTrue);
    // The audit trail still shows what the base strategy had said.
    expect(outcome.baseKind, QuestionOutcomeKind.correct);
    expect(marksClose(outcome.baseMarksAwarded!, 4), isTrue);
  });

  test('a dropped question neither consumes a slot nor loses its award', () {
    final Map<QuestionId, KeyEntry> mixedKey = <QuestionId, KeyEntry>{
      for (final QuestionId q in order)
        q: q == 'q7'
            ? keyFor(q, <OptionId>{'A'}, state: KeyEntryState.dropped)
            : keyFor(q, <OptionId>{'A'}),
    };
    final GradingReport report = ExamGrader().grade(
      GradingRequest(
        examId: 'e1',
        keyVersionId: 'v1',
        reads: <String, SheetRead>{
          's1': sheet(<QuestionId, MarkedResponse>{
            for (final QuestionId q in order) q: resp(<OptionId>{'A'}),
          }),
        },
        key: mixedKey,
        questionOrder: order,
        sections: <SectionSpec>[
          SectionSpec(id: 'sec2', maxCounted: 5, questionIds: order),
        ],
        rules: <String, ScoringRule>{rule.id: rule},
        examDefaultRuleId: rule.id,
      ),
    );
    final ExamResult result = report.resultsByStudent['s1']!;
    // q7 is dropped: it awards everyone and never consumes a slot, so q6 — the
    // sixth real attempt — is the one that overflows instead.
    expect(result.outcomeFor('q7')!.kind, QuestionOutcomeKind.bonus);
    expect(marksClose(result.outcomeFor('q7')!.marksAwarded, 4), isTrue);
    expect(result.outcomeFor('q6')!.kind, QuestionOutcomeKind.invalidated);
    // Five counted correct answers plus the dropped-question award.
    expect(marksClose(result.totalMarks, 24), isTrue);
  });

  test('sections without a cap are unaffected', () {
    final GradingReport report = ExamGrader().grade(
      GradingRequest(
        examId: 'e1',
        keyVersionId: 'v1',
        reads: <String, SheetRead>{
          's1': sheet(<QuestionId, MarkedResponse>{
            for (final QuestionId q in order) q: resp(<OptionId>{'A'}),
          }),
        },
        key: key,
        questionOrder: order,
        sections: <SectionSpec>[SectionSpec(id: 'sec1', questionIds: order)],
        rules: <String, ScoringRule>{rule.id: rule},
        examDefaultRuleId: rule.id,
      ),
    );
    final ExamResult result = report.resultsByStudent['s1']!;
    expect(result.outcomeCounts[QuestionOutcomeKind.correct], 7);
    expect(marksClose(result.totalMarks, 28), isTrue);
  });

  test('a cap below one is rejected up front', () {
    expect(
      () => grade(<QuestionId, MarkedResponse>{}),
      returnsNormally,
    );
    expect(
      () => ExamGrader().grade(
        GradingRequest(
          examId: 'e1',
          keyVersionId: 'v1',
          reads: <String, SheetRead>{'s1': sheet(<QuestionId, MarkedResponse>{})},
          key: key,
          questionOrder: order,
          sections: <SectionSpec>[
            SectionSpec(id: 'sec2', maxCounted: 0, questionIds: order),
          ],
          rules: <String, ScoringRule>{rule.id: rule},
          examDefaultRuleId: rule.id,
        ),
      ),
      throwsArgumentError,
    );
  });
}
