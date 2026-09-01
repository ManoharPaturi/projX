import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';

/// Phase-2 sync outbox (plan §4 `†`, M5): DAO writes enqueue rows here in the
/// SAME transaction as the write (no triggers, by design); the drainer in
/// `lib/sync/sync_outbox.dart` replays them to a transport later. Client UUID
/// row ids make replay idempotent on the server.
@DataClassName('SyncOutboxEntry')
class SyncOutbox extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();

  /// SQL name pinned to `table_name` — the Dart getter can't be `tableName`
  /// because [Table.tableName] already owns that member.
  TextColumn get targetTable => text().named('table_name')();
  TextColumn get rowId => text()();
  TextColumn get op => textEnum<SyncOp>()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastAttemptAt => text().map(nullableIsoDate).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
