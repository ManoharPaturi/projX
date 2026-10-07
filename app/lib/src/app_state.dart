import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:omr_data/omr_data.dart';

import 'db/open_db.dart';

/// Root application state: the db handle plus who the operator is.
///
/// Screens talk to the db directly (they know their query); this object is
/// the identity holder and the change signal. `version` bumps on every
/// mutation so FutureBuilders keyed on it re-run their query — the cheap
/// stand-in for reactive drift streams until a screen needs real-time ones.
class AppState extends ChangeNotifier {
  AppState({
    required this.db,
    required this.instituteId,
    required String instituteName,
  }) : _instituteName = instituteName;

  final AppDb db;
  final String instituteId;
  String _instituteName;

  /// The name printed on reports and shown in the app bar.
  String get instituteName => _instituteName;

  /// True until the operator replaces the first-run placeholder name.
  bool get instituteNamed => _instituteName != kDefaultInstituteName;

  /// Monotonic data-change counter — use as a FutureBuilder key.
  int version = 0;

  String get tenantId => kTenantId;

  /// Production boot: open the on-device db and run the first-run seed.
  static Future<AppState> boot() async {
    final db = await openAppDb();
    // The seed guarantees exactly one institute for the MVP tenant.
    final rows = await (db.select(
      db.institutes,
    )..where((Institutes i) => i.tenantId.equals(kTenantId))).get();
    final row = rows.single;
    // Sweep now: originals past the grace window (a previous session's
    // captures) go before the operator touches anything. A failure must not
    // block boot — the next launch sweeps again.
    await runRetentionSweep(db).catchError((Object error) {
      debugPrint('retention sweep skipped: $error');
      return RetentionReport(purged: const [], missing: const []);
    });
    return AppState(db: db, instituteId: row.id, instituteName: row.name);
  }

  /// Renames the institute (reports and the app bar pick it up at once).
  Future<void> renameInstitute(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _instituteName) return;
    await (db.update(db.institutes)
          ..where((Institutes i) => i.id.equals(instituteId)))
        .write(InstitutesCompanion(name: Value(trimmed)));
    await AuditLogService(db).record(
      tenantId: tenantId,
      entity: 'institutes',
      entityId: instituteId,
      action: 'rename',
      before: {'name': _instituteName},
      after: {'name': trimmed},
    );
    _instituteName = trimmed;
    refresh();
  }

  /// Signal "data changed" to every listening screen.
  void refresh() {
    version++;
    notifyListeners();
  }

  /// Full grading pass over (exam, key version) + the change signal.
  Future<void> grade(String examId, String keyVersionId) async {
    await GradingService(
      db,
    ).gradeExam(tenantId: tenantId, examId: examId, keyVersionId: keyVersionId);
    refresh();
  }
}
