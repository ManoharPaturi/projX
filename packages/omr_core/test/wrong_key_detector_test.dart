/// Wrong-key detector: planted anomalies are caught with evidence, clean exams
/// stay silent, and the guards (minimum attempts, non-normal key states) hold.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

void main() {
  const WrongKeyDetector detector = WrongKeyDetector();

  /// Builds one question's stats so that `correctRate` and `multiMarkRate`
  /// come out exactly as asked.
  QuestionStats qstat(
    QuestionId q, {
    required double correctRate,
    required int attempted,
    double multiMarkRate = 0.04,
    String subject = 'physics',
    int cohort = 60,
  }) {
    final int correct = (correctRate * attempted).round();
    final int multiMarked = (multiMarkRate * attempted).round();
    return QuestionStats(
      questionId: q,
      subject: subject,
      cohortSize: cohort,
      attempted: attempted,
      correct: correct,
      partial: 0,
      wrong: attempted - correct,
      unattempted: cohort - attempted,
      invalidated: 0,
      bonus: 0,
      multiMarked: multiMarked,
      averageMarks: 0,
    );
  }

  Map<QuestionId, KeyEntry> normalKey(List<QuestionId> ids) =>
      <QuestionId, KeyEntry>{
        for (final QuestionId q in ids) q: KeyEntry(questionId: q, correctOptions: <OptionId>{'A'}),
      };

  group('planted anomalies are detected with evidence', () {
    // Six questions in one subject. Medians: correct rate 0.80, multi-mark 0.04.
    final GradingSummary summary = GradingSummary(
      students: 60,
      stats: <QuestionStats>[
        qstat('q1', correctRate: 0.02, attempted: 50), // near-zero
        qstat('q2', correctRate: 0.10, attempted: 50), // collapsed vs section
        qstat('q3', correctRate: 0.80, attempted: 50, multiMarkRate: 0.30),
        qstat('q4', correctRate: 0.80, attempted: 50),
        qstat('q5', correctRate: 0.80, attempted: 50),
        qstat('q6', correctRate: 0.80, attempted: 50),
      ],
      medianCorrectRate: 0.80,
      medianMultiMarkRate: 0.04,
    );

    test('all three heuristics fire, each on its own question', () {
      final List<KeyAnomaly> anomalies = detector.analyze(
        summary: summary,
        key: normalKey(<QuestionId>['q1', 'q2', 'q3', 'q4', 'q5', 'q6']),
      );
      expect(anomalies.length, 3);
      expect(anomalies.map((KeyAnomaly a) => a.questionId), <String>['q1', 'q2', 'q3']);
      expect(anomalies[0].reason, KeyAnomalyReason.nearZeroCorrectRate);
      expect(anomalies[1].reason, KeyAnomalyReason.sectionOutlierCorrectRate);
      expect(anomalies[2].reason, KeyAnomalyReason.elevatedMultiMarkRate);
    });

    test('evidence carries the numbers the card will show', () {
      final KeyAnomaly nearZero = detector
          .analyze(summary: summary, key: normalKey(<QuestionId>['q1']))
          .first;
      expect(marksClose(nearZero.evidence.questionRate, 0.02), isTrue);
      expect(nearZero.evidence.attempted, 50);
      expect(nearZero.evidence.cohortSize, 60);
      expect(nearZero.explanation, contains('2.0%'));
      expect(nearZero.explanation, contains('50'));

      final KeyAnomaly multi = detector
          .analyze(summary: summary, key: normalKey(<QuestionId>['q3']))
          .first;
      expect(marksClose(multi.evidence.referenceRate, 0.04), isTrue);
      expect(multi.explanation, contains('multi-marked'));
    });

    test('a near-zero question reports once, not twice', () {
      // q1 also collapses against the section median, but a single decisive
      // signal is enough to put it in front of a teacher.
      final List<KeyAnomaly> anomalies = detector.analyze(
        summary: summary,
        key: normalKey(<QuestionId>['q1']),
      );
      expect(anomalies.length, 1);
    });
  });

  test('a clean exam raises no flags', () {
    final GradingSummary summary = GradingSummary(
      students: 60,
      stats: <QuestionStats>[
        for (int i = 1; i <= 6; i++)
          qstat('q$i', correctRate: 0.80, attempted: 50),
      ],
      medianCorrectRate: 0.80,
      medianMultiMarkRate: 0.04,
    );
    expect(
      detector.analyze(
        summary: summary,
        key: normalKey(<QuestionId>['q1', 'q2', 'q3', 'q4', 'q5', 'q6']),
      ),
      isEmpty,
    );
  });

  test('a hard-but-fair question is not flagged next to easy ones', () {
    // 0.5 correct against a 0.8 median is a difficult question, not a wrong key.
    final GradingSummary summary = GradingSummary(
      students: 60,
      stats: <QuestionStats>[
        qstat('q1', correctRate: 0.50, attempted: 50),
        qstat('q2', correctRate: 0.80, attempted: 50),
        qstat('q3', correctRate: 0.80, attempted: 50),
      ],
      medianCorrectRate: 0.80,
      medianMultiMarkRate: 0.04,
    );
    expect(
      detector.analyze(
        summary: summary,
        key: normalKey(<QuestionId>['q1', 'q2', 'q3']),
      ),
      isEmpty,
    );
  });

  group('guards', () {
    test('a question too few attempted produces no signal', () {
      final GradingSummary summary = GradingSummary(
        students: 60,
        stats: <QuestionStats>[qstat('q1', correctRate: 0, attempted: 4)],
        medianCorrectRate: 0.80,
        medianMultiMarkRate: 0.04,
      );
      expect(
        detector.analyze(summary: summary, key: normalKey(<QuestionId>['q1'])),
        isEmpty,
      );
    });

    test('a zero median disables the ratio checks instead of flagging all', () {
      final GradingSummary summary = GradingSummary(
        students: 60,
        stats: <QuestionStats>[
          qstat('q1', correctRate: 0.60, attempted: 50, multiMarkRate: 0.10),
          qstat('q2', correctRate: 0.60, attempted: 50, multiMarkRate: 0.10),
        ],
        medianCorrectRate: 0.60,
        medianMultiMarkRate: 0,
      );
      expect(
        detector.analyze(
          summary: summary,
          key: normalKey(<QuestionId>['q1', 'q2']),
        ),
        isEmpty,
      );
    });

    test('non-normal key states are skipped, even when they look broken', () {
      final GradingSummary summary = GradingSummary(
        students: 60,
        stats: <QuestionStats>[
          qstat('q1', correctRate: 0, attempted: 50),
          qstat('q2', correctRate: 0.80, attempted: 50),
        ],
        medianCorrectRate: 0.40,
        medianMultiMarkRate: 0.04,
      );
      final Map<QuestionId, KeyEntry> key = <QuestionId, KeyEntry>{
        'q1': KeyEntry(
          questionId: 'q1',
          correctOptions: <OptionId>{'A'},
          state: KeyEntryState.dropped,
        ),
        'q2': KeyEntry(questionId: 'q2', correctOptions: <OptionId>{'A'}),
      };
      expect(detector.analyze(summary: summary, key: key), isEmpty);
    });

    test('questions missing from the key are ignored', () {
      final GradingSummary summary = GradingSummary(
        students: 60,
        stats: <QuestionStats>[qstat('q1', correctRate: 0, attempted: 50)],
        medianCorrectRate: 0.80,
        medianMultiMarkRate: 0.04,
      );
      expect(detector.analyze(summary: summary, key: <QuestionId, KeyEntry>{}), isEmpty);
    });
  });

  group('thresholds are tunable', () {
    final GradingSummary summary = GradingSummary(
      students: 60,
      stats: <QuestionStats>[
        qstat('q1', correctRate: 0.10, attempted: 50),
        qstat('q2', correctRate: 0.80, attempted: 50),
      ],
      medianCorrectRate: 0.80,
      medianMultiMarkRate: 0.04,
    );
    final Map<QuestionId, KeyEntry> key = normalKey(<QuestionId>['q1', 'q2']);

    test('loosening the near-zero threshold silences the flag', () {
      const WrongKeyDetector lenient = WrongKeyDetector(nearZeroThreshold: 0.01);
      // 0.10 is no longer near-zero, but it still collapses against 0.8.
      final List<KeyAnomaly> anomalies = lenient.analyze(
        summary: summary,
        key: key,
      );
      expect(anomalies.length, 1);
      expect(anomalies.single.reason, KeyAnomalyReason.sectionOutlierCorrectRate);
    });

    test('raising minAttempts suppresses small-cohort noise', () {
      const WrongKeyDetector cautious = WrongKeyDetector(minAttempts: 60);
      expect(cautious.analyze(summary: summary, key: key), isEmpty);
    });
  });
}
