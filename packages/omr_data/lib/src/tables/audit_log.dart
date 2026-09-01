import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

/// Append-only audit trail (plan M4): entity, action, before/after JSON.
@DataClassName('AuditLogEntry')
class AuditLog extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get action => text()();
  TextColumn get beforeJson => text().nullable()();
  TextColumn get afterJson => text().nullable()();
  TextColumn get at =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();
  TextColumn get byUser => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
