import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Roster import semantics (plan §6 screen 4): additive, never destructive,
/// every skip explained.
void main() {
  late AppDb db;
  late String instituteId;

  setUp(() async {
    db = await openTestDb();
    instituteId = await seedInstitute(db);
  });

  tearDown(() => db.close());

  test('imports new rolls and reports existing ones without updating them',
      () async {
    await db.studentsDao.importRoster(kTenantId, instituteId, const [
      RosterEntry(rollNo: 'R001', name: 'First'),
    ]);

    final second = await db.studentsDao.importRoster(kTenantId, instituteId, [
      const RosterEntry(rollNo: 'R001', name: 'Imposter'),
      const RosterEntry(rollNo: 'R002'),
    ]);

    expect(second.imported, 1);
    expect(second.existingRolls, ['R001']);
    expect(second.clean, isFalse);

    // An import must never rewrite an enrolled student's name.
    final roster = await db.studentsDao.rosterFor(instituteId);
    expect(roster.singleWhere((s) => s.rollNo == 'R001').name, 'First');
    expect(roster.map((s) => s.rollNo), ['R001', 'R002']);
  });

  test('repeats inside one file keep only the first copy', () async {
    final result = await db.studentsDao.importRoster(kTenantId, instituteId, [
      const RosterEntry(rollNo: 'R001', name: 'Winner'),
      const RosterEntry(rollNo: 'R001', name: 'Loser'),
      const RosterEntry(rollNo: 'R001', name: 'Also loser'),
    ]);

    expect(result.imported, 1);
    expect(result.duplicatesInFile, ['R001', 'R001']);
    expect(await db.studentsDao.count(instituteId), 1);
    expect(
      (await db.studentsDao.rosterFor(instituteId)).single.name,
      'Winner',
    );
  });

  test('blank rolls are refused before touching the table', () async {
    final result = await db.studentsDao.importRoster(kTenantId, instituteId, [
      const RosterEntry(rollNo: '  ', name: 'no roll'),
      const RosterEntry(rollNo: 'R001'),
    ]);

    expect(result.imported, 1);
    expect(result.invalidRolls, ['  ']);
    expect(await db.studentsDao.count(instituteId), 1);
  });

  test('a whole-file failure lands nothing (transaction)', () async {
    await db.studentsDao.importRoster(kTenantId, instituteId, const [
      RosterEntry(rollNo: 'R001'),
    ]);

    // institute must exist per the FK; pointing at a junk institute makes
    // every insert throw — the transaction must leave the roster untouched.
    await expectLater(
      db.studentsDao.importRoster(kTenantId, 'no-such-institute', const [
        RosterEntry(rollNo: 'R002'),
      ]),
      throwsA(isA<Exception>()),
    );
    expect(await db.studentsDao.count(instituteId), 1);
  });

  test('rosterFor filters by roll substring, ordered', () async {
    await db.studentsDao.importRoster(kTenantId, instituteId, [
      for (final roll in const ['R010', 'A002', 'R011', 'A001'])
        RosterEntry(rollNo: roll),
    ]);

    expect(
      (await db.studentsDao.rosterFor(instituteId)).map((s) => s.rollNo),
      ['A001', 'A002', 'R010', 'R011'],
    );
    expect(
      (await db.studentsDao.rosterFor(instituteId, query: 'r01'))
          .map((s) => s.rollNo),
      ['R010', 'R011'],
      reason: 'case-insensitive roll filter for the search box',
    );
  });
}
