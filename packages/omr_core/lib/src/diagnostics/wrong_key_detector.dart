library;

import '../grading/exam_grader.dart';
import '../models/ids.dart';
import '../models/key_entry.dart';

/// Why a question was flagged as possibly having a wrong key row.
///
/// Advisory only: nothing here edits a key. A human reads the card and decides
/// whether to cut a new key version.
enum KeyAnomalyReason {
  /// Almost nobody who attempted the question got it right — the classic
  /// signature of a mis-entered key (or of the right answer keyed under the
  /// wrong option letter).
  nearZeroCorrectRate,

  /// Correct rate collapsed relative to the same section's median, which is how
  /// a single bad row in an otherwise well-answered section shows up.
  sectionOutlierCorrectRate,

  /// Far more multi-marked reads than the exam norm. Either the question is a
  /// multi-correct being graded as single-correct, or its bubbles are being
  /// misread — both are worth a look before results go out.
  elevatedMultiMarkRate,
}

/// Evidence bundle behind one flag, so a card can show its working.
typedef KeyAnomalyEvidence = ({
  double questionRate,
  double referenceRate,
  int attempted,
  int cohortSize,
});

/// One flagged question: what fired, and the numbers it fired on.
final class KeyAnomaly {
  /// Creates a flag.
  const KeyAnomaly({
    required this.questionId,
    required this.reason,
    required this.evidence,
    required this.explanation,
  });

  /// The flagged question.
  final QuestionId questionId;

  /// Which heuristic fired.
  final KeyAnomalyReason reason;

  /// The numbers behind [reason].
  final KeyAnomalyEvidence evidence;

  /// One-line, teacher-facing explanation of the evidence.
  final String explanation;

  @override
  String toString() =>
      'KeyAnomaly($questionId, ${reason.name}, ${evidence.questionRate})';
}

/// Post-grade heuristics that suggest — never apply — key corrections.
///
/// Three signals, all cohort-level:
///
/// 1. **Near-zero**: correct rate below [nearZeroThreshold] (default 0.05).
/// 2. **Section collapse**: correct rate below `sectionOutlierFactor ×` the
///    median correct rate of the *same section* (default 0.25 ×). Comparing
///    within a section controls for subject difficulty, so a hard-but-fair
///    physics question is not flagged next to an easy chemistry one.
/// 3. **Multi-mark spike**: multi-mark rate above `multiMarkFactor ×` the exam
///    median (default 3 ×).
///
/// Two guards keep it quiet on small or clean runs: a question must have at
/// least [minAttempts] attempts before any heuristic may fire, and a median of
/// zero (no signal anywhere) disables the ratio-based checks rather than
/// flagging everything above nothing.
///
/// Questions whose key state is not `normal` are skipped: a dropped or
/// key-corrected question *should* look anomalous, and the state already
/// explains it.
final class WrongKeyDetector {
  /// Creates a detector with the given thresholds.
  const WrongKeyDetector({
    this.nearZeroThreshold = 0.05,
    this.sectionOutlierFactor = 0.25,
    this.multiMarkFactor = 3,
    this.minAttempts = 5,
  });

  /// Correct rate below this fires [KeyAnomalyReason.nearZeroCorrectRate].
  final double nearZeroThreshold;

  /// Correct rate below `this × section median` fires
  /// [KeyAnomalyReason.sectionOutlierCorrectRate].
  final double sectionOutlierFactor;

  /// Multi-mark rate above `this × exam median` fires
  /// [KeyAnomalyReason.elevatedMultiMarkRate].
  final double multiMarkFactor;

  /// Minimum attempts before any heuristic may fire on a question.
  final int minAttempts;

  /// Analyses a graded exam; returns flags in sheet serial order.
  ///
  /// Section grouping comes from [QuestionStats.subject], which the grader
  /// already derived from the section spec, so no section list is needed here.
  List<KeyAnomaly> analyze({
    required GradingSummary summary,
    required Map<QuestionId, KeyEntry> key,
  }) {
    final Map<SubjectId, List<QuestionStats>> bySubject =
        <SubjectId, List<QuestionStats>>{};
    for (final QuestionStats s in summary.stats) {
      bySubject.putIfAbsent(s.subject, () => <QuestionStats>[]).add(s);
    }
    final double examMultiMarkMedian = summary.medianMultiMarkRate;

    final List<KeyAnomaly> anomalies = <KeyAnomaly>[];
    for (final QuestionStats s in summary.stats) {
      final KeyEntry? entry = key[s.questionId];
      if (entry == null) continue;
      if (entry.state != KeyEntryState.normal) continue;
      if (s.attempted < minAttempts) continue;

      final List<QuestionStats> peers = bySubject[s.subject] ?? const <QuestionStats>[];
      final double sectionMedian = _median(
        peers
            .where((QuestionStats p) => p.attempted > 0)
            .map((QuestionStats p) => p.correctRate)
            .toList(),
      );

      if (s.correctRate < nearZeroThreshold) {
        anomalies.add(
          KeyAnomaly(
            questionId: s.questionId,
            reason: KeyAnomalyReason.nearZeroCorrectRate,
            evidence: (
              questionRate: s.correctRate,
              referenceRate: nearZeroThreshold,
              attempted: s.attempted,
              cohortSize: s.cohortSize,
            ),
            explanation:
                'only ${_pct(s.correctRate)} of ${s.attempted} attempts were '
                'correct (threshold ${_pct(nearZeroThreshold)})',
          ),
        );
        continue;
      }

      if (sectionMedian > 0 &&
          s.correctRate < sectionOutlierFactor * sectionMedian) {
        anomalies.add(
          KeyAnomaly(
            questionId: s.questionId,
            reason: KeyAnomalyReason.sectionOutlierCorrectRate,
            evidence: (
              questionRate: s.correctRate,
              referenceRate: sectionMedian,
              attempted: s.attempted,
              cohortSize: s.cohortSize,
            ),
            explanation:
                '${_pct(s.correctRate)} correct vs a ${s.subject} median of '
                '${_pct(sectionMedian)}',
          ),
        );
      }

      if (examMultiMarkMedian > 0 &&
          s.multiMarkRate > multiMarkFactor * examMultiMarkMedian) {
        anomalies.add(
          KeyAnomaly(
            questionId: s.questionId,
            reason: KeyAnomalyReason.elevatedMultiMarkRate,
            evidence: (
              questionRate: s.multiMarkRate,
              referenceRate: examMultiMarkMedian,
              attempted: s.attempted,
              cohortSize: s.cohortSize,
            ),
            explanation:
                '${_pct(s.multiMarkRate)} of attempts were multi-marked vs an '
                'exam median of ${_pct(examMultiMarkMedian)}',
          ),
        );
      }
    }
    return anomalies;
  }

  /// Median of [values]; 0 when empty.
  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final List<double> sorted = values.toList()..sort();
    final int mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
}
