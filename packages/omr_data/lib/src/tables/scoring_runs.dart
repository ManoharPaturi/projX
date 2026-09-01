import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import 'answer_key_versions.dart';
import 'exams.dart';

/// Full audit snapshot of one grading pass: which rules, which layout
/// version, which thresholds — so a historical marksheet reproduces exactly
/// even after presets or thresholds change (plan §4/§5).
class ScoringRuns extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();

  /// Audit history: RESTRICT — never delete an exam or key version that has
  /// scoring runs under it.
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.restrict)();
  TextColumn get keyVersionId =>
      text().references(AnswerKeyVersions, #id, onDelete: KeyAction.restrict)();

  /// JSON: the scoring-rule rows used, verbatim.
  TextColumn get scoringRuleSnapshotJson => text()();
  IntColumn get sheetLayoutVersion => integer()();
  TextColumn get thresholdConfigId => text().nullable()();
  TextColumn get startedAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();

  /// NULL while the run is in flight; stamped by `finishScoringRun`.
  TextColumn get finishedAt => text().map(nullableIsoDate).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
