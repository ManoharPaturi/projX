import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// The ranking fixture: 5 students with totals [100, 90, 90, 80, 70].
///
/// RANK() — not ROW_NUMBER() — is load-bearing here: the two 90s SHARE rank 2
/// and the next student gets rank 4 (skipped), which is what merit lists and
/// tie-resolution rules expect.
void main() {
  late AppDb db;
  late String examId;
  late String keyVersionId;
  late String scoringRunId;
  late List<String> studentIds;
  late List<String> scanIds;

  Future<List<double>> totalsInRankOrder() async {
    final rows = await db.resultsDao.resultsFor(examId, keyVersionId);
    return rows.map((r) => r.result.total).toList();
  }

  setUp(() async {
    db = await openTestDb();
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
    keyVersionId = await seedKeyVersion(db, examId);
    scoringRunId = await seedScoringRun(db, examId, keyVersionId);
    studentIds = await seedStudents(db, instituteId, 5);
    scanIds = [];
    for (var i = 0; i < studentIds.length; i++) {
      scanIds.add(
        await db.scansDao.insertScanWithReads(
          scanRow(
            examId: examId,
            studentId: studentIds[i],
            rollNoRead: 'R00${i + 1}',
            setCodeRead: 'A',
          ),
          const [],
        ),
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  test('batch upsert + recomputeRanks assigns SHARED ranks to ties', () async {
    const totals = [100.0, 90.0, 90.0, 80.0, 70.0];
    await db.resultsDao.upsertResults(kTenantId, [
      for (var i = 0; i < 5; i++)
        resultRow(
          examId: examId,
          studentId: studentIds[i],
          keyVersionId: keyVersionId,
          scoringRunId: scoringRunId,
          scanId: scanIds[i],
          total: totals[i],
        ),
    ]);
    await db.resultsDao.recomputeRanks(examId, keyVersionId);

    final rows = await db.resultsDao.resultsFor(examId, keyVersionId);
    expect(rows.length, 5);

    final rankByStudent = <String, int?>{
      for (final r in rows) r.student.id: r.result.rank,
    };
    expect(rankByStudent[studentIds[0]], 1);
    expect(rankByStudent[studentIds[1]], 2);
    expect(
      rankByStudent[studentIds[2]],
      2,
      reason: 'a tie shares the rank — ROW_NUMBER would have said 3',
    );
    expect(
      rankByStudent[studentIds[3]],
      4,
      reason: 'the rank after a 2-way tie skips to 4',
    );
    expect(rankByStudent[studentIds[4]], 5);

    // Rank order: leader first, the 90-tie next (either internal order —
    // ranks are equal), tail last.
    expect(await totalsInRankOrder(), [100.0, 90.0, 90.0, 80.0, 70.0]);
    final rankOrder = rows.map((r) => r.result.rank).toList();
    expect(rankOrder, [1, 2, 2, 4, 5]);

    // The join carried the roster row along.
    expect(rows.first.student.rollNo, 'R001');
  });

  test(
    're-upserting the same natural key replaces in place, never duplicates',
    () async {
      Future<void> grade(List<double> totals) async {
        await db.resultsDao.upsertResults(kTenantId, [
          for (var i = 0; i < totals.length; i++)
            resultRow(
              examId: examId,
              studentId: studentIds[i],
              keyVersionId: keyVersionId,
              scoringRunId: scoringRunId,
              scanId: scanIds[i],
              total: totals[i],
            ),
        ]);
        await db.resultsDao.recomputeRanks(examId, keyVersionId);
      }

      await grade([100, 90, 90, 80, 70]);
      expect((await db.select(db.results).get()).length, 5);

      // A corrected key re-grades the SAME exam + version: upsert by natural
      // key, swap the leader, recompute — still exactly 5 rows.
      await grade([80, 100, 90, 90, 70]);

      final stored = await db.select(db.results).get();
      expect(
        stored.length,
        5,
        reason:
            'the natural key (exam, student, keyVersion) deduplicated the '
            're-grade instead of appending',
      );

      final rows = await db.resultsDao.resultsFor(examId, keyVersionId);
      final rankByStudent = <String, int?>{
        for (final r in rows) r.student.id: r.result.rank,
      };
      expect(rankByStudent[studentIds[0]], 4); // 80: dropped from 1st
      expect(rankByStudent[studentIds[1]], 1); // 100: new leader
      expect(rankByStudent[studentIds[2]], 2);
      expect(rankByStudent[studentIds[3]], 2);
      expect(rankByStudent[studentIds[4]], 5);
      expect(await totalsInRankOrder(), [100.0, 90.0, 90.0, 80.0, 70.0]);
    },
  );

  test('upsertResults refuses rows from more than one scoring run', () async {
    final otherRunId = await seedScoringRun(db, examId, keyVersionId);
    await expectLater(
      db.resultsDao.upsertResults(kTenantId, [
        resultRow(
          examId: examId,
          studentId: studentIds[0],
          keyVersionId: keyVersionId,
          scoringRunId: scoringRunId,
          scanId: scanIds[0],
          total: 10,
        ),
        resultRow(
          examId: examId,
          studentId: studentIds[1],
          keyVersionId: keyVersionId,
          scoringRunId: otherRunId,
          scanId: scanIds[1],
          total: 20,
        ),
      ]),
      throwsA(isA<ArgumentError>()),
    );
    expect(await db.select(db.results).get(), isEmpty);
  });

  test('ranks are per key version: two versions rank independently', () async {
    final v2 = await seedKeyVersion(db, examId, version: 2);
    final run2 = await seedScoringRun(db, examId, v2);

    // One upsertResults per run — the DAO refuses a mixed-run batch.
    await db.resultsDao.upsertResults(kTenantId, [
      resultRow(
        examId: examId,
        studentId: studentIds[0],
        keyVersionId: keyVersionId,
        scoringRunId: scoringRunId,
        scanId: scanIds[0],
        total: 100,
      ),
      resultRow(
        examId: examId,
        studentId: studentIds[1],
        keyVersionId: keyVersionId,
        scoringRunId: scoringRunId,
        scanId: scanIds[1],
        total: 90,
      ),
    ]);
    await db.resultsDao.upsertResults(kTenantId, [
      resultRow(
        examId: examId,
        studentId: studentIds[0],
        keyVersionId: v2,
        scoringRunId: run2,
        scanId: scanIds[0],
        total: 50,
      ),
      resultRow(
        examId: examId,
        studentId: studentIds[1],
        keyVersionId: v2,
        scoringRunId: run2,
        scanId: scanIds[1],
        total: 60,
      ),
    ]);
    await db.resultsDao.recomputeRanks(examId, keyVersionId);
    await db.resultsDao.recomputeRanks(examId, v2);

    final v1Ranks = <String, int?>{
      for (final r in await db.resultsDao.resultsFor(examId, keyVersionId))
        r.student.id: r.result.rank,
    };
    final v2Ranks = <String, int?>{
      for (final r in await db.resultsDao.resultsFor(examId, v2))
        r.student.id: r.result.rank,
    };
    expect(v1Ranks[studentIds[0]], 1);
    expect(v1Ranks[studentIds[1]], 2);
    expect(
      v2Ranks[studentIds[0]],
      2,
      reason: 'student 0 lost the lead under v2',
    );
    expect(v2Ranks[studentIds[1]], 1);
  });
}
