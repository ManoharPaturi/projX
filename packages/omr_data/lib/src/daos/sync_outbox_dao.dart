import 'package:drift/drift.dart';

import '../app_db.dart';
import '../converters.dart';
import '../enums.dart';
import '../tables/sync_outbox.dart';

part 'sync_outbox_dao.g.dart';

/// Write path of the phase-2 sync seam. The write DAOs call [enqueue] inside
/// the SAME transaction as their insert/update — deliberately NOT a trigger
/// (plan: "simple helper DAOs call after inserts — do NOT wire triggers") —
/// so an outbox row exists iff the write it describes committed.
@DriftAccessor(tables: [SyncOutbox])
class SyncOutboxDao extends DatabaseAccessor<AppDb> with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.attachedDatabase);

  /// Records a write for later replay. [rowId] should be the client UUID of
  /// the affected row (or a stable natural key) so server-side replay can
  /// `ON CONFLICT DO NOTHING` (plan M5).
  Future<void> enqueue({
    required String tenantId,
    required String tableName,
    required String rowId,
    required SyncOp op,
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return into(syncOutbox).insert(
      SyncOutboxCompanion.insert(
        tenantId: tenantId,
        targetTable: tableName,
        rowId: rowId,
        op: op,
        payloadJson: Value(encodeJsonObject(payload)),
      ),
    );
  }

  /// Undelivered rows, least-attempted first (retry fairness — a flaky row
  /// never starves fresh ones), then oldest attempt stamp.
  Future<List<SyncOutboxEntry>> pending({int limit = 100}) {
    return (select(syncOutbox)
          ..orderBy([
            (SyncOutbox t) => OrderingTerm.asc(t.attempts),
            (SyncOutbox t) => OrderingTerm.asc(t.lastAttemptAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Records one delivery attempt: delivered rows are deleted (they must
  /// never replay); failed rows get `attempts + 1` and a fresh stamp.
  Future<void> markAttempt(
    String id, {
    required bool delivered,
    required DateTime at,
  }) async {
    if (delivered) {
      await (delete(syncOutbox)..where((SyncOutbox t) => t.id.equals(id))).go();
      return;
    }
    final row = await (select(
      syncOutbox,
    )..where((SyncOutbox t) => t.id.equals(id))).getSingle();
    await (update(syncOutbox)..where((SyncOutbox t) => t.id.equals(id))).write(
      SyncOutboxCompanion(
        attempts: Value(row.attempts + 1),
        lastAttemptAt: Value(at),
      ),
    );
  }
}
