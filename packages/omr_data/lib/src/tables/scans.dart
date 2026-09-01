import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';
import '../enums.dart';
import 'exams.dart';
import 'students.dart';

/// One captured sheet. `id` is minted ON THE CLIENT at capture time — it is
/// the replay and sync idempotency key (plan §4/M5: same scan uploaded twice
/// ⇒ one row). It is the GLOBAL primary key, not merely unique per exam: a
/// capture UUID names one physical sheet, M5's server replay conflicts on id
/// alone, and bubble_reads/results FKs reference scans.id by itself.
///
/// The v1 migration's `ux_scans_exam_id (exam_id, id)` unique index therefore
/// adds no constraint the PK doesn't already imply — it exists as the
/// exam-leading lookup index for "all scans of an exam".
class Scans extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();

  /// Exams with scans are never silently deleted.
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.restrict)();

  /// Resolved roster match; NULL until roll+roster agree or a human confirms.
  /// SET NULL: the sheet evidence (roll read, images) outlives the roster row.
  TextColumn get studentId => text().nullable().references(
    Students,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Raw decoded roll digits — kept even after resolution, as evidence.
  TextColumn get rollNoRead => text().nullable()();
  RealColumn get rollConfidence => real().nullable()();

  /// Bubbled set code ('A'..'D'); blank/multi route to mandatory review.
  TextColumn get setCodeRead => text().nullable()();

  /// The layout version this sheet was read against (from the QR).
  IntColumn get layoutVersion => integer()();

  /// Threshold-config id (omr_detect); TEXT id, no FK — the thresholds table
  /// belongs to the detection package, not this schema.
  TextColumn get thresholdConfigId => text().nullable()();
  TextColumn get capturedAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();
  TextColumn get deviceId => text().nullable()();

  /// Retained image set (plan risk #9): warped grayscale + annotated thumb
  /// always; the 12MP original only during the retention grace window.
  TextColumn get warpedImagePath => text()();
  TextColumn get thumbPath => text()();
  TextColumn get annotatedPath => text()();
  TextColumn get originalPath => text().nullable()();

  /// Per-sheet confidence from the aggregator (plan §3 stage 10).
  RealColumn get sheetConfidence => real().nullable()();

  /// JSON: the five capture-gate scores at shutter time.
  TextColumn get gateReportJson => text().withDefault(const Constant('{}'))();

  /// Timing-track curvature residual exceeded tolerance (plan §3 stage 4).
  BoolColumn get curlFlag => boolean().withDefault(const Constant(false))();

  /// Safe-by-default: an unrouted scan is a review candidate, never a mark.
  TextColumn get status =>
      textEnum<ScanStatus>().withDefault(const Constant('needsReview'))();
  TextColumn get syncState =>
      textEnum<SyncState>().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
