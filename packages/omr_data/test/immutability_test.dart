import 'package:drift/drift.dart';
import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Answer keys are immutable and versioned (plan §5).
///
/// Layer 1 — compile time: [KeysDao] exposes exactly three write paths,
/// createVersion / addEntries (INSERT-only) and finalizeVersion (a status
/// UPDATE on answer_key_versions, never on the entries). There is no
/// updateEntry / deleteEntry / replaceEntries method and no companion shape
/// an entry mutation could sneak through `KeyEntryInput` — that absence IS
/// the guarantee this suite documents; adding any entry-mutating method must
/// fail this file's review, not its assertions.
///
/// Layer 2 — the database itself: the v1 migration installs a BEFORE UPDATE
/// trigger that RAISE(ABORT)s on answer_key_entries, so even a raw drift
/// write cannot smuggle an edit past the convention.
///
/// Layer 3 — history: correcting a key means a NEW version that supersedes,
/// and results keep pointing at whichever version graded them.
void main() {
  late AppDb db;
  late String examId;

  setUp(() async {
    db = await openTestDb();
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'the trigger aborts any UPDATE on answer_key_entries, even raw drift',
    () async {
      final keyVersionId = await seedKeyVersion(db, examId);
      await seedKeyEntries(db, keyVersionId, {
        'q1': [0],
      });

      // A deliberate, direct SQL-level write attempt: this is the exact escape
      // hatch the trigger exists to close.
      await expectLater(
        db.customUpdate(
          "UPDATE answer_key_entries SET correct_options_json = '[2]' "
          'WHERE key_version_id = ?',
          variables: [Variable.withString(keyVersionId)],
          updates: {db.answerKeyEntries},
        ),
        throwsA(isA<Exception>()),
      );

      final entries = await db.keysDao.entriesFor(keyVersionId);
      expect(
        entries.single.correctOptionsJson,
        '[0]',
        reason: 'the aborted UPDATE must have left the entry untouched',
      );
    },
  );

  test(
    'a corrected key is a NEW version that supersedes; both survive',
    () async {
      final v1 = await seedKeyVersion(db, examId, version: 1);
      await seedKeyEntries(db, v1, {
        'q1': [0],
        'q2': [1],
      });

      // Key q2 was wrong: supersede, don't edit.
      final v2 = await seedKeyVersion(db, examId, version: 2, supersedesId: v1);
      await seedKeyEntries(db, v2, {
        'q1': [0],
        'q2': [2],
      });

      final versions = await db.keysDao.versionsFor(examId);
      expect(versions.map((v) => v.id), containsAll([v1, v2]));
      expect(versions.length, 2, reason: 'the superseded version is retained');

      final v2Row = await db.keysDao.versionById(v2);
      expect(v2Row.supersedesId, v1);
      expect(v2Row.version, 2);

      // The wrong key stays exactly as published — that is the point.
      expect(
        (await db.keysDao.entriesFor(
          v1,
        )).firstWhere((e) => e.questionId == 'q2').correctOptionsJson,
        '[1]',
      );
      expect(
        (await db.keysDao.entriesFor(
          v2,
        )).firstWhere((e) => e.questionId == 'q2').correctOptionsJson,
        '[2]',
      );
    },
  );

  test(
    'finalizing a version freezes it: addEntries is refused afterwards',
    () async {
      final keyVersionId = await seedKeyVersion(db, examId);
      await seedKeyEntries(db, keyVersionId, {
        'q1': [0],
      });

      expect(
        (await db.keysDao.versionById(keyVersionId)).status,
        KeyVersionStatus.provisional,
      );
      await db.keysDao.finalizeVersion(keyVersionId);
      expect(
        (await db.keysDao.versionById(keyVersionId)).status,
        KeyVersionStatus.finalized,
      );

      await expectLater(
        db.keysDao.addEntries(
          keyVersionId,
          tenantId: kTenantId,
          entries: const [
            KeyEntryInput(setCode: 'A', questionId: 'q2', correctOptions: [1]),
          ],
        ),
        throwsA(isA<StateError>()),
      );
      expect((await db.keysDao.entriesFor(keyVersionId)).length, 1);

      // And finalizing twice is refused too — publish is one-way.
      await expectLater(
        db.keysDao.finalizeVersion(keyVersionId),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'activeVersion prefers the newest finalized, else newest provisional',
    () async {
      final v1 = await seedKeyVersion(db, examId, version: 1);
      final v2 = await seedKeyVersion(db, examId, version: 2);
      expect(
        (await db.keysDao.activeVersion(examId))!.id,
        v2,
        reason: 'nothing finalized yet — the newest draft grades',
      );

      await db.keysDao.finalizeVersion(v1);
      expect(
        (await db.keysDao.activeVersion(examId))!.id,
        v1,
        reason: 'a finalized key always beats a newer provisional one',
      );
    },
  );

  test('results keep their keyVersionId across re-grades', () async {
    final instituteId = (await db.select(db.institutes).get()).single.id;
    final studentIds = await seedStudents(db, instituteId, 1);
    final v1 = await seedKeyVersion(db, examId, version: 1);
    final v2 = await seedKeyVersion(db, examId, version: 2);
    final scanId = await db.scansDao.insertScanWithReads(
      scanRow(examId: examId, studentId: studentIds.single),
      const [],
    );

    // Grade against v1, then re-grade the same exam against v2: both result
    // rows coexist because keyVersionId is part of the natural key.
    final run1 = await seedScoringRun(db, examId, v1);
    final run2 = await seedScoringRun(db, examId, v2);
    // One upsertResults per run — the DAO refuses a mixed-run batch (each
    // batch must be one coherent audit snapshot).
    await db.resultsDao.upsertResults(kTenantId, [
      resultRow(
        examId: examId,
        studentId: studentIds.single,
        keyVersionId: v1,
        scoringRunId: run1,
        scanId: scanId,
        total: 40,
      ),
    ]);
    await db.resultsDao.upsertResults(kTenantId, [
      resultRow(
        examId: examId,
        studentId: studentIds.single,
        keyVersionId: v2,
        scoringRunId: run2,
        scanId: scanId,
        total: 44,
      ),
    ]);

    final byVersion = <String, double>{};
    for (final row in (await db.select(db.results).get())) {
      byVersion[row.keyVersionId] = row.total;
    }
    expect(byVersion, {
      v1: 40.0,
      v2: 44.0,
    }, reason: 'the v1 marksheet still renders after the v2 re-grade');
    expect(
      (await db.resultsDao.resultsFor(examId, v1)).single.result.total,
      40.0,
    );
  });
}
