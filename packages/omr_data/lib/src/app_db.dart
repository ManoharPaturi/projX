import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

import 'daos/analytics_dao.dart';
import 'daos/exams_dao.dart';
import 'daos/keys_dao.dart';
import 'daos/layouts_dao.dart';
import 'daos/report_jobs_dao.dart';
import 'daos/results_dao.dart';
import 'daos/students_dao.dart';
import 'daos/review_dao.dart';
import 'daos/scans_dao.dart';
import 'daos/sync_outbox_dao.dart';
import 'converters.dart';
import 'enums.dart';
import 'migrations/migrations.dart';
import 'tables/answer_key_entries.dart';
import 'tables/answer_key_versions.dart';
import 'tables/audit_log.dart';
import 'tables/bubble_reads.dart';
import 'tables/exams.dart';
import 'tables/institutes.dart';
import 'tables/question_sets.dart';
import 'tables/report_jobs.dart';
import 'tables/results.dart';
import 'tables/review_queue.dart';
import 'tables/scans.dart';
import 'tables/scoring_rules.dart';
import 'tables/scoring_runs.dart';
import 'tables/sheet_layouts.dart';
import 'tables/students.dart';
import 'tables/sync_outbox.dart';
import 'tables/tenants.dart';

part 'app_db.g.dart';

/// The local database of the OMR grading system (plan §4).
///
/// - schemaVersion 1; the v2+ scaffold lives in `migrations/migrations.dart`;
/// - `beforeOpen` enables FK enforcement and WAL journaling;
/// - all timestamps are ISO-8601 UTC TEXT (see `converters.dart`);
/// - client-generated UUID row ids double as the sync idempotency keys.
@DriftDatabase(
  tables: [
    Tenants,
    Institutes,
    Students,
    SheetLayouts,
    Exams,
    QuestionSets,
    ScoringRules,
    AnswerKeyVersions,
    AnswerKeyEntries,
    Scans,
    BubbleReads,
    Results,
    ScoringRuns,
    ReviewQueue,
    ReportJobs,
    AuditLog,
    SyncOutbox,
  ],
  daos: [
    ScansDao,
    ResultsDao,
    ReviewDao,
    AnalyticsDao,
    LayoutsDao,
    ExamsDao,
    KeysDao,
    SyncOutboxDao,
    ReportJobsDao,
    StudentsDao,
  ],
)
class AppDb extends _$AppDb {
  /// Use with any [QueryExecutor]; see [memory] for tests.
  AppDb(super.executor);

  /// Ephemeral in-memory database for host tests — `NativeDatabase.memory()`
  /// is pure Dart over the sqlite3 FFI (dev-dep `sqlite3`), so tests need no
  /// Flutter boot. On a device, pair an executor with sqlite3_flutter_libs.
  factory AppDb.memory() => AppDb(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => buildMigrations(this);
}
