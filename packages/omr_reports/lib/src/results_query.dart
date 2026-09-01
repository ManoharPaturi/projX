import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';

/// One student's published result, flattened for rendering (plan §7).
///
/// Roll number leads, name trails and may be null — DPDP-wise the roll is the
/// student key; names exist only when an institute chose to type them in.
class ReportRow {
  const ReportRow({
    required this.studentId,
    required this.rollNo,
    required this.name,
    required this.rank,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.unattempted,
    required this.subjectTotals,
    required this.status,
    required this.scanId,
  });

  final String studentId;
  final String rollNo;
  final String? name;
  final int? rank;
  final double total;
  final int correct;
  final int wrong;
  final int unattempted;
  final Map<String, double> subjectTotals;
  final ResultStatus status;
  final String scanId;

  /// Questions the student marked (cap-invalidated ones count — the cap only
  /// zeroes marks, the student did mark them).
  int get attempted => correct + wrong;
}

/// Exam-level facts every renderer puts in its header, resolved once.
class ExamHeader {
  const ExamHeader({
    required this.examId,
    required this.examName,
    required this.instituteName,
    required this.heldAt,
    required this.totalQuestions,
    required this.keyVersionId,
    required this.keyVersionNumber,
    required this.subjects,
    required this.studentCount,
    required this.maxTotal,
    required this.generatedAt,
  });

  final String examId;
  final String examName;
  final String instituteName;
  final DateTime? heldAt;
  final int totalQuestions;
  final String keyVersionId;
  final int keyVersionNumber;

  /// Subject/section ids in stable order — the dynamic columns of every table.
  final List<String> subjects;

  final int studentCount;

  /// Highest total in the cohort — the "out of" teachers quote against.
  final double maxTotal;

  final DateTime generatedAt;
}

/// The ONE canonical results read (plan §7): every renderer — PDF, XLSX, CSV,
/// analytics — consumes only [ExamHeader] + [ReportRow]s from here, so no two
/// exports can disagree about the same exam.
///
/// Per-question detail stays lazy: it is a pure function of the same substrate
/// the grading pass used, rebuilt on demand via [GradingService.gradeScan]
/// rather than stored — which is also why any marksheet reproduces exactly.
class ResultsQuery {
  ResultsQuery(this.db, {required this.examId, required this.keyVersionId});

  final AppDb db;
  final String examId;
  final String keyVersionId;

  GradingService _grading() => GradingService(db);

  /// Exam facts + cohort subject columns. Rows are read once so the header's
  /// count/top-total can never disagree with [rows] called a moment later.
  Future<ExamHeader> header() async {
    final exam = await db.examsDao.byId(examId);
    if (exam == null) {
      throw StateError('unknown exam $examId');
    }
    final institute = await (db.select(
      db.institutes,
    )..where((Institutes i) => i.id.equals(exam.instituteId))).getSingle();
    final keyVersion = await db.keysDao.versionById(keyVersionId);
    final layout = await _grading().layoutContextFor(examId);

    final rows = await this.rows();
    return ExamHeader(
      examId: examId,
      examName: exam.name,
      instituteName: institute.name,
      heldAt: exam.heldAt,
      totalQuestions: exam.totalQuestions,
      keyVersionId: keyVersionId,
      keyVersionNumber: keyVersion.version,
      subjects: <String>{
        for (final s in layout.sections) s.subjectKey,
      }.toList(growable: false),
      studentCount: rows.length,
      maxTotal: rows.fold<double>(0, (m, r) => r.total > m ? r.total : m),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  /// Every published row, rank order, ties broken deterministically.
  Future<List<ReportRow>> rows() async {
    final results = await db.resultsDao.resultsFor(examId, keyVersionId);
    return <ReportRow>[
      for (final r in results)
        ReportRow(
          studentId: r.student.id,
          rollNo: r.student.rollNo,
          name: r.student.name,
          rank: r.result.rank,
          total: r.result.total,
          correct: r.result.correct,
          wrong: r.result.wrong,
          unattempted: r.result.unattempted,
          subjectTotals: decodeJsonObject(
            r.result.subjectTotalsJson,
          ).map((k, v) => MapEntry(k, (v as num).toDouble())),
          status: r.result.status,
          scanId: r.result.scanId,
        ),
    ];
  }

  /// Rebuilds one student's per-question outcomes from the stored substrate —
  /// the lazy detail behind marksheet tables and analytics drill-downs.
  Future<List<core.QuestionOutcome>> outcomesFor(ReportRow row) async {
    final result = await _grading().gradeScan(
      examId: examId,
      keyVersionId: keyVersionId,
      scanId: row.scanId,
    );
    return result.outcomes;
  }
}
