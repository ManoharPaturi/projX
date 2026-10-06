import 'package:drift/drift.dart';

import '../converters.dart';

/// Operator-tunable settings, one row per tenant (plan §6 screen 12: the
/// threshold preset and retention policy surfaces that "arrive with
/// calibration, M4").
///
/// Strictness names mirror omr_detect's `Strictness` members verbatim
/// ('strict' | 'normal' | 'relaxed') but this package does NOT depend on
/// omr_detect — the detection package owns the enum, the app maps between.
/// Stored as plain TEXT for the same reason every enum here is textEnum:
/// raw-SQL readers must see readable values.
class AppSettings extends Table {
  TextColumn get tenantId => text()();

  /// Capture-strictness preset for the quality gates (not the marking
  /// thresholds — those are identical across presets so scores stay
  /// comparable). Default 'normal'.
  TextColumn get strictness => text().withDefault(const Constant('normal'))();

  /// Days a 12MP capture original is kept before the retention sweep drops
  /// it (the warped grayscale + annotated thumb stay forever — they are the
  /// review substrate). Default 7.
  IntColumn get retentionGraceDays =>
      integer().withDefault(const Constant(7))();

  TextColumn get updatedAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();

  @override
  Set<Column> get primaryKey => {tenantId};
}
