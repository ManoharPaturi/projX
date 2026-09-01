import 'package:drift/drift.dart';

import 'exams.dart';

/// Per-set question mapping: sheet ordinal → canonical question id, so set
/// codes A/B/C/D shuffle paper positions without shuffling the key.
class QuestionSets extends Table {
  TextColumn get tenantId => text()();

  /// Sets die with their exam.
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.cascade)();
  TextColumn get setCode => text()();
  TextColumn get questionMapJson => text()();

  @override
  Set<Column> get primaryKey => {examId, setCode};
}
