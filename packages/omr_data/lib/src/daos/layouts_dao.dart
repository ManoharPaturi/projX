import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:omr_spec/omr_spec.dart';

import '../app_db.dart';
import '../enums.dart';
import '../tables/sheet_layouts.dart';

part 'layouts_dao.g.dart';

/// A layout row together with the spec it must still round-trip to.
@immutable
class ValidatedSpec {
  const ValidatedSpec({required this.row, required this.spec});

  final SheetLayout row;
  final SheetSpec spec;
}

/// Layouts are immutable printed artifacts keyed by (layout_id, layout_version)
/// — the pair the sheet QR encodes. The stored [SheetLayouts.specHash] is the
/// template-vs-print drift guard (plan risk #4): every load re-derives
/// `specSha256` and refuses to hand out a spec whose hash moved.
@DriftAccessor(tables: [SheetLayouts])
class LayoutsDao extends DatabaseAccessor<AppDb> with _$LayoutsDaoMixin {
  LayoutsDao(super.attachedDatabase);

  /// Idempotent upsert of a spec.
  ///
  /// - new (layoutId, layoutVersion): inserts, storing the CANONICAL JSON so
  ///   the row is byte-stable and re-hashable;
  /// - same identity, same hash: no-op, returns the existing row id;
  /// - same identity, different hash: refuses — a geometry change behind an
  ///   already-printed QR must bump layoutVersion, never patch the row.
  Future<String> upsertSpec({
    required String tenantId,
    required SheetSpec spec,
  }) async {
    final hash = specSha256(spec);
    final existing =
        await (select(sheetLayouts)..where(
              (SheetLayouts l) =>
                  l.layoutId.equals(spec.layoutId) &
                  l.layoutVersion.equals(spec.layoutVersion),
            ))
            .getSingleOrNull();
    if (existing != null) {
      if (existing.specHash != hash) {
        throw StateError(
          'specHash mismatch for ${spec.layoutId} v${spec.layoutVersion}: '
          'stored ${existing.specHash}, incoming $hash. Layouts are '
          'immutable — bump layoutVersion instead.',
        );
      }
      return existing.id;
    }
    return transaction(() async {
      final inserted = await into(sheetLayouts).insertReturning(
        SheetLayoutsCompanion.insert(
          tenantId: tenantId,
          layoutId: spec.layoutId,
          layoutVersion: spec.layoutVersion,
          specJson: spec.canonicalJson(),
          specHash: hash,
        ),
      );
      final id = inserted.id;
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'sheet_layouts',
        rowId: id,
        op: SyncOp.insert,
        payload: <String, Object?>{
          'layoutId': spec.layoutId,
          'layoutVersion': spec.layoutVersion,
          'specHash': hash,
        },
      );
      return id;
    });
  }

  /// Resolves the exact row a printed QR points at. Throws if the version
  /// does not resolve — detection must refuse, not guess (plan §2).
  Future<SheetLayout> byIdentity(String layoutId, int layoutVersion) {
    return (select(sheetLayouts)..where(
          (SheetLayouts l) =>
              l.layoutId.equals(layoutId) &
              l.layoutVersion.equals(layoutVersion),
        ))
        .getSingle();
  }

  /// Loads a spec, validates it against the omr_spec schema, and re-verifies
  /// its hash against the stored value. All three must pass.
  Future<ValidatedSpec> loadValidated(
    String layoutId,
    int layoutVersion,
  ) async {
    final row = await byIdentity(layoutId, layoutVersion);
    final Object? decoded;
    try {
      decoded = jsonDecode(row.specJson);
    } on FormatException {
      throw StateError(
        'corrupt specJson for $layoutId v$layoutVersion (row ${row.id})',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw StateError(
        'specJson for $layoutId v$layoutVersion is not a JSON object',
      );
    }
    final spec = SheetSpec.fromJson(decoded);
    if (specSha256(spec) != row.specHash) {
      throw StateError(
        'specHash mismatch for $layoutId v$layoutVersion: row says '
        '${row.specHash}, spec hashes to ${specSha256(spec)} — the stored '
        'layout was tampered with or edited out-of-band.',
      );
    }
    return ValidatedSpec(row: row, spec: validateOrThrow(spec));
  }

  /// Active layouts offered in exam setup.
  Future<List<SheetLayout>> activeForTenant(String tenantId) {
    return (select(sheetLayouts)
          ..where(
            (SheetLayouts l) =>
                l.tenantId.equals(tenantId) & l.isActive.equals(true),
          )
          ..orderBy([(SheetLayouts l) => OrderingTerm.asc(l.layoutId)]))
        .get();
  }
}
