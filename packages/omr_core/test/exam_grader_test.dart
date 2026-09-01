/// End-to-end mini exam: three students, five questions, two sections, negative
/// marking — every total hand-computed.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final ScoringRule single = ScoringPresets.neetJeeMain;
  final List<QuestionId> order = <QuestionId>['q1', 'q2', 'q3', 'q4', 'q5'];

  final Map<QuestionId, KeyEntry> key = <QuestionId, KeyEntry>{
    'q1': keyFor('q1', <OptionId>{'A'}),
    'q2': keyFor('q2', <OptionId>{'B'}),
    'q3': keyFor('q3', <OptionId>{'C'}),
    'q4': keyFor('q4', <OptionId>{'D'}),
    'q5': keyFor('q5', <OptionId>{'A'}),
  };

  final List<SectionSpec> sections = <SectionSpec>[
    SectionSpec(
      id: 'physics',
      subject: 'physics',
      questionIds: <QuestionId>['q1', 'q2', 'q3'],
    ),
    SectionSpec(
      id: 'chemistry',
      subject: 'chemistry',
      questionIds: <QuestionId>['q4', 'q5'],
    ),
  ];

  /// The three sheets, hand-worked:
  /// * s1: A / A / C / D / blank   → +4 −1 +4 +4  0 = 11
  /// * s2: A / B / A / A / A      → +4 +4 −1 −1 +4 = 10
  /// * s3: B / A / A / A / B      → −1 −1 −1 −1 −1 = −5
  final Map<String, SheetRead> reads = <String, SheetRead>{
    's1': sheet(<QuestionId, MarkedResponse>{
      'q1': resp(<OptionId>{'A'}),
      'q2': resp(<OptionId>{'A'}),
      'q3': resp(<OptionId>{'C'}),
      'q4': resp(<OptionId>{'D'}),
    }),
    's2': sheet(<QuestionId, MarkedResponse>{
      'q1': resp(<OptionId>{'A'}),
      'q2': resp(<OptionId>{'B'}),
      'q3': resp(<OptionId>{'A'}),
      'q4': resp(<OptionId>{'A'}),
      'q5': resp(<OptionId>{'A'}),
    }),
    's3': sheet(<QuestionId, MarkedResponse>{
      'q1': resp(<OptionId>{'B'}),
      'q2': resp(<OptionId>{'A'}),
      'q3': resp(<OptionId>{'A'}),
      'q4': resp(<OptionId>{'A'}),
      'q5': resp(<OptionId>{'B'}),
    }),
  };

  GradingReport grade({
    Map<String, SheetRead>? withReads,
    List<SectionSpec>? withSections,
    Map<QuestionId, KeyEntry>? withKey,
    bool regrade = false,
  }) => ExamGrader().grade(
    GradingRequest(
      examId: 'exam-1',
      keyVersionId: 'kv-1',
      reads: withReads ?? reads,
      key: withKey ?? key,
      questionOrder: order,
      sections: withSections ?? sections,
      rules: <String, ScoringRule>{single.id: single},
      examDefaultRuleId: single.id,
      regrade: regrade,
    ),
  );

  test('per-student totals match the hand-worked marks', () {
    final GradingReport report = grade();
    expect(report.resultsByStudent.keys, containsAll(<String>['s1', 's2', 's3']));
    expect(marksClose(report.resultsByStudent['s1']!.totalMarks, 11), isTrue);
    expect(marksClose(report.resultsByStudent['s2']!.totalMarks, 10), isTrue);
    expect(marksClose(report.resultsByStudent['s3']!.totalMarks, -5), isTrue);
  });

  test('a question missing from a read is simply unattempted', () {
    // s1's sheet has no entry for q5 at all.
    final ExamResult s1 = grade().resultsByStudent['s1']!;
    expect(s1.outcomeFor('q5')!.kind, QuestionOutcomeKind.unattempted);
    expect(s1.outcomes.length, order.length);
  });

  test('outcome counts are reported per verdict', () {
    final ExamResult s1 = grade().resultsByStudent['s1']!;
    expect(s1.outcomeCounts[QuestionOutcomeKind.correct], 3);
    expect(s1.outcomeCounts[QuestionOutcomeKind.wrong], 1);
    expect(s1.outcomeCounts[QuestionOutcomeKind.unattempted], 1);
    expect(s1.attemptedCount, 4);

    final ExamResult s3 = grade().resultsByStudent['s3']!;
    expect(s3.outcomeCounts[QuestionOutcomeKind.wrong], 5);
    expect(marksClose(s3.negativeMarks, -5), isTrue);
  });

  test('subject totals split by section', () {
    final Map<String, ExamResult> results = grade().resultsByStudent;
    // s1: physics 4 - 1 + 4 = 7, chemistry 4 + 0 = 4.
    expect(marksClose(results['s1']!.subjectTotals['physics']!, 7), isTrue);
    expect(marksClose(results['s1']!.subjectTotals['chemistry']!, 4), isTrue);
    // s2: physics 4 + 4 - 1 = 7, chemistry -1 + 4 = 3.
    expect(marksClose(results['s2']!.subjectTotals['physics']!, 7), isTrue);
    expect(marksClose(results['s2']!.subjectTotals['chemistry']!, 3), isTrue);
    // s3: everything wrong.
    expect(marksClose(results['s3']!.subjectTotals['physics']!, -3), isTrue);
    expect(marksClose(results['s3']!.subjectTotals['chemistry']!, -2), isTrue);
  });

  test('summary statistics over the cohort', () {
    final GradingSummary summary = grade().summary;
    expect(summary.students, 3);
    expect(summary.stats.length, order.length);

    // q1: attempted by all three, two correct -> 2/3.
    final QuestionStats q1 = summary.statFor('q1')!;
    expect(q1.attempted, 3);
    expect(q1.correct, 2);
    expect(marksClose(q1.correctRate, 2 / 3), isTrue);

    // q5: only two students attempted it, one correctly -> 1/2.
    final QuestionStats q5 = summary.statFor('q5')!;
    expect(q5.attempted, 2);
    expect(q5.correct, 1);
    expect(marksClose(q5.correctRate, 0.5), isTrue);

    // Correct rates are [2/3, 1/3, 1/3, 1/3, 1/2] -> median 1/3.
    expect(marksClose(summary.medianCorrectRate, 1 / 3), isTrue);
    // Nobody was multi-marked, so the multi-mark median is 0.
    expect(marksClose(summary.medianMultiMarkRate, 0), isTrue);
  });

  test('multi-marked reads are counted from detection validity', () {
    final GradingReport report = grade(
      withReads: <String, SheetRead>{
        's1': sheet(<QuestionId, MarkedResponse>{
          'q1': resp(<OptionId>{'A', 'B'}, validity: ResponseValidity.multiMarked),
          'q2': resp(<OptionId>{'B'}),
        }),
        's2': sheet(<QuestionId, MarkedResponse>{
          'q1': resp(<OptionId>{'A', 'B'}), // two chosen, but not flagged
        }),
      },
    );
    final QuestionStats q1 = report.summary.statFor('q1')!;
    expect(q1.multiMarked, 1);
    expect(q1.attempted, 2);
    expect(marksClose(q1.multiMarkRate, 0.5), isTrue);
  });

  test('rule resolution: question override beats section and exam defaults', () {
    final ScoringRule generous = singleRule(id: 'generous', correct: 10, wrong: 0);
    final ScoringRule sectionWide = singleRule(id: 'section-wide', correct: 2, wrong: 0);

    final GradingReport report = ExamGrader().grade(
      GradingRequest(
        examId: 'exam-1',
        keyVersionId: 'kv-1',
        reads: reads,
        key: <QuestionId, KeyEntry>{
          ...key,
          'q1': keyFor('q1', <OptionId>{'A'}, ruleId: 'generous'),
          'q4': keyFor('q4', <OptionId>{'D'}, ruleId: 'section-wide'),
        },
        questionOrder: order,
        sections: <SectionSpec>[
          SectionSpec(
            id: 'physics',
            subject: 'physics',
            defaultRuleId: 'section-wide',
            questionIds: <QuestionId>['q1', 'q2', 'q3'],
          ),
          SectionSpec(
            id: 'chemistry',
            subject: 'chemistry',
            questionIds: <QuestionId>['q4', 'q5'],
          ),
        ],
        rules: <String, ScoringRule>{
          single.id: single,
          'generous': generous,
          'section-wide': sectionWide,
        },
        examDefaultRuleId: single.id,
      ),
    );

    final Map<String, ExamResult> results = report.resultsByStudent;
    // q1 uses the question override (+10 / 0).
    expect(marksClose(results['s1']!.outcomeFor('q1')!.marksAwarded, 10), isTrue);
    // q2, q3 inherit the section default (+2 / 0).
    expect(marksClose(results['s1']!.outcomeFor('q2')!.marksAwarded, 0), isTrue);
    expect(marksClose(results['s1']!.outcomeFor('q3')!.marksAwarded, 2), isTrue);
    // q4 overrides its own section's default with +2; q5 falls back to the exam
    // default (+4 / -1).
    expect(marksClose(results['s1']!.outcomeFor('q4')!.marksAwarded, 2), isTrue);
    expect(marksClose(results['s1']!.outcomeFor('q5')!.marksAwarded, 0), isTrue);
  });

  test('a dangling rule id fails the run up front', () {
    expect(
      () => ExamGrader().grade(
        GradingRequest(
          examId: 'exam-1',
          keyVersionId: 'kv-1',
          reads: reads,
          key: <QuestionId, KeyEntry>{
            ...key,
            'q1': keyFor('q1', <OptionId>{'A'}, ruleId: 'nope'),
          },
          questionOrder: order,
          sections: sections,
          rules: <String, ScoringRule>{single.id: single},
          examDefaultRuleId: single.id,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('a question with no key entry fails the run up front', () {
    expect(
      () => grade(withKey: <QuestionId, KeyEntry>{...key}..remove('q3')),
      throwsArgumentError,
    );
  });

  test('a clean, confident sheet is ok', () {
    final GradingReport report = grade();
    expect(report.resultsByStudent['s1']!.status, ExamResultStatus.ok);
  });

  test('a flagged or low-confidence sheet is doubtful', () {
    final GradingReport flagged = grade(
      withReads: <String, SheetRead>{
        's1': sheet(
          <QuestionId, MarkedResponse>{'q1': resp(<OptionId>{'A'})},
          flags: <SheetReadFlag>{SheetReadFlag.rollChecksumMismatch},
        ),
      },
    );
    expect(flagged.resultsByStudent['s1']!.status, ExamResultStatus.doubtful);

    final GradingReport faint = grade(
      withReads: <String, SheetRead>{
        's1': sheet(
          <QuestionId, MarkedResponse>{'q1': resp(<OptionId>{'A'})},
          confidence: 0.72,
        ),
      },
    );
    expect(faint.resultsByStudent['s1']!.status, ExamResultStatus.doubtful);
  });

  test('a regrade stamps results as regraded', () {
    final GradingReport report = grade(regrade: true);
    expect(report.resultsByStudent['s1']!.status, ExamResultStatus.regraded);
    expect(report.keyVersionId, 'kv-1');
  });

  test('human-corrected overlays grade like any other read', () {
    // A reviewer changed s3's q1 from B to A; the correction must simply be the
    // response the grader sees, and the flag must survive for the audit trail.
    final GradingReport report = grade(
      withReads: <String, SheetRead>{
        's3': sheet(<QuestionId, MarkedResponse>{
          'q1': resp(<OptionId>{'A'}, humanCorrected: true),
        }),
      },
    );
    final ExamResult s3 = report.resultsByStudent['s3']!;
    expect(s3.outcomeFor('q1')!.kind, QuestionOutcomeKind.correct);
    expect(marksClose(s3.totalMarks, 4), isTrue);
  });
}
