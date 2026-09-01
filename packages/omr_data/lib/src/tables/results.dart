import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'answer_key_versions.dart';
import 'exams.dart';
import 'scans.dart';
import 'scoring_runs.dart';
import 'students.dart';

/// One graded result per (exam, student, key version) — that natural key is
/// a unique index created in the v1 migration, and the upsert conflict
/// target for `ResultsDao.upsertResults`.
///
/// ALL foreign keys RESTRICT: results are the historical marks record — an
/// exam/student/key version with results on it cannot be deleted (deleting
/// an institute that still has results therefore fails at the results FK;
/// schema_test covers the direct case).
class Results extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();
  TextColumn get scanId =>
      text().references(Scans, #id, onDelete: KeyAction.restrict)();
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.restrict)();
  TextColumn get studentId =>
      text().references(Students, #id, onDelete: KeyAction.restrict)();
  TextColumn get keyVersionId =>
      text().references(AnswerKeyVersions, #id, onDelete: KeyAction.restrict)();
  TextColumn get scoringRunId =>
      text().references(ScoringRuns, #id, onDelete: KeyAction.restrict)();

  /// Final score after negative marking, corrections and overrides.
  RealColumn get total => real()();
  IntColumn get correct => integer().withDefault(const Constant(0))();
  IntColumn get wrong => integer().withDefault(const Constant(0))();
  IntColumn get unattempted => integer().withDefault(const Constant(0))();

  /// JSON: subject/section → marks, consumed by AnalyticsDao via JSON1.
  TextColumn get subjectTotalsJson =>
      text().withDefault(const Constant('{}'))();

  /// 1-based exam rank; NULL until `recomputeRanks` runs. RANK semantics —
  /// ties share a rank and the next rank skips.
  IntColumn get rank => integer().nullable()();
  TextColumn get status =>
      textEnum<ResultStatus>().withDefault(const Constant('ok'))();
  TextColumn get gradedAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();

  @override
  Set<Column> get primaryKey => {id};
}
