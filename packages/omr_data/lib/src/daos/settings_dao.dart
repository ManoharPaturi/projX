import 'package:drift/drift.dart';

import '../app_db.dart';
import '../tables/app_settings.dart';

part 'settings_dao.g.dart';

/// The typed read of [AppSettings] — strictness as the omr_detect member
/// name, defaults applied when no row exists yet.
class TenantSettings {
  const TenantSettings({
    required this.strictness,
    required this.retentionGraceDays,
  });

  const TenantSettings.defaults()
    : strictness = 'normal',
      retentionGraceDays = 7;

  final String strictness;
  final int retentionGraceDays;

  bool get isValid =>
      const ['strict', 'normal', 'relaxed'].contains(strictness) &&
      retentionGraceDays > 0;
}

/// Per-tenant operator settings (plan §6 screen 12). Reads are
/// load-or-default: a fresh install sees sane values before anything has
/// ever written a row, and a corrupt strictness string degrades to the
/// default rather than poisoning the capture path.
@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDb> with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  /// Current settings, defaults when the row is missing or invalid.
  Future<TenantSettings> settingsFor(String tenantId) async {
    final row = await (select(
      appSettings,
    )..where((AppSettings s) => s.tenantId.equals(tenantId))).getSingleOrNull();
    if (row == null) return const TenantSettings.defaults();
    final settings = TenantSettings(
      strictness: row.strictness,
      retentionGraceDays: row.retentionGraceDays,
    );
    return settings.isValid ? settings : const TenantSettings.defaults();
  }

  /// Upsert — the only write. Null fields keep their stored (or default)
  /// value; an unknown strictness name is refused rather than persisted.
  Future<void> write({
    required String tenantId,
    String? strictness,
    int? retentionGraceDays,
  }) async {
    if (strictness != null &&
        !const ['strict', 'normal', 'relaxed'].contains(strictness)) {
      throw ArgumentError.value(strictness, 'strictness');
    }
    if (retentionGraceDays != null && retentionGraceDays <= 0) {
      throw ArgumentError.value(retentionGraceDays, 'retentionGraceDays');
    }
    final existing = await (select(
      appSettings,
    )..where((AppSettings s) => s.tenantId.equals(tenantId))).getSingleOrNull();
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        tenantId: tenantId,
        strictness: Value(strictness ?? existing?.strictness ?? 'normal'),
        retentionGraceDays: Value(
          retentionGraceDays ?? existing?.retentionGraceDays ?? 7,
        ),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
