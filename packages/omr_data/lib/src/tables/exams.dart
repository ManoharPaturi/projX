import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'institutes.dart';
import 'sheet_layouts.dart';

class Exams extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();

  /// Audited history wins over tidy deletes: an exam outlives its institute
  /// record (results reference exams with RESTRICT anyway).
  TextColumn get instituteId =>
      text().references(Institutes, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get heldAt => text()
      .map(const IsoDateTimeConverter())
      .nullable()
      .clientDefault(nowIsoUtc)();

  /// Layouts are immutable printed artifacts — never delete under an exam.
  TextColumn get sheetLayoutId =>
      text().references(SheetLayouts, #id, onDelete: KeyAction.restrict)();
  IntColumn get totalQuestions => integer()();
  TextColumn get status =>
      textEnum<ExamStatus>().withDefault(const Constant('draft'))();

  /// JSON: scoring preset + section overrides selected in exam setup.
  TextColumn get gradingConfigJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get createdAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
