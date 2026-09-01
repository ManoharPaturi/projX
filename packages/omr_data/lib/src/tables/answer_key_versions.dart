import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'exams.dart';

/// An immutable answer-key version (plan §5): editing a key ALWAYS inserts a
/// new version row that supersedes the old one. There is deliberately no API
/// that edits a version in place beyond the provisional→finalized transition;
/// `answer_key_entries` is additionally frozen by a BEFORE UPDATE trigger
/// created in the v1 migration (see immutability_test).
class AnswerKeyVersions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();

  /// Key versions die with their exam — unless results still reference them,
  /// in which case the RESTRICT on results blocks the delete (audit wins).
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.cascade)();
  IntColumn get version => integer()();
  TextColumn get status =>
      textEnum<KeyVersionStatus>().withDefault(const Constant('provisional'))();

  /// The version this one replaces, if any. SET NULL on delete because old
  /// versions are never deleted in practice and the chain must not block.
  TextColumn get supersedesId => text().nullable().references(
    AnswerKeyVersions,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get createdBy => text()();
  TextColumn get createdAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();

  @override
  Set<Column> get primaryKey => {id};
}
