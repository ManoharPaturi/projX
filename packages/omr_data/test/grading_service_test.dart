import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// The re-grade engine (plan §5): grade → correct the key → re-grade, with the
/// bubble_reads substrate and human-correction overlays in the loop.
///
/// Fixture — Standard-90 layout, NEET/JEE-Main marking (+4 / −1 / 0,
/// multi-mark = wrong):
///
/// | student | q1 (key A)  | q2 (key B)  | q3 (key C) | expected v1   |
/// |---------|-------------|-------------|------------|---------------|
/// | R001    | fills A +4  | fills A −1  | —          | 3, rank 2     |
/// | R002    | fills A +4  | fills A+B   | —          | 3, rank 1     |
///         (multi-marked → wrong)                     (tie: ranks 1, 1)
void main() {
  late AppDb db;
  late String examId;
  late String keyVersionId;
  late List<String> studentIds;
  /// Fresh per access — a cached `late final` would pin the FIRST test's db
  /// and die with it in tearDown.
  GradingService grading() => GradingService(db);

  /// Full 90-question key: q1→A, q2→B, q3→C, q4..q90→A. The grader asserts
  /// every question in serial order has a key row — a partial key is a setup
  /// error and must throw, not silently grade.
  Map<String, List<int>> keyMap() => <String, List<int>>{
        'q1': [0],
        'q2': [1],
        'q3': [2],
        for (var i = 4; i <= 90; i++) 'q$i': [0],
      };

  Future<String> seedScan(
    String studentId,
    String roll, {
    List<BubbleReadInput> reads = const [],
  }) =>
      db.scansDao.insertScanWithReads(
        scanRow(examId: examId, studentId: studentId, rollNoRead: roll),
        reads,
      );

  setUp(() async {
    db = await openTestDb();
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
    keyVersionId = await seedKeyVersion(db, examId);
    await seedKeyEntries(db, keyVersionId, keyMap());
    studentIds = await seedStudents(db, instituteId, 2);
  });

  tearDown(() => db.close());

  test('gradeExam writes totals, counts and ranks from bubble reads', () async {
    await seedScan(studentIds[0], 'R001', reads: [
      const BubbleReadInput(
          fieldKey: 'q1', optionIndex: 0, markClass: MarkClass.filled),
      const BubbleReadInput(
          fieldKey: 'q2', optionIndex: 0, markClass: MarkClass.filled),
    ]);
    await seedScan(studentIds[1], 'R002', reads: [
      const BubbleReadInput(
          fieldKey: 'q1', optionIndex: 0, markClass: MarkClass.filled),
      // Multi-marked q2: two filled rows.
      const BubbleReadInput(
          fieldKey: 'q2', optionIndex: 0, markClass: MarkClass.filled),
      const BubbleReadInput(
          fieldKey: 'q2', optionIndex: 1, markClass: MarkClass.filled),
    ]);

    final report = await grading().gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
    );

    expect(report.resultsByStudent.length, 2);
    final byRoll = <String, double>{
      'R001': report.resultsByStudent[studentIds[0]]!.totalMarks,
      'R002': report.resultsByStudent[studentIds[1]]!.totalMarks,
    };
    expect(byRoll, {'R001': 3.0, 'R002': 3.0},
        reason: '+4 −1 for both: R002\'s multi-mark is wrong under the preset');

    final rows = await db.resultsDao.resultsFor(examId, keyVersionId);
    expect(rows.length, 2);
    expect(rows.every((r) => r.result.rank == 1), isTrue,
        reason: 'tied totals share rank 1');
    final r001 =
        rows.singleWhere((r) => r.student.rollNo == 'R001').result;
    expect(r001.correct, 1);
    expect(r001.wrong, 1);
    expect(r001.unattempted, 88);
    expect(r001.status, ResultStatus.ok);

    // The audit trail: a scoring run exists for this pass and is finished.
    final runs = await db.select(db.scoringRuns).get();
    expect(runs.single.finishedAt, isNotNull);
  });

  test('a needsReview scan is never graded', () async {
    final scanId = await db.scansDao.insertScanWithReads(
      scanRow(examId: examId, studentId: studentIds[0], rollNoRead: 'R001'),
      [
        const BubbleReadInput(
            fieldKey: 'q1', optionIndex: 0, markClass: MarkClass.filled),
      ],
    );
    await db.reviewDao.enqueue(
      tenantId: kTenantId,
      scanId: scanId,
      reasonCode: 'multi_mark_roll',
      severity: ReviewSeverity.mandatory,
    );

    final report = await grading().gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
    );

    expect(report.resultsByStudent, isEmpty,
        reason: 'marks must not publish while a human has not cleared the read');
    expect(await db.resultsDao.resultsFor(examId, keyVersionId), isEmpty);
  });

  test('corrected key re-grades with NO rescan; both versions coexist', () async {
    await seedScan(studentIds[0], 'R001', reads: [
      const BubbleReadInput(
          fieldKey: 'q2', optionIndex: 0, markClass: MarkClass.filled),
    ]);
    await grading().gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
    );

    // Key q2 was wrong: it is B, the student bubbled A. Insert v2 with A.
    final v2 = await seedKeyVersion(db, examId, version: 2,
        supersedesId: keyVersionId);
    await seedKeyEntries(db, v2, {
      ...keyMap(),
      'q2': [0],
    });

    final report2 = await grading().gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: v2,
      regrade: true,
    );

    expect(report2.resultsByStudent[studentIds[0]]!.totalMarks, 4.0);
    expect(report2.resultsByStudent[studentIds[0]]!.status.name, 'regraded');

    // v1 still grades −1 exactly as published; v2 sits beside it.
    expect(
      (await db.resultsDao.resultsFor(examId, keyVersionId))
          .single
          .result
          .total,
      -1.0,
    );
    expect((await db.resultsDao.resultsFor(examId, v2)).single.result.total, 4.0);
  });

  test('a human correction overlay changes the next re-grade of the SAME version',
      () async {
    final scanId = await seedScan(studentIds[0], 'R001', reads: [
      const BubbleReadInput(
          fieldKey: 'q2', optionIndex: 0, markClass: MarkClass.filled),
    ]);
    await grading().gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
    );
    expect(
      (await db.resultsDao.resultsFor(examId, keyVersionId))
          .single
          .result
          .total,
      -1.0,
    );

    // Review decides q2 was actually blank: route, then clear the read in
    // place through the queue's correction payload.
    final reviewId = await db.reviewDao.enqueue(
      tenantId: kTenantId,
      scanId: scanId,
      reasonCode: 'probable_bubble',
      severity: ReviewSeverity.high,
      fieldRefs: const ['q2:0'],
    );
    await db.reviewDao.resolve(
      reviewId,
      outcome: ReviewOutcome.corrected,
      corrections: const [
        BubbleCorrection(
            fieldKey: 'q2', optionIndex: 0, markClass: MarkClass.empty),
      ],
    );

    await grading().gradeExam(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
    );

    // Same natural key replaced in place: unattempted now, 0 marks. With q2
    // blank every one of the 90 questions is unattempted.
    final rows = await db.resultsDao.resultsFor(examId, keyVersionId);
    expect(rows.single.result.total, 0.0);
    expect(rows.single.result.unattempted, 90);
  });
}
