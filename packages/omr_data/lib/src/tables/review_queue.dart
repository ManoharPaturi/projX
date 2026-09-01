import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'scans.dart';

/// The human review queue — the product surface that turns ~90% machine
/// accuracy into ~99%+ (plan risk #1). One row per reason a scan was routed
/// to review; a scan can carry several.
@DataClassName('ReviewQueueItem')
class ReviewQueue extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();

  /// Queue items die with their scan.
  TextColumn get scanId =>
      text().references(Scans, #id, onDelete: KeyAction.cascade)();

  /// e.g. ROLL_CHECKSUM_MISMATCH, ROLL_NOT_ON_ROSTER, SET_CODE_INVALID,
  /// MULTI_BUBBLE_WARN, PROBABLE_BUBBLE, LOW_SHEET_CONFIDENCE, CURL_FLAGGED,
  /// NO_MARKER_ERR (plan §3).
  TextColumn get reasonCode => text()();

  /// JSON array of field keys the reason refers to, e.g. '["q17","q18"]'.
  TextColumn get fieldRefsJson => text().withDefault(const Constant('[]'))();
  TextColumn get severity => textEnum<ReviewSeverity>()();
  TextColumn get resolvedBy => text().nullable()();
  TextColumn get resolvedAt => text().map(nullableIsoDate).nullable()();

  /// JSON array of applied corrections (see ReviewDao.resolve).
  TextColumn get correctionJson => text().nullable()();
  TextColumn get outcome =>
      textEnum<ReviewOutcome>().withDefault(const Constant('open'))();

  @override
  Set<Column> get primaryKey => {id};
}
