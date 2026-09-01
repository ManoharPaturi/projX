import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';

class Institutes extends Table {
  /// Client-generated UUID — the sync idempotency key.
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get code => text()();
  TextColumn get createdAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
