/// Local database layer of the OMR grading system (plan §4).
///
/// drift/SQLite schema with tenant-leading tables, DAOs for
/// scans/results/review/analytics (+ layouts/exams/keys/outbox), ISO-8601
/// TEXT timestamps, immutable versioned answer keys, and a no-op sync outbox
/// as the phase-2 seam.
///
/// Host tests: `AppDb.memory()` — a pure-Dart in-memory SQLite via the
/// sqlite3 FFI, no Flutter boot needed. Generated code (`*.g.dart`) comes
/// from drift_dev via build_runner.
library;

export 'src/app_db.dart';
export 'src/converters.dart';
export 'src/enums.dart';
export 'src/daos/analytics_dao.dart';
export 'src/daos/exams_dao.dart';
export 'src/daos/keys_dao.dart';
export 'src/daos/layouts_dao.dart';
export 'src/daos/report_jobs_dao.dart';
export 'src/daos/results_dao.dart';
export 'src/daos/review_dao.dart';
export 'src/daos/scans_dao.dart';
export 'src/daos/students_dao.dart';
export 'src/daos/sync_outbox_dao.dart';
export 'src/migrations/migrations.dart' show buildMigrations, v1Indexes;
export 'src/services/grading_service.dart';
export 'src/tables/answer_key_entries.dart';
export 'src/tables/answer_key_versions.dart';
export 'src/tables/audit_log.dart';
export 'src/tables/bubble_reads.dart';
export 'src/tables/exams.dart';
export 'src/tables/institutes.dart';
export 'src/tables/question_sets.dart';
export 'src/tables/report_jobs.dart';
export 'src/tables/results.dart';
export 'src/tables/review_queue.dart';
export 'src/tables/scans.dart';
export 'src/tables/scoring_rules.dart';
export 'src/tables/scoring_runs.dart';
export 'src/tables/sheet_layouts.dart';
export 'src/tables/students.dart';
export 'src/tables/sync_outbox.dart';
export 'src/tables/tenants.dart';
export 'sync/sync_outbox.dart';
