/// Schema lifecycle for [AppDb].
///
/// v1 layout (this file's indexes/trigger are created ON TOP of the tables
/// drift's `createAll` emits):
/// - every domain table is tenant-leading with a tenant-first index
///   (M4's scripted tenant-schema audit checks exactly this);
/// - UNIQUE constraints are unique indexes:
///   students(institute_id, roll_no), sheet_layouts(layout_id, layout_version),
///   scans(exam_id, id), results(exam_id, student_id, key_version_id);
/// - `answer_key_entries` is frozen by a BEFORE UPDATE trigger — key rows are
///   INSERT-only; a key edit is a new answer_key_versions row (plan §5).
///
/// Column names are snake_case because that is drift_dev's
/// `case_from_dart_to_sql` default; the raw SQL in the DAOs match.
library;

import 'package:drift/drift.dart';

/// v1 indexes. Ordered tenant-first; UNIQUE ones enforce the natural keys.
List<Index> v1Indexes() => <Index>[
  // institutes
  Index(
    'ix_institutes_tenant',
    'CREATE INDEX IF NOT EXISTS ix_institutes_tenant ON institutes '
        '(tenant_id)',
  ),
  Index(
    'ix_institutes_tenant_code',
    'CREATE INDEX IF NOT EXISTS ix_institutes_tenant_code ON institutes '
        '(tenant_id, code)',
  ),
  // students
  Index(
    'ux_students_institute_roll',
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_students_institute_roll ON '
        'students (institute_id, roll_no)',
  ),
  Index(
    'ix_students_tenant_institute',
    'CREATE INDEX IF NOT EXISTS ix_students_tenant_institute ON students '
        '(tenant_id, institute_id)',
  ),
  // sheet_layouts
  Index(
    'ux_sheet_layouts_id_version',
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_sheet_layouts_id_version ON '
        'sheet_layouts (layout_id, layout_version)',
  ),
  Index(
    'ix_sheet_layouts_tenant_active',
    'CREATE INDEX IF NOT EXISTS ix_sheet_layouts_tenant_active ON '
        'sheet_layouts (tenant_id, is_active)',
  ),
  // exams
  Index(
    'ix_exams_tenant_institute',
    'CREATE INDEX IF NOT EXISTS ix_exams_tenant_institute ON exams '
        '(tenant_id, institute_id)',
  ),
  Index(
    'ix_exams_tenant_status',
    'CREATE INDEX IF NOT EXISTS ix_exams_tenant_status ON exams '
        '(tenant_id, status)',
  ),
  // question_sets (PK (exam_id, set_code) already serves set lookups)
  Index(
    'ix_question_sets_tenant_exam',
    'CREATE INDEX IF NOT EXISTS ix_question_sets_tenant_exam ON '
        'question_sets (tenant_id, exam_id)',
  ),
  // scoring_rules
  Index(
    'ix_scoring_rules_tenant',
    'CREATE INDEX IF NOT EXISTS ix_scoring_rules_tenant ON scoring_rules '
        '(tenant_id)',
  ),
  // answer_key_versions
  Index(
    'ix_akv_tenant_exam_status',
    'CREATE INDEX IF NOT EXISTS ix_akv_tenant_exam_status ON '
        'answer_key_versions (tenant_id, exam_id, status)',
  ),
  // answer_key_entries (PK (key_version_id, ...) serves version lookups)
  Index(
    'ix_ake_tenant_version',
    'CREATE INDEX IF NOT EXISTS ix_ake_tenant_version ON '
        'answer_key_entries (tenant_id, key_version_id)',
  ),
  // scans
  Index(
    'ux_scans_exam_id',
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_scans_exam_id ON scans '
        '(exam_id, id)',
  ),
  Index(
    'ix_scans_tenant_exam_status',
    'CREATE INDEX IF NOT EXISTS ix_scans_tenant_exam_status ON scans '
        '(tenant_id, exam_id, status)',
  ),
  Index(
    'ix_scans_tenant_status_captured',
    'CREATE INDEX IF NOT EXISTS ix_scans_tenant_status_captured ON scans '
        '(tenant_id, status, captured_at)',
  ),
  // bubble_reads (PK (scan_id, field_key, option_index) serves reads per
  // scan; the tenant index exists for the M4 uniformity audit — drop it
  // if bulk-insert throughput on low-end devices ever hurts.)
  Index(
    'ix_bubble_reads_tenant_scan',
    'CREATE INDEX IF NOT EXISTS ix_bubble_reads_tenant_scan ON '
        'bubble_reads (tenant_id, scan_id)',
  ),
  // results
  Index(
    'ux_results_exam_student_key',
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_results_exam_student_key ON '
        'results (exam_id, student_id, key_version_id)',
  ),
  Index(
    'ix_results_tenant_exam_key_total',
    'CREATE INDEX IF NOT EXISTS ix_results_tenant_exam_key_total ON '
        'results (tenant_id, exam_id, key_version_id, total DESC)',
  ),
  // scoring_runs
  Index(
    'ix_scoring_runs_tenant_exam_key',
    'CREATE INDEX IF NOT EXISTS ix_scoring_runs_tenant_exam_key ON '
        'scoring_runs (tenant_id, exam_id, key_version_id)',
  ),
  // review_queue
  Index(
    'ix_review_tenant_scan',
    'CREATE INDEX IF NOT EXISTS ix_review_tenant_scan ON review_queue '
        '(tenant_id, scan_id)',
  ),
  Index(
    'ix_review_tenant_outcome_severity',
    'CREATE INDEX IF NOT EXISTS ix_review_tenant_outcome_severity ON '
        'review_queue (tenant_id, outcome, severity)',
  ),
  // report_jobs
  Index(
    'ix_report_jobs_tenant_exam_status',
    'CREATE INDEX IF NOT EXISTS ix_report_jobs_tenant_exam_status ON '
        'report_jobs (tenant_id, exam_id, status)',
  ),
  // audit_log
  Index(
    'ix_audit_tenant_entity',
    'CREATE INDEX IF NOT EXISTS ix_audit_tenant_entity ON audit_log '
        '(tenant_id, entity, entity_id)',
  ),
  // sync_outbox
  Index(
    'ix_sync_outbox_tenant_attempts',
    'CREATE INDEX IF NOT EXISTS ix_sync_outbox_tenant_attempts ON '
        'sync_outbox (tenant_id, attempts)',
  ),
  Index(
    'ix_sync_outbox_row',
    'CREATE INDEX IF NOT EXISTS ix_sync_outbox_row ON sync_outbox '
        '(table_name, row_id)',
  ),
];

const String _answerKeyEntriesImmutable = '''
CREATE TRIGGER IF NOT EXISTS answer_key_entries_immutable
BEFORE UPDATE ON answer_key_entries
BEGIN
  SELECT RAISE(ABORT, 'answer_key_entries is immutable: insert a new answer_key_versions row instead');
END;
''';

/// Builds the [MigrationStrategy] used by [AppDb].
///
/// `beforeOpen` runs outside drift's migration transaction, which is what
/// makes the PRAGMAs safe: `foreign_keys` is silently a no-op inside a
/// transaction and `journal_mode` cannot be changed inside one at all. On an
/// in-memory database (tests) the WAL pragma is ignored by SQLite — the
/// journal mode stays `memory` — so it neither errors nor applies.
MigrationStrategy buildMigrations(GeneratedDatabase db) => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
    for (final index in v1Indexes()) {
      await m.createIndex(index);
    }
    await db.customStatement(_answerKeyEntriesImmutable);
  },
  onUpgrade: (Migrator m, int from, int to) async {
    // ------------------------------------------------------------------
    // v2+ steps land here, oldest first. Keep every step idempotent
    // (IF NOT EXISTS / addColumn) so interrupted upgrades recover, and
    // mirror any new index in v1Indexes into the step that introduced it.
    //
    // if (from < 2) {
    //   await m.addColumn(scans, scans.someNewColumn);
    //   await m.createIndex(Index('ix_...', 'CREATE INDEX IF NOT EXISTS ...'));
    // }
    // ------------------------------------------------------------------
    assert(from >= 1 && to >= from, 'unsupported schema step $from -> $to');
  },
  beforeOpen: (OpeningDetails details) async {
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.customStatement('PRAGMA journal_mode = WAL');
  },
);
