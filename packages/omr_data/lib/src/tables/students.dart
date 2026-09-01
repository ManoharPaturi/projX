import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'institutes.dart';

class Students extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// LEADING tenant column (plan §4: every domain table is tenant-first).
  TextColumn get tenantId => text()();

  /// Deleting an institute takes its roster with it (schema_test pins this).
  TextColumn get instituteId =>
      text().references(Institutes, #id, onDelete: KeyAction.cascade)();
  TextColumn get rollNo => text()();

  /// PII-min (plan risk #9): roll numbers, not names, are the student key.
  TextColumn get name => text().nullable()();
  TextColumn get batch => text().nullable()();
  TextColumn get createdAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};

  // UNIQUE(instituteId, rollNo) is enforced by the
  // ux_students_institute_roll unique index created in the v1 migration.
}
