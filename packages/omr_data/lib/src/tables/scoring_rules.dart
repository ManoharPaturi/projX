import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../enums.dart';

/// Named marking scheme rows — marking is data (plan §5): a rule selects a
/// strategy plus its params; per-question overrides fall back to these.
class ScoringRules extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();
  TextColumn get name => text()();
  TextColumn get strategy => textEnum<ScoringStrategyKind>()();

  /// JSON params, e.g. `{'correct': 4, 'wrong': -1, 'unattempted': 0}`.
  TextColumn get paramsJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}
