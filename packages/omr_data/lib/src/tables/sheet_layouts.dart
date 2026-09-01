import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../converters.dart';

/// One immutable printed layout: (layout_id, layout_version) is what the
/// sheet QR encodes, and [specHash] is the template-vs-print drift guard
/// (plan risk #4) — re-verified on every load by `LayoutsDao`.
class SheetLayouts extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get tenantId => text()();
  TextColumn get layoutId => text()();
  IntColumn get layoutVersion => integer()();

  /// Canonical JSON of the `SheetSpec` (omr_spec) — round-trips through
  /// `SheetSpec.fromJson`.
  TextColumn get specJson => text()();

  /// `specSha256(spec)` — sha256 hex of the spec's canonical JSON.
  TextColumn get specHash => text()();
  TextColumn get createdAt =>
      text().map(const IsoDateTimeConverter()).clientDefault(nowIsoUtc)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  // UNIQUE(layoutId, layoutVersion) is enforced by the
  // ux_sheet_layouts_id_version unique index created in the v1 migration.
}
