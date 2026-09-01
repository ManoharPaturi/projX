import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../app_db.dart';
import '../tables/answer_key_entries.dart';
import '../tables/bubble_reads.dart';
import '../tables/results.dart';
import '../tables/scans.dart';

part 'analytics_dao.g.dart';

/// avg/max/min marks per subject, straight out of
/// `results.subject_totals_json` via SQLite JSON1.
@immutable
class SubjectAggregateRow {
  const SubjectAggregateRow({
    required this.subject,
    required this.students,
    required this.avgTotal,
    required this.maxTotal,
    required this.minTotal,
  });

  final String subject;
  final int students;
  final double avgTotal;
  final double maxTotal;
  final double minTotal;
}

/// Per-question difficulty and discrimination for one (exam, key version).
@immutable
class QuestionStatsRow {
  const QuestionStatsRow({
    required this.questionId,
    required this.students,
    required this.attempted,
    required this.correct,
    required this.difficulty,
    required this.topHalfCorrectRate,
    required this.bottomHalfCorrectRate,
    required this.discrimination,
  });

  final String questionId;

  /// Students with reads for this question (the denominators below).
  final int students;
  final int attempted;
  final int correct;

  /// Classic difficulty index P = correct / students.
  final double difficulty;

  /// Correct rate among the top half of the cohort (by total, NTILE(2)).
  /// NULL (Dart `null`) when that half has no students at all — "not
  /// measurable", not zero.
  final double? topHalfCorrectRate;
  final double? bottomHalfCorrectRate;

  /// Discrimination = top-half rate − bottom-half rate. Positive is good
  /// (stronger students found it easier); ~0 is uninformative; negative means
  /// the question favours the weak half — a wrong-key smell. NULL when a
  /// half is empty.
  final double? discrimination;
}

/// Distractor distribution: how often each option of each question was the
/// one actually bubbled, and whether it was a keyed option.
@immutable
class DistractorRow {
  const DistractorRow({
    required this.questionId,
    required this.optionIndex,
    required this.chosenCount,
    required this.isCorrectOption,
  });

  final String questionId;
  final int optionIndex;
  final int chosenCount;
  final bool isCorrectOption;
}

/// Exam analytics as pure SQL — window functions, JSON1 and GROUP BY on the
/// engine, never app-side loops over result sets (plan §4). All rates use
/// REAL division; a question nobody in a half attempted yields NULL rates
/// (SQLite's x/0), which maps to Dart `null` in the row classes below —
/// callers treat NULL as "not measurable", not zero.
@DriftAccessor(tables: [Results, BubbleReads, Scans, AnswerKeyEntries])
class AnalyticsDao extends DatabaseAccessor<AppDb> with _$AnalyticsDaoMixin {
  AnalyticsDao(super.attachedDatabase);

  /// Subject-wise aggregates over `results.subject_totals_json`.
  Future<List<SubjectAggregateRow>> subjectAggregates(
    String examId,
    String keyVersionId,
  ) async {
    final rows = await customSelect(
      'SELECT je.key AS subject, COUNT(*) AS students, '
      'AVG(CAST(je.value AS REAL)) AS avg_total, '
      'MAX(CAST(je.value AS REAL)) AS max_total, '
      'MIN(CAST(je.value AS REAL)) AS min_total '
      'FROM results r, json_each(r.subject_totals_json) je '
      'WHERE r.exam_id = ?1 AND r.key_version_id = ?2 '
      'GROUP BY je.key ORDER BY je.key',
      variables: [
        Variable.withString(examId),
        Variable.withString(keyVersionId),
      ],
      readsFrom: {results},
    ).get();
    return <SubjectAggregateRow>[
      for (final row in rows)
        SubjectAggregateRow(
          subject: row.read<String>('subject'),
          students: row.read<int>('students'),
          avgTotal: row.read<double>('avg_total'),
          maxTotal: row.read<double>('max_total'),
          minTotal: row.read<double>('min_total'),
        ),
    ];
  }

  /// Per-question difficulty (correct rate over the cohort) and
  /// discrimination (top-half correct rate minus bottom-half). A student's
  /// answer is CORRECT when the set of FILLED options equals the keyed set:
  /// at least one keyed option filled and none unkeyed — multi-marks are
  /// wrong, not partially right (that logic lives in omr_core's strategies).
  ///
  /// The cohort is split by NTILE(2) OVER (ORDER BY total DESC): halves are
  /// computed from the same results the ranks come from.
  Future<List<QuestionStatsRow>> questionStats(
    String examId,
    String keyVersionId,
  ) async {
    final rows = await customSelect(
      'WITH keyq AS ('
      '  SELECT set_code, question_id, correct_options_json '
      '  FROM answer_key_entries WHERE key_version_id = ?2'
      '), cohort AS ('
      '  SELECT r.scan_id, NTILE(2) OVER (ORDER BY r.total DESC, r.student_id) AS half '
      '  FROM results r WHERE r.exam_id = ?1 AND r.key_version_id = ?2'
      '), per_student AS ('
      '  SELECT br.scan_id, br.field_key AS question_id, co.half, '
      '    MAX(CASE WHEN br.mark_class = \'filled\' THEN 1 ELSE 0 END) AS attempted, '
      '    MAX(CASE WHEN br.mark_class = \'filled\' AND EXISTS ('
      '      SELECT 1 FROM json_each(k.correct_options_json) je '
      '      WHERE CAST(je.value AS INTEGER) = br.option_index) '
      '      THEN 1 ELSE 0 END) AS any_good, '
      '    MAX(CASE WHEN br.mark_class = \'filled\' AND NOT EXISTS ('
      '      SELECT 1 FROM json_each(k.correct_options_json) je '
      '      WHERE CAST(je.value AS INTEGER) = br.option_index) '
      '      THEN 1 ELSE 0 END) AS any_bad '
      '  FROM bubble_reads br '
      '  JOIN scans s ON s.id = br.scan_id '
      '  JOIN cohort co ON co.scan_id = br.scan_id '
      '  JOIN keyq k ON k.set_code = COALESCE(s.set_code_read, \'\') '
      '              AND k.question_id = br.field_key '
      '  GROUP BY br.scan_id, br.field_key, co.half'
      '), scored AS ('
      '  SELECT question_id, half, attempted, '
      '    CASE WHEN attempted = 1 AND any_good = 1 AND any_bad = 0 '
      '      THEN 1 ELSE 0 END AS is_correct '
      '  FROM per_student'
      ') '
      'SELECT question_id, '
      'COUNT(*) AS students, SUM(attempted) AS attempted, SUM(is_correct) AS correct, '
      'CAST(SUM(is_correct) AS REAL) / COUNT(*) AS difficulty, '
      'CAST(SUM(CASE WHEN half = 1 THEN is_correct ELSE 0 END) AS REAL) '
      '  / SUM(CASE WHEN half = 1 THEN 1 ELSE 0 END) AS top_rate, '
      'CAST(SUM(CASE WHEN half = 2 THEN is_correct ELSE 0 END) AS REAL) '
      '  / SUM(CASE WHEN half = 2 THEN 1 ELSE 0 END) AS bottom_rate, '
      'CAST(SUM(CASE WHEN half = 1 THEN is_correct ELSE 0 END) AS REAL) '
      '  / SUM(CASE WHEN half = 1 THEN 1 ELSE 0 END) '
      '  - CAST(SUM(CASE WHEN half = 2 THEN is_correct ELSE 0 END) AS REAL) '
      '    / SUM(CASE WHEN half = 2 THEN 1 ELSE 0 END) AS discrimination '
      'FROM scored GROUP BY question_id ORDER BY question_id',
      variables: [
        Variable.withString(examId),
        Variable.withString(keyVersionId),
      ],
      readsFrom: {results, bubbleReads, scans, answerKeyEntries},
    ).get();
    return <QuestionStatsRow>[
      for (final row in rows)
        QuestionStatsRow(
          questionId: row.read<String>('question_id'),
          students: row.read<int>('students'),
          attempted: row.read<int>('attempted'),
          correct: row.read<int>('correct'),
          difficulty: row.read<double>('difficulty'),
          topHalfCorrectRate: row.readNullable<double>('top_rate'),
          bottomHalfCorrectRate: row.readNullable<double>('bottom_rate'),
          discrimination: row.readNullable<double>('discrimination'),
        ),
    ];
  }

  /// Distractor distribution: filled-option counts per question/option over
  /// the graded cohort of one key version, keyed-option flagged.
  Future<List<DistractorRow>> distractorDistribution(
    String examId,
    String keyVersionId,
  ) async {
    final rows = await customSelect(
      'SELECT br.field_key AS question_id, br.option_index, '
      'COUNT(*) AS chosen, '
      'EXISTS(SELECT 1 FROM json_each(k.correct_options_json) je '
      '  WHERE CAST(je.value AS INTEGER) = br.option_index) AS is_correct '
      'FROM bubble_reads br '
      'JOIN scans s ON s.id = br.scan_id '
      'JOIN results r ON r.scan_id = br.scan_id '
      '  AND r.exam_id = ?1 AND r.key_version_id = ?2 '
      'JOIN answer_key_entries k ON k.key_version_id = ?2 '
      '  AND k.set_code = COALESCE(s.set_code_read, \'\') '
      '  AND k.question_id = br.field_key '
      'WHERE br.mark_class = \'filled\' '
      'GROUP BY br.field_key, br.option_index, is_correct '
      'ORDER BY br.field_key, br.option_index',
      variables: [
        Variable.withString(examId),
        Variable.withString(keyVersionId),
      ],
      readsFrom: {bubbleReads, scans, results, answerKeyEntries},
    ).get();
    return <DistractorRow>[
      for (final row in rows)
        DistractorRow(
          questionId: row.read<String>('question_id'),
          optionIndex: row.read<int>('option_index'),
          chosenCount: row.read<int>('chosen'),
          isCorrectOption: row.read<int>('is_correct') != 0,
        ),
    ];
  }
}
