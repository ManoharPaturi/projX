import 'dart:io';

import 'package:drift/native.dart';
import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// v3 adds two lookup indexes. A fresh database gets them from onCreate; a
/// v2 database gets them from the upgrade step — and the per-sheet queries
/// they exist for must actually use them.
void main() {
  Future<List<String>> plan(AppDb db, String sql) async => [
    for (final row in await db.customSelect('EXPLAIN QUERY PLAN $sql').get())
      row.read<String>('detail'),
  ];

  Future<Set<String>> indexNames(AppDb db) async => {
    for (final row
        in await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
            .get())
      row.read<String>('name'),
  };

  test('fresh databases have the v3 indexes and use them', () async {
    final db = await openTestDb();
    addTearDown(db.close);

    expect(
      await indexNames(db),
      containsAll(['ix_review_scan_outcome', 'ix_akv_exam_version']),
    );
    expect(
      await plan(
        db,
        "SELECT * FROM review_queue WHERE scan_id = 'x' AND outcome = 'open'",
      ),
      contains(contains('ix_review_scan_outcome')),
    );
    expect(
      await plan(
        db,
        "SELECT * FROM answer_key_versions WHERE exam_id = 'x' "
        'ORDER BY version DESC',
      ),
      contains(contains('ix_akv_exam_version')),
    );
  });

  test('a v2 database gains the v3 indexes on upgrade', () async {
    final dir = await Directory.systemTemp.createTemp('omr_v3_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.db');

    // Build the current schema, then roll it back to what v2 shipped.
    final first = AppDb(NativeDatabase(file));
    await first.customSelect('SELECT 1').get();
    await first.customStatement('DROP INDEX ix_review_scan_outcome');
    await first.customStatement('DROP INDEX ix_akv_exam_version');
    await first.customStatement('PRAGMA user_version = 2');
    await first.close();

    final upgraded = AppDb(NativeDatabase(file));
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();
    expect(
      await indexNames(upgraded),
      containsAll(['ix_review_scan_outcome', 'ix_akv_exam_version']),
    );
    final version = await upgraded
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 3);
  });
}
