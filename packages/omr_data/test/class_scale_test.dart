import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// A whole class scanned sheet by sheet, the way intake grades it: one
/// incremental pass per new sheet. The end state must equal one full pass
/// over the same sheets — totals, counts and ranks — and the per-sheet cost
/// must not grow with the class (printed for the log, not asserted: host
/// timings are too noisy to gate on).
void main() {
  const classSize = 120;

  late AppDb db;
  late String examId;
  late String keyVersionId;
  late List<String> students;

  setUp(() async {
    db = await openTestDb();
    final institute = await seedInstitute(db);
    final layout = await seedLayout(db);
    examId = await seedExam(db, institute, sheetLayoutId: layout);
    keyVersionId = await seedKeyVersion(db, examId);
    await seedKeyEntries(db, keyVersionId, {
      for (var q = 1; q <= 90; q++) 'q$q': [q % 4],
    });
    students = await seedStudents(db, institute, classSize);
  });

  tearDown(() => db.close());

  /// Student s bubbles option (q + s) % 4 on every question, plus empty roll
  /// columns — a full sheet's worth of bubble rows.
  Future<String> scan(int s) => db.scansDao.insertScanWithReads(
    scanRow(
      examId: examId,
      studentId: students[s],
      rollNoRead: 'R${(s + 1).toString().padLeft(3, '0')}',
    ),
    [
      for (var q = 1; q <= 90; q++)
        for (var o = 0; o < 4; o++)
          BubbleReadInput(
            fieldKey: 'q$q',
            optionIndex: o,
            markClass: (q + s) % 4 == o ? MarkClass.filled : MarkClass.empty,
          ),
      for (var r = 1; r <= 8; r++)
        for (var d = 0; d < 10; d++)
          BubbleReadInput(
            fieldKey: 'roll$r',
            optionIndex: d,
            markClass: MarkClass.empty,
          ),
    ],
  );

  Future<Map<String, (double, int, int?)>> snapshot() async => {
    for (final r in await db.resultsDao.resultsFor(examId, keyVersionId))
      r.student.rollNo: (r.result.total, r.result.correct, r.result.rank),
  };

  test('per-sheet incremental grading ends where one full pass does', () async {
    final perSheet = <int>[];
    for (var s = 0; s < classSize; s++) {
      final scanId = await scan(s);
      final watch = Stopwatch()..start();
      await GradingService(db).gradeExam(
        tenantId: kTenantId,
        examId: examId,
        keyVersionId: keyVersionId,
        onlyScans: {scanId},
      );
      perSheet.add(watch.elapsedMicroseconds);
    }
    final incremental = await snapshot();

    final full = Stopwatch()..start();
    await GradingService(db).gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
    );
    full.stop();
    final fullPass = await snapshot();

    double ms(int us) => us / 1000;
    // ignore: avoid_print
    print(
      'incremental grade per sheet: first ${ms(perSheet.first)} ms, '
      'last ${ms(perSheet.last)} ms; full pass over $classSize: '
      '${full.elapsedMilliseconds} ms',
    );

    expect(incremental, hasLength(classSize));
    expect(incremental, fullPass);
    // Every 4th student matches the key (+360), the rest score −90: 30
    // tied at rank 1, then 90 tied at rank 31.
    expect(fullPass.values.map((v) => v.$3).toSet(), {1, 31});
  });

  test('an incremental pass leaves other students\' rows untouched', () async {
    final first = await scan(0);
    final second = await scan(1);
    await GradingService(db).gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
      onlyScans: {first},
    );
    final before = await db.resultsDao.resultsFor(examId, keyVersionId);
    expect(before.map((r) => r.result.scanId), [first]);

    await GradingService(db).gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
      onlyScans: {second},
    );
    final after = await db.resultsDao.resultsFor(examId, keyVersionId);
    expect(after.map((r) => r.result.scanId).toSet(), {first, second});
    final firstRow = after.singleWhere((r) => r.result.scanId == first);
    expect(firstRow.result.scoringRunId, before.single.result.scoringRunId);
  });
}
