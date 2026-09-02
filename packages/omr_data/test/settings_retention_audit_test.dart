import 'package:drift/drift.dart' show Value;
import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// v2 surfaces: per-tenant settings (strictness + retention window), the
/// original-purge retention sweep, and the audit trail written by the
/// consequential actions (key finalize, grading run, review resolve).
void main() {
  late AppDb db;
  late String examId;

  setUp(() async {
    db = await openTestDb();
    await seedTenant(db);
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
  });

  tearDown(() async {
    await db.close();
  });

  group('SettingsDao', () {
    test('reads defaults before any write', () async {
      final settings = await db.settingsDao.settingsFor(kTenantId);
      expect(settings.strictness, 'normal');
      expect(settings.retentionGraceDays, 7);
    });

    test('write then read round-trips; null fields keep stored values',
        () async {
      await db.settingsDao.write(tenantId: kTenantId, strictness: 'strict');
      await db.settingsDao.write(tenantId: kTenantId, retentionGraceDays: 30);

      final settings = await db.settingsDao.settingsFor(kTenantId);
      expect(settings.strictness, 'strict'); // survived the second write
      expect(settings.retentionGraceDays, 30);
    });

    test('refuses unknown strictness names and non-positive grace days',
        () async {
      expect(
        () => db.settingsDao.write(tenantId: kTenantId, strictness: 'yolo'),
        throwsArgumentError,
      );
      expect(
        () => db.settingsDao.write(tenantId: kTenantId, retentionGraceDays: 0),
        throwsArgumentError,
      );
      // Neither rejected write landed.
      final settings = await db.settingsDao.settingsFor(kTenantId);
      expect(settings.strictness, 'normal');
      expect(settings.retentionGraceDays, 7);
    });
  });

  group('RetentionService', () {
    test('purges only originals past the grace window, audits each purge',
        () async {
      final now = DateTime.utc(2026, 9, 2);
      // Three scans: fresh (keep), past the window (purge), and one whose
      // file already vanished (column still cleared).
      final fresh = await db.scansDao.insertScanWithReads(
        scanRow(
          examId: examId,
          id: 'scan-fresh',
          capturedAt: now.subtract(const Duration(days: 6)),
        ).copyWith(
          originalPath: const Value('/srv/fresh.jpg'),
        ),
        const [],
      );
      final old = await db.scansDao.insertScanWithReads(
        scanRow(
          examId: examId,
          id: 'scan-old',
          capturedAt: now.subtract(const Duration(days: 8)),
        ).copyWith(originalPath: const Value('/srv/old.jpg')),
        const [],
      );
      final ancient = await db.scansDao.insertScanWithReads(
        scanRow(
          examId: examId,
          id: 'scan-ancient',
          capturedAt: now.subtract(const Duration(days: 30)),
        ).copyWith(
          originalPath: const Value('/srv/gone-already.jpg'),
        ),
        const [],
      );
      expect(fresh, 'scan-fresh');
      expect(old, 'scan-old');
      expect(ancient, 'scan-ancient');

      final deleted = <String>[];
      final report = await RetentionService(
        db,
        deleteFile: (path) async {
          // The already-missing file "fails" to delete — the sweep must
          // still clear the column.
          if (path == '/srv/gone-already.jpg') return false;
          deleted.add(path);
          return true;
        },
      ).run(tenantId: kTenantId, graceDays: 7, now: now);

      expect(deleted, ['/srv/old.jpg']);
      expect(report.purged, ['scan-old']);
      expect(report.missing, ['scan-ancient']);
      expect(report.total, 2);

      // Fresh row untouched, purged rows cleared.
      final rows = {
        for (final s in await db.select(db.scans).get()) s.id: s.originalPath,
      };
      expect(rows['scan-fresh'], '/srv/fresh.jpg');
      expect(rows['scan-old'], isNull);
      expect(rows['scan-ancient'], isNull);

      // One audit row per purge — evidence, including the missing file.
      final audits = await (db.select(db.auditLog)
            ..where((AuditLog a) => a.action.equals('purge_original')))
          .get();
      expect(audits.length, 2);
      expect(
        audits.map((a) => a.entityId).toSet(),
        {'scan-old', 'scan-ancient'},
      );
    });

    test('a deleteFile throw is not swallowed — policy failures abort',
        () async {
      await db.scansDao.insertScanWithReads(
        scanRow(
          examId: examId,
          capturedAt: DateTime.utc(2020, 1, 1),
        ).copyWith(originalPath: const Value('/outside/root.jpg')),
        const [],
      );
      await expectLater(
        RetentionService(
          db,
          deleteFile: (path) async => throw StateError('outside app root'),
        ).run(tenantId: kTenantId, graceDays: 7, now: DateTime.utc(2026, 9, 2)),
        throwsStateError,
      );
      // The row still points at its file — the sweep failed closed.
      final scan = (await db.select(db.scans).get()).single;
      expect(scan.originalPath, '/outside/root.jpg');
    });
  });

  group('audit trail wiring', () {
    test('finalizeVersion lands in audit_log with before/after', () async {
      final keyVersionId = await db.keysDao.createVersion(
        tenantId: kTenantId,
        examId: examId,
        version: 1,
        createdBy: 'operator',
      );
      await db.keysDao.finalizeVersion(keyVersionId);

      final entry = (await (db.select(db.auditLog)
              ..where((AuditLog a) => a.entityId.equals(keyVersionId)))
          .get())
          .single;
      expect(entry.entity, 'answer_key_versions');
      expect(entry.action, 'finalize');
      expect(entry.beforeJson, contains('provisional'));
      expect(entry.afterJson, contains('finalized'));
    });
  });
}
