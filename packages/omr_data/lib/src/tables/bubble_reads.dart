import 'package:drift/drift.dart';

import '../enums.dart';
import 'scans.dart';

/// The raw per-bubble read — the re-grade substrate (plan §5). Nothing here
/// is ever recomputed away: a corrected key re-grades from these rows, with
/// human corrections (isHumanCorrection = 1) superseding the machine read.
///
/// `optionIndex` is the bubble's index within the field row and matches
/// DetectionTemplate's BubbleRect.optionIndex exactly (omr_spec).
class BubbleReads extends Table {
  TextColumn get tenantId => text()();

  /// Reads die with their scan.
  TextColumn get scanId =>
      text().references(Scans, #id, onDelete: KeyAction.cascade)();

  /// 'q17' | 'roll3' | 'set' — the globally unique field key from the spec.
  TextColumn get fieldKey => text()();
  IntColumn get optionIndex => integer()();
  RealColumn get meanIntensity => real().nullable()();
  RealColumn get fillRatio => real().nullable()();
  TextColumn get markClass => textEnum<MarkClass>()();
  RealColumn get confidence => real().nullable()();
  RealColumn get thresholdUsed => real().nullable()();

  /// 1 when a review operator set this value — supersedes the raw read on
  /// every subsequent re-grade, deterministically.
  BoolColumn get isHumanCorrection =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {scanId, fieldKey, optionIndex};
}
