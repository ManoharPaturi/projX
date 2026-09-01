import 'package:drift/drift.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_spec/omr_spec.dart';

/// The single MVP tenant (plan §4: exactly one row).
const String kTenantId = 'tenant-mvp';

/// Opens an in-memory db and forces it open (beforeOpen pragmas included).
Future<AppDb> openTestDb() async {
  final db = AppDb.memory();
  await db.customSelect('SELECT 1').getSingle();
  return db;
}

Future<void> seedTenant(AppDb db) => db
    .into(db.tenants)
    .insert(
      TenantsCompanion.insert(
        id: kTenantId,
        name: 'MVP Institute Group',
        plan: 'mvp',
      ),
    );

Future<String> seedInstitute(AppDb db) async {
  final row = await db
      .into(db.institutes)
      .insertReturning(
        InstitutesCompanion.insert(
          tenantId: kTenantId,
          name: 'Test Institute',
          code: 'TI',
        ),
      );
  return row.id;
}

/// R001..R00N, returned in roll order.
Future<List<String>> seedStudents(
  AppDb db,
  String instituteId,
  int count, {
  String rollPrefix = 'R',
}) async {
  final ids = <String>[];
  for (var i = 1; i <= count; i++) {
    ids.add(
      (await db
              .into(db.students)
              .insertReturning(
                StudentsCompanion.insert(
                  tenantId: kTenantId,
                  instituteId: instituteId,
                  rollNo: '$rollPrefix${i.toString().padLeft(3, '0')}',
                ),
              ))
          .id,
    );
  }
  return ids;
}

/// Layout = the already-validated Standard-90 preset from omr_spec.
Future<String> seedLayout(AppDb db) =>
    db.layoutsDao.upsertSpec(tenantId: kTenantId, spec: buildStandard90());

Future<String> seedExam(
  AppDb db,
  String instituteId, {
  required String sheetLayoutId,
  String name = 'JEE Mock 1',
}) => db.examsDao.createExam(
  tenantId: kTenantId,
  instituteId: instituteId,
  name: name,
  sheetLayoutId: sheetLayoutId,
  totalQuestions: 90,
);

Future<String> seedKeyVersion(
  AppDb db,
  String examId, {
  int version = 1,
  String? supersedesId,
}) => db.keysDao.createVersion(
  tenantId: kTenantId,
  examId: examId,
  version: version,
  createdBy: 'tester',
  supersedesId: supersedesId,
);

Future<void> seedKeyEntries(
  AppDb db,
  String keyVersionId,
  Map<String, List<int>> keysByQuestion, {
  String setCode = 'A',
}) => db.keysDao.addEntries(
  keyVersionId,
  tenantId: kTenantId,
  entries: [
    for (final entry in keysByQuestion.entries)
      KeyEntryInput(
        setCode: setCode,
        questionId: entry.key,
        correctOptions: entry.value,
      ),
  ],
);

Future<String> seedScoringRun(AppDb db, String examId, String keyVersionId) =>
    db.resultsDao.startScoringRun(
      tenantId: kTenantId,
      examId: examId,
      keyVersionId: keyVersionId,
      scoringRuleSnapshot: const <String, Object?>{
        'preset': 'NEET_JEE_MAIN',
        'correct': 4,
        'wrong': -1,
        'unattempted': 0,
      },
      sheetLayoutVersion: 1,
    );

ScansCompanion scanRow({
  required String examId,
  String? id,
  String? studentId,
  String? rollNoRead,
  String? setCodeRead,
  ScanStatus status = ScanStatus.graded,
  double? sheetConfidence,
  DateTime? capturedAt,
}) => ScansCompanion.insert(
  id: id == null ? const Value.absent() : Value(id),
  tenantId: kTenantId,
  examId: examId,
  studentId: Value(studentId),
  rollNoRead: Value(rollNoRead),
  setCodeRead: Value(setCodeRead),
  layoutVersion: 1,
  capturedAt: capturedAt == null ? const Value.absent() : Value(capturedAt),
  warpedImagePath: '/tmp/warped.png',
  thumbPath: '/tmp/thumb.png',
  annotatedPath: '/tmp/annotated.png',
  sheetConfidence: Value(sheetConfidence),
  status: Value(status),
);

ResultsCompanion resultRow({
  required String examId,
  required String studentId,
  required String keyVersionId,
  required String scoringRunId,
  required String scanId,
  required double total,
  Map<String, Object?>? subjectTotals,
  int correct = 0,
  int wrong = 0,
  int unattempted = 0,
}) => ResultsCompanion.insert(
  tenantId: kTenantId,
  scanId: scanId,
  examId: examId,
  studentId: studentId,
  keyVersionId: keyVersionId,
  scoringRunId: scoringRunId,
  total: total,
  correct: Value(correct),
  wrong: Value(wrong),
  unattempted: Value(unattempted),
  subjectTotalsJson: Value(
    subjectTotals == null ? '{}' : encodeJsonObject(subjectTotals),
  ),
);

/// The analytics cohort (analytics_dao_test holds the hand-computed
/// expectations): 4 students with totals 12 / 10 / 6 / 4 — NTILE(2) top half
/// is students 1 and 2 — against keys q1→[0], q2→[1], q3→[2], q4→[1] on
/// set 'A'.
class AnalyticsCohort {
  AnalyticsCohort({
    required this.examId,
    required this.keyVersionId,
    required this.scoringRunId,
    required this.studentIds,
    required this.scanIds,
  });

  final String examId;
  final String keyVersionId;
  final String scoringRunId;
  final List<String> studentIds;
  final List<String> scanIds;
}

const List<Map<String, int?>> kFilledOptions = [
  {'q1': 0, 'q2': 1, 'q3': 3, 'q4': 1},
  {'q1': 0, 'q2': 2, 'q3': 0, 'q4': 1},
  {'q1': 0, 'q2': 1, 'q3': 2, 'q4': null},
  {'q1': 1, 'q2': 3, 'q3': 2, 'q4': null},
];

Future<AnalyticsCohort> seedAnalyticsCohort(AppDb db) async {
  final instituteId = await seedInstitute(db);
  final layoutId = await seedLayout(db);
  final examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
  final keyVersionId = await seedKeyVersion(db, examId);
  await seedKeyEntries(db, keyVersionId, {
    'q1': [0],
    'q2': [1],
    'q3': [2],
    'q4': [1],
  });
  final studentIds = await seedStudents(db, instituteId, 4);
  const totals = [12.0, 10.0, 6.0, 4.0];
  const subjectTotals = <Map<String, Object?>>[
    {'Physics': 8.0, 'Chemistry': 4.0},
    {'Physics': 6.0, 'Chemistry': 4.0},
    {'Physics': 4.0, 'Chemistry': 2.0},
    {'Physics': 2.0, 'Chemistry': 2.0},
  ];
  final scoringRunId = await seedScoringRun(db, examId, keyVersionId);
  final scanIds = <String>[];
  final results = <ResultsCompanion>[];
  for (var i = 0; i < 4; i++) {
    final scanId = await db.scansDao.insertScanWithReads(
      scanRow(
        examId: examId,
        studentId: studentIds[i],
        rollNoRead: 'R00${i + 1}',
        setCodeRead: 'A',
      ),
      [
        for (final q in const ['q1', 'q2', 'q3', 'q4'])
          BubbleReadInput(
            fieldKey: q,
            optionIndex: kFilledOptions[i][q] ?? 1,
            markClass: kFilledOptions[i][q] == null
                ? MarkClass.empty
                : MarkClass.filled,
          ),
      ],
    );
    scanIds.add(scanId);
    results.add(
      resultRow(
        examId: examId,
        studentId: studentIds[i],
        keyVersionId: keyVersionId,
        scoringRunId: scoringRunId,
        scanId: scanId,
        total: totals[i],
        subjectTotals: subjectTotals[i],
      ),
    );
  }
  await db.resultsDao.upsertResults(kTenantId, results);
  await db.resultsDao.recomputeRanks(examId, keyVersionId);
  return AnalyticsCohort(
    examId: examId,
    keyVersionId: keyVersionId,
    scoringRunId: scoringRunId,
    studentIds: studentIds,
    scanIds: scanIds,
  );
}
