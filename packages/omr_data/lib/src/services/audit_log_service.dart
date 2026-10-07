import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_db.dart';

/// Append-only audit writes (plan §4 `audit_log`, M4). One row per
/// consequential action: key publish, re-grade run, review resolution,
/// report generation, retention purge.
///
/// The trail is evidence, not control flow: callers write AFTER the action
/// commits (or inside the same transaction when they already hold one) and
/// nothing reads it back to decide behaviour. Audit rows are therefore
/// best-effort by design at call sites outside a transaction — a grading
/// pass must not roll back because a log row was rejected.
class AuditLogService {
  AuditLogService(this.db);

  final AppDb db;

  /// Records one action. [before]/[after] are small JSON-able summaries —
  /// full row images are the sync outbox's job, this is the human-readable
  /// "who changed what when".
  Future<void> record({
    required String tenantId,
    required String entity,
    required String entityId,
    required String action,
    Map<String, Object?>? before,
    Map<String, Object?>? after,
    String? byUser,
  }) {
    return db
        .into(db.auditLog)
        .insert(
          AuditLogCompanion.insert(
            tenantId: tenantId,
            entity: entity,
            entityId: entityId,
            action: action,
            beforeJson: Value(
              before == null || before.isEmpty ? null : jsonEncode(before),
            ),
            afterJson: Value(
              after == null || after.isEmpty ? null : jsonEncode(after),
            ),
            byUser: Value(byUser),
          ),
        );
  }
}
