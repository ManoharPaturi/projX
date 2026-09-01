import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// plan §4 shape guarantees: tenant-first schema, FK enforcement, cascade vs
/// restrict semantics, and the natural-key uniqueness that backs idempotency.
void main() {
  late AppDb db;

  setUp(() async {
    db = await openTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  test('PRAGMA foreign_keys is ON for the whole connection', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test('v1 creates exactly the 17 plan tables', () async {
    expect(db.allTables.length, 17);
  });

  test('v1 creates the natural-key unique indexes', () async {
    final names =
        (await db
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'ux_%'",
                )
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();
    expect(
      names,
      containsAll(<String>[
        'ux_students_institute_roll', // UNIQUE(instituteId, rollNo)
        'ux_sheet_layouts_id_version', // UNIQUE(layoutId, layoutVersion)
        'ux_scans_exam_id', // UNIQUE(examId, id) — replay idempotency
        'ux_results_exam_student_key', // UNIQUE(examId, studentId, keyVersionId)
      ]),
    );
  });

  test('deleting an institute cascades to its students', () async {
    final instituteId = await seedInstitute(db);
    await seedStudents(db, instituteId, 3);
    expect((await db.select(db.students).get()).length, 3);

    await (db.delete(
      db.institutes,
    )..where((Institutes i) => i.id.equals(instituteId))).go();

    expect(await db.select(db.students).get(), isEmpty);
  });

  test('deleting a scan cascades to its bubble reads', () async {
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    final examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
    final scanId = await db.scansDao
        .insertScanWithReads(scanRow(examId: examId), const [
          BubbleReadInput(
            fieldKey: 'q1',
            optionIndex: 0,
            markClass: MarkClass.filled,
          ),
          BubbleReadInput(
            fieldKey: 'q1',
            optionIndex: 1,
            markClass: MarkClass.empty,
          ),
        ]);
    expect((await db.select(db.bubbleReads).get()).length, 2);

    await (db.delete(db.scans)..where((Scans s) => s.id.equals(scanId))).go();

    expect(await db.select(db.bubbleReads).get(), isEmpty);
  });

  test('an orphan result insert is rejected by the FK constraint', () async {
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    final examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
    final keyVersionId = await seedKeyVersion(db, examId);
    final studentIds = await seedStudents(db, instituteId, 1);
    final scanId = await db.scansDao.insertScanWithReads(
      scanRow(examId: examId, studentId: studentIds.single),
      const [],
    );
    final runId = await seedScoringRun(db, examId, keyVersionId);

    await expectLater(
      db
          .into(db.results)
          .insert(
            resultRow(
              examId: examId,
              // No such student — RESTRICT must refuse the row outright
              // rather than leave a result nobody can render.
              studentId: 'no-such-student',
              keyVersionId: keyVersionId,
              scoringRunId: runId,
              scanId: scanId,
              total: 10,
            ),
          ),
      throwsA(isA<Exception>()),
    );
    expect(await db.select(db.results).get(), isEmpty);
  });

  test('results RESTRICT: a student with results cannot be deleted', () async {
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    final examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
    final keyVersionId = await seedKeyVersion(db, examId);
    final studentIds = await seedStudents(db, instituteId, 1);
    final scanId = await db.scansDao.insertScanWithReads(
      scanRow(examId: examId, studentId: studentIds.single),
      const [],
    );
    final runId = await seedScoringRun(db, examId, keyVersionId);
    await db
        .into(db.results)
        .insert(
          resultRow(
            examId: examId,
            studentId: studentIds.single,
            keyVersionId: keyVersionId,
            scoringRunId: runId,
            scanId: scanId,
            total: 10,
          ),
        );

    await expectLater(
      (db.delete(
        db.students,
      )..where((Students s) => s.id.equals(studentIds.single))).go(),
      throwsA(isA<Exception>()),
    );
    expect(
      (await db.select(db.results).get()).length,
      1,
      reason:
          'historical results are audit records — deleting the roster '
          'row that produced them is refused, never cascaded',
    );
  });

  test('UNIQUE(instituteId, rollNo) rejects a duplicate roll', () async {
    final instituteId = await seedInstitute(db);
    await seedStudents(db, instituteId, 1);
    await expectLater(
      db
          .into(db.students)
          .insert(
            StudentsCompanion.insert(
              tenantId: kTenantId,
              instituteId: instituteId,
              rollNo: 'R001',
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
