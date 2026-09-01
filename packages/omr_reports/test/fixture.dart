import 'package:drift/drift.dart' hide isNull;
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:omr_spec/omr_spec.dart' as spec;

const String kTenantId = 'tenant-mvp';

Future<AppDb> openTestDb() async {
  final db = AppDb.memory();
  await db.customSelect('SELECT 1').getSingle();
  return db;
}

/// One graded exam against the Standard-90 layout, NEET/JEE-Main marking:
///
/// | roll | name         | marks                         | total | rank |
/// |------|--------------|-------------------------------|-------|------|
/// | R001 | आरव शर्मा    | q1 A +4, q2 A −1              | 3     | 2    |
/// | R002 | (none)       | q1 A +4, q2 B +4, q3 C +4     | 12    | 1    |
/// | R003 | (none)       | q1 B −1                       | −1    | 3    |
///
/// Key: q1→A, q2→B, q3→C, q4..q90→A. Subjects: Physics q1..q30, Chemistry
/// q31..q60, Mathematics q61..q90.
class GradedFixture {
  GradedFixture({
    required this.db,
    required this.examId,
    required this.keyVersionId,
    required this.rolls,
    required this.scanIdByRoll,
  });

  final AppDb db;
  final String examId;
  final String keyVersionId;
  final List<String> rolls;
  final Map<String, String> scanIdByRoll;

  ResultsQuery query() =>
      ResultsQuery(db, examId: examId, keyVersionId: keyVersionId);
}

Future<GradedFixture> seedGradedExam(AppDb db) async {
  final instituteRow = await db
      .into(db.institutes)
      .insertReturning(
        InstitutesCompanion.insert(
          tenantId: kTenantId,
          name: 'Test Institute',
          code: 'TI',
        ),
      );
  final layoutId = await db.layoutsDao.upsertSpec(
    tenantId: kTenantId,
    spec: spec.buildStandard90(),
  );
  final examId = await db.examsDao.createExam(
    tenantId: kTenantId,
    instituteId: instituteRow.id,
    name: 'JEE Mock 1',
    sheetLayoutId: layoutId,
    totalQuestions: 90,
  );
  final keyVersionId = await db.keysDao.createVersion(
    tenantId: kTenantId,
    examId: examId,
    version: 1,
    createdBy: 'tester',
  );
  await db.keysDao.addEntries(
    keyVersionId,
    tenantId: kTenantId,
    entries: [
      for (var i = 1; i <= 90; i++)
        KeyEntryInput(
          setCode: 'A',
          questionId: 'q$i',
          // q1→A, q2→B, q3→C, everything else→A.
          correctOptions: [
            switch (i) {
              1 => 0,
              2 => 1,
              3 => 2,
              _ => 0,
            },
          ],
        ),
    ],
  );

  Future<String> seedStudent(String roll, String? name) => db
      .into(db.students)
      .insertReturning(
        StudentsCompanion.insert(
          tenantId: kTenantId,
          instituteId: instituteRow.id,
          rollNo: roll,
          name: name == null ? const Value.absent() : Value(name),
        ),
      )
      .then((r) => r.id);

  final r001 = await seedStudent('R001', 'आरव शर्मा');
  final r002 = await seedStudent('R002', null);
  final r003 = await seedStudent('R003', null);

  Future<String> seedScan(
    String studentId,
    String roll,
    List<BubbleReadInput> reads,
  ) {
    return db.scansDao.insertScanWithReads(
      ScansCompanion.insert(
        tenantId: kTenantId,
        examId: examId,
        studentId: Value(studentId),
        rollNoRead: Value(roll),
        setCodeRead: const Value('A'),
        layoutVersion: 1,
        warpedImagePath: '/tmp/warped.png',
        thumbPath: '/tmp/thumb.png',
        annotatedPath: '/tmp/annotated.png',
        status: const Value(ScanStatus.graded),
      ),
      reads,
    );
  }

  final scanIdByRoll = <String, String>{
    'R001': await seedScan(r001, 'R001', const [
      BubbleReadInput(
        fieldKey: 'q1',
        optionIndex: 0,
        markClass: MarkClass.filled,
      ),
      BubbleReadInput(
        fieldKey: 'q2',
        optionIndex: 0,
        markClass: MarkClass.filled,
      ),
    ]),
    'R002': await seedScan(r002, 'R002', const [
      BubbleReadInput(
        fieldKey: 'q1',
        optionIndex: 0,
        markClass: MarkClass.filled,
      ),
      BubbleReadInput(
        fieldKey: 'q2',
        optionIndex: 1,
        markClass: MarkClass.filled,
      ),
      BubbleReadInput(
        fieldKey: 'q3',
        optionIndex: 2,
        markClass: MarkClass.filled,
      ),
    ]),
    'R003': await seedScan(r003, 'R003', const [
      BubbleReadInput(
        fieldKey: 'q1',
        optionIndex: 1,
        markClass: MarkClass.filled,
      ),
    ]),
  };

  await GradingService(
    db,
  ).gradeExam(tenantId: kTenantId, examId: examId, keyVersionId: keyVersionId);

  return GradedFixture(
    db: db,
    examId: examId,
    keyVersionId: keyVersionId,
    rolls: const ['R001', 'R002', 'R003'],
    scanIdByRoll: scanIdByRoll,
  );
}

/// Adds [count] more students+scans to the fixture exam and re-grades, so
/// pagination tests run against a realistic cohort in ONE scoring run.
/// Student B000i fills q1..qi all-correct → a real rank spread.
Future<void> seedExtraCohort(AppDb db, GradedFixture fx, int count) async {
  final instituteId = (await db.select(db.students).get()).first.instituteId;
  for (var i = 0; i < count; i++) {
    final roll = 'B${i.toString().padLeft(3, '0')}';
    final studentId = await db
        .into(db.students)
        .insertReturning(
          StudentsCompanion.insert(
            tenantId: kTenantId,
            instituteId: instituteId,
            rollNo: roll,
          ),
        )
        .then((r) => r.id);
    await db.scansDao.insertScanWithReads(
      ScansCompanion.insert(
        tenantId: kTenantId,
        examId: fx.examId,
        studentId: Value(studentId),
        rollNoRead: Value(roll),
        setCodeRead: const Value('A'),
        layoutVersion: 1,
        warpedImagePath: '/tmp/warped.png',
        thumbPath: '/tmp/thumb.png',
        annotatedPath: '/tmp/annotated.png',
        status: const Value(ScanStatus.graded),
      ),
      [
        for (var q = 1; q <= i; q++)
          BubbleReadInput(
            fieldKey: 'q$q',
            // Mirrors the key: q1→A, q2→B, q3→C, q4..→A — all correct.
            optionIndex: switch (q) {
              1 => 0,
              2 => 1,
              3 => 2,
              _ => 0,
            },
            markClass: MarkClass.filled,
          ),
      ],
    );
  }
  await GradingService(db).gradeExam(
    tenantId: kTenantId,
    examId: fx.examId,
    keyVersionId: fx.keyVersionId,
  );
}
