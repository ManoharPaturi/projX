import 'package:drift/drift.dart';

import '../converters.dart';

/// The tenant root. The MVP runs with exactly one row (plan §4); every other
/// domain table carries `tenant_id` as its LEADING column and is indexed
/// tenant-first so the phase-2 hosted schema is a mechanical lift.
class Tenants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get plan => text()();

  /// ISO-8601 UTC TEXT — see [IsoDateTimeConverter].
  TextColumn get createdAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();

  @override
  Set<Column> get primaryKey => {id};
}
