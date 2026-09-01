import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'exams.dart';

/// Every generated report/export is traceable and reproducible (plan §7):
/// params + produced path are recorded per job.
class ReportJobs extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();

  /// Report artifacts are regenerable — they die with the exam.
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => textEnum<ReportJobType>()();
  TextColumn get format => text()();
  TextColumn get paramsJson => text()();
  TextColumn get filePath => text().nullable()();
  TextColumn get status =>
      textEnum<ReportJobStatus>().withDefault(const Constant('queued'))();
  TextColumn get generatedAt => text().map(nullableIsoDate).nullable()();
  TextColumn get errorText => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
