import 'dart:io';

import 'package:drift/drift.dart' show InsertMode;
import 'package:drift/native.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_spec/omr_spec.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The single MVP tenant (plan §4: exactly one row until the phase-2 cloud).
const String kTenantId = 'tenant-mvp';

/// Opens the on-device database and runs the idempotent first-run seed.
///
/// WAL journaling and FK enforcement come from the db's `beforeOpen`, not
/// here. [path] exists so tests can point at a temp file when they want to
/// exercise the file-backed path; production passes null and gets
/// `<app-documents>/omr.db`.
Future<AppDb> openAppDb({String? path}) async {
  final file = path == null
      ? File(
          p.join(
            (await getApplicationDocumentsDirectory()).path,
            'omr.db',
          ),
        )
      : File(path);
  // createInBackground: drift runs queries on a background isolate, so the
  // UI thread never blocks on a grading-sized write.
  final db = AppDb(NativeDatabase.createInBackground(file));
  // Force beforeOpen (pragmas + migrations) before the first real query.
  await db.customSelect('SELECT 1').getSingle();
  await seedFirstRun(db);
  return db;
}

/// Everything a fresh install needs, safe to re-run on every launch:
/// the tenant row, one institute, and the shipped sheet presets. Layouts are
/// upserted by (layoutId, layoutVersion) — a preset shipping an updated
/// spec lands as the new active row, never as a silent edit of the old one.
Future<String> seedFirstRun(AppDb db) async {
  await db
      .into(db.tenants)
      .insert(
        TenantsCompanion.insert(
          id: kTenantId,
          name: 'MVP Institute Group',
          plan: 'mvp',
        ),
        mode: InsertMode.insertOrIgnore,
      );

  var institutes =
      await (db.select(
        db.institutes,
      )..where((Institutes i) => i.tenantId.equals(kTenantId))).get();
  if (institutes.isEmpty) {
    final created = await db
        .into(db.institutes)
        .insertReturning(
          InstitutesCompanion.insert(
            tenantId: kTenantId,
            name: 'My Institute',
            code: 'MVI',
          ),
        );
    institutes = [created];
  }

  await db.layoutsDao.upsertSpec(
    tenantId: kTenantId,
    spec: buildStandard90(),
  );
  await db.layoutsDao.upsertSpec(
    tenantId: kTenantId,
    spec: buildNeet180(),
  );

  return institutes.first.id;
}

/// Directory report artifacts are written into, e.g. `<docs>/reports/<examId>`.
Future<String> reportsDirectory(String examId) async {
  final docs = await getApplicationDocumentsDirectory();
  return p.joinAll([docs.path, 'reports', examId]);
}
