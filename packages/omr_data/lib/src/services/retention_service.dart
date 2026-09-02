import 'package:drift/drift.dart';

import '../app_db.dart';
import '../tables/scans.dart';
import 'audit_log_service.dart';

/// One purge step's outcome — what the sweep deleted and what it cleared.
class RetentionReport {
  const RetentionReport({required this.purged, required this.missing});

  /// Originals whose file was deleted and whose column was cleared.
  final List<String> purged;

  /// Rows whose original had already vanished from disk (a restore, a
  /// manual cleanup). The column is still cleared — the row must never
  /// point at a path expecting a file.
  final List<String> missing;

  int get total => purged.length + missing.length;
}

/// The M4 retention sweep (plan risk #9): drop 12MP capture originals whose
/// grace window has closed, keep the warped grayscale + annotated thumb
/// forever (they are the review substrate), and audit every deletion.
///
/// File deletion is INJECTED, never defaulted: this package must not guess
/// filesystem policy. The app supplies a deleter that resolves the path
/// under its own app-documents root and refuses anything outside it — a
/// mis-filled `original_path` then fails closed instead of deleting an
/// arbitrary path.
class RetentionService {
  RetentionService(this.db, {required this.deleteFile});

  final AppDb db;

  /// Deletes the file at [path]; returns false when nothing was there.
  /// Throw to abort the whole sweep — e.g. a path outside the allowed root.
  final Future<bool> Function(String path) deleteFile;

  /// Runs the sweep for [tenantId] as of [now] (injectable for tests).
  ///
  /// Not a transaction: each scan is purged atomically on its own
  /// (delete-then-clear per row), so one stubborn file cannot roll back the
  /// purges that already succeeded.
  Future<RetentionReport> run({
    required String tenantId,
    required int graceDays,
    DateTime? now,
  }) async {
    final cutoff = (now ?? DateTime.now())
        .toUtc()
        .subtract(Duration(days: graceDays))
        .toIso8601String(); // TEXT column; ISO-8601 UTC sorts chronologically
    final rows = await (db.select(db.scans)
          ..where(
            (Scans s) =>
                s.tenantId.equals(tenantId) &
                s.originalPath.isNotNull() &
                s.capturedAt.isSmallerThanValue(cutoff),
          ))
        .get();

    final purged = <String>[];
    final missing = <String>[];
    final audit = AuditLogService(db);
    for (final scan in rows) {
      final path = scan.originalPath!;
      final existed = await deleteFile(path);
      await (db.update(db.scans)
            ..where((Scans s) => s.id.equals(scan.id)))
          .write(const ScansCompanion(originalPath: Value(null)));
      await audit.record(
        tenantId: tenantId,
        entity: 'scans',
        entityId: scan.id,
        action: 'purge_original',
        before: {'originalPath': path},
        after: {'originalPath': null},
      );
      (existed ? purged : missing).add(scan.id);
    }
    return RetentionReport(purged: purged, missing: missing);
  }
}
