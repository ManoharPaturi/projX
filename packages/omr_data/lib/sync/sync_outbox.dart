import 'package:meta/meta.dart';

import '../src/app_db.dart';

/// Outcome of handing one outbox row to a transport.
enum SyncDelivery { delivered, skipped, failed }

/// Phase-2 seam (plan M5): the cloud sync transport. MVP ships only
/// [NoopSyncTransport] — the app is local-only — but the DAO layer enqueues
/// outbox rows from day one so replay is exercised by tests and the schema
/// never needs a migration when the real transport lands.
abstract class SyncTransport {
  /// Attempts to deliver one outbox row. Returning a Future that completes
  /// with [SyncDelivery.delivered] means the server acknowledged the write;
  /// throwing or returning [SyncDelivery.failed] leaves the row queued and
  /// bumps its attempts counter.
  Future<SyncDelivery> deliver(SyncOutboxEntry entry);
}

/// Delivers nothing — the MVP transport.
class NoopSyncTransport implements SyncTransport {
  const NoopSyncTransport();

  @override
  Future<SyncDelivery> deliver(SyncOutboxEntry entry) async =>
      SyncDelivery.skipped;
}

/// Summary of one [OutboxDrainer.drain] pass.
@immutable
class DrainReport {
  const DrainReport({
    required this.delivered,
    required this.failed,
    required this.skipped,
    required this.deadLettered,
  });

  final int delivered;
  final int failed;
  final int skipped;

  /// Rows that exhausted [OutboxDrainer.maxAttempts] and were left in place
  /// for a human, not retried.
  final int deadLettered;

  @override
  String toString() =>
      'DrainReport(delivered: $delivered, failed: $failed, '
      'skipped: $skipped, deadLettered: $deadLettered)';
}

/// Drains the outbox through a [SyncTransport].
///
/// Structured for retry/attempts TODAY, a no-op in effect until phase 2
/// wires a real transport: with the default [NoopSyncTransport] every row is
/// `skipped`, nothing is deleted and no attempt is recorded. The
/// attempts/last_attempt_at bookkeeping only starts once something can fail.
class OutboxDrainer {
  OutboxDrainer(
    this._db, {
    this.transport = const NoopSyncTransport(),
    this.maxAttempts = 5,
  });

  final AppDb _db;
  final SyncTransport transport;
  final int maxAttempts;

  /// Offers up to [limit] pending rows to [transport], oldest-attempted
  /// order. Runs on app start / connectivity regained (phase 2).
  Future<DrainReport> drain({int limit = 100}) async {
    var delivered = 0;
    var failed = 0;
    var skipped = 0;
    var deadLettered = 0;
    final pending = await _db.syncOutboxDao.pending(limit: limit);
    for (final entry in pending) {
      if (entry.attempts >= maxAttempts) {
        deadLettered++;
        continue;
      }
      final outcome = await transport.deliver(entry);
      switch (outcome) {
        case SyncDelivery.delivered:
          await _db.syncOutboxDao.markAttempt(
            entry.id,
            delivered: true,
            at: DateTime.now().toUtc(),
          );
          delivered++;
        case SyncDelivery.failed:
          await _db.syncOutboxDao.markAttempt(
            entry.id,
            delivered: false,
            at: DateTime.now().toUtc(),
          );
          failed++;
        case SyncDelivery.skipped:
          skipped++;
      }
    }
    return DrainReport(
      delivered: delivered,
      failed: failed,
      skipped: skipped,
      deadLettered: deadLettered,
    );
  }
}
