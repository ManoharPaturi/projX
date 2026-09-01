library;

import 'ids.dart';
import 'question_outcome.dart';

/// Publication state of one student's result for one key version.
///
/// `doubtful` marks a result whose *input* is suspect (sheet flags or low
/// confidence) and which therefore must clear review before publishing; it is
/// not a comment on the arithmetic. `regraded` records that this result came
/// from a key version that supersedes an earlier one — informational, kept so
/// a marksheet can say "revised" without diffing key versions.
enum ExamResultStatus { ok, doubtful, regraded }

/// One student's graded result against one key version.
final class ExamResult {
  /// Creates a fully-specified result. Prefer [fromOutcomes], which derives
  /// the totals so they can never disagree with the per-question list.
  const ExamResult({
    required this.studentId,
    required this.keyVersionId,
    required this.totalMarks,
    required this.outcomeCounts,
    required this.subjectTotals,
    required this.outcomes,
    required this.status,
  });

  /// Builds a result by aggregating [outcomes] (in sheet serial order).
  factory ExamResult.fromOutcomes({
    required String studentId,
    required String keyVersionId,
    required List<QuestionOutcome> outcomes,
    required Map<SubjectId, double> subjectTotals,
    required ExamResultStatus status,
  }) {
    final Map<QuestionOutcomeKind, int> counts = <QuestionOutcomeKind, int>{
      for (final QuestionOutcomeKind kind in QuestionOutcomeKind.values) kind: 0,
    };
    double total = 0;
    for (final QuestionOutcome o in outcomes) {
      counts[o.kind] = (counts[o.kind] ?? 0) + 1;
      total += o.marksAwarded;
    }
    return ExamResult(
      studentId: studentId,
      keyVersionId: keyVersionId,
      totalMarks: total,
      outcomeCounts: counts,
      subjectTotals: subjectTotals,
      outcomes: outcomes,
      status: status,
    );
  }

  /// The student this result belongs to.
  final String studentId;

  /// Key version graded against (results are per key version, never mutated).
  final String keyVersionId;

  /// Sum of per-question marks.
  final double totalMarks;

  /// How many questions landed in each verdict bucket.
  final Map<QuestionOutcomeKind, int> outcomeCounts;

  /// Marks aggregated per subject/section key.
  final Map<SubjectId, double> subjectTotals;

  /// Per-question outcomes in sheet serial order.
  final List<QuestionOutcome> outcomes;

  /// Publication state.
  final ExamResultStatus status;

  /// Fast lookup by question id.
  QuestionOutcome? outcomeFor(QuestionId questionId) {
    for (final QuestionOutcome o in outcomes) {
      if (o.questionId == questionId) return o;
    }
    return null;
  }

  /// Questions the student actually marked. Cap-invalidated responses count as
  /// attempted — the student did mark them; the section cap only zeroes marks.
  int get attemptedCount =>
      outcomes.length - (outcomeCounts[QuestionOutcomeKind.unattempted] ?? 0);

  /// Marks lost to negative marking — the number students dispute most.
  double get negativeMarks {
    double lost = 0;
    for (final QuestionOutcome o in outcomes) {
      if (o.marksAwarded < 0) lost += o.marksAwarded;
    }
    return lost;
  }
}
