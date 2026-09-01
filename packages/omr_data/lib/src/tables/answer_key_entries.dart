import 'package:drift/drift.dart';

import '../enums.dart';
import 'answer_key_versions.dart';
import 'scoring_rules.dart';

/// One key row per (version, set, question). Composite PK; INSERT-only — a
/// BEFORE UPDATE trigger raised in the v1 migration makes any UPDATE abort.
class AnswerKeyEntries extends Table {
  TextColumn get tenantId => text()();

  /// Entries die with their version.
  TextColumn get keyVersionId =>
      text().references(AnswerKeyVersions, #id, onDelete: KeyAction.cascade)();

  /// Set code ('A'..'D', or '' for single-set papers).
  TextColumn get setCode => text()();

  /// Canonical question id, e.g. 'q17'.
  TextColumn get questionId => text()();

  /// JSON array of correct option indexes into the bubble row,
  /// e.g. '[0]' or '[0, 2]' for multi-correct.
  TextColumn get correctOptionsJson =>
      text().withDefault(const Constant('[]'))();

  /// For integer-digit questions (JEE-Adv numeric), if applicable.
  IntColumn get correctInteger => integer().nullable()();

  /// NTA key-correction state, first-class (plan §5).
  TextColumn get state =>
      textEnum<KeyEntryState>().withDefault(const Constant('normal'))();

  /// Per-question scoring override, if any.
  TextColumn get scoringRuleId => text().nullable().references(
    ScoringRules,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {keyVersionId, setCode, questionId};
}
