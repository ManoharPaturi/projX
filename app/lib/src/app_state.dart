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
    required this.instituteName,
  });

  final AppDb db;
  final String instituteId;
  final String instituteName;

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
    return AppState(
      db: db,
      instituteId: row.id,
      instituteName: row.name,
    );
  }

  /// Signal "data changed" to every listening screen.
  void refresh() {
    version++;
    notifyListeners();
  }

  /// Full grading pass over (exam, key version) + the change signal.
  Future<void> grade(String examId, String keyVersionId) async {
    await GradingService(db).gradeExam(
      tenantId: tenantId,
      examId: examId,
      keyVersionId: keyVersionId,
    );
    refresh();
  }
}
