import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/exams/exam_detail_screen.dart';
import 'package:omr_app/features/review/review_queue_screen.dart';
import 'package:omr_app/features/students/roster_screen.dart';
import 'package:omr_app/main.dart';
import 'package:omr_app/src/app_state.dart';
import 'package:omr_app/src/demo_scans.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';

import 'helpers.dart';

/// The on-device flow the app exists for (plan §9): exam → key → roster →
/// scans → results → reports, and the review correction that turns a bad
/// read into a right one — all over the in-memory AppDb, no device needed.
void main() {
  late AppState state;

  setUp(() async {
    state = await seededAppState();
  });

  tearDown(() => state.db.close());

  testWidgets('dashboard → exam → ranked results (flagged sheet excluded)', (
    tester,
  ) async {
    final seeded = await seedExamWithRoster(state);
    final roster = await state.db.studentsDao.rosterFor(state.instituteId);

    // Two clean sheets + one multi-marked sheet routed to review.
    for (var i = 0; i < 3; i++) {
      await insertDemoScan(
        db: state.db,
        examId: seeded.examId,
        studentId: roster[i].id,
        rollNo: roster[i].rollNo,
        studentIndex: i,
        flaggedForReview: i == 2,
      );
    }
    await state.grade(seeded.examId, seeded.keyVersionId);

    await tester.pumpWidget(OmrApp(state: state));
    await tester.pumpAndSettle();

    // Dashboard lists the exam (below the getting-started checklist).
    await tester.scrollUntilVisible(find.text('JEE Mock 1'), 200);
    expect(find.text('JEE Mock 1'), findsOneWidget);
    await tester.tap(find.text('JEE Mock 1'));
    await tester.pumpAndSettle();

    // Results tab shows exactly the two review-cleared students, ranked.
    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();
    // Student 0's fixture attempts 54 of 90 (all correct at +4) = 216.
    expect(
      find.text('2 students · highest 216 marks · answer key 1'),
      findsOneWidget,
    );

    final r1Tile = find.ancestor(
      of: find.text('R001'),
      matching: find.byType(ListTile),
    );
    final r2Tile = find.ancestor(
      of: find.text('R002'),
      matching: find.byType(ListTile),
    );
    expect(r1Tile, findsOneWidget);
    expect(r2Tile, findsOneWidget);
    expect(
      find.text('R003'),
      findsNothing,
      reason:
          'needs-review sheets do '
          'not publish marks',
    );
  });

  testWidgets('review correction rewrites the read and re-grades', (
    tester,
  ) async {
    final seeded = await seedExamWithRoster(state, students: 1);
    final roster = await state.db.studentsDao.rosterFor(state.instituteId);
    final scanId = await insertDemoScan(
      db: state.db,
      examId: seeded.examId,
      studentId: roster.first.id,
      rollNo: roster.first.rollNo,
      studentIndex: 0,
      flaggedForReview: true,
    );

    await tester.pumpWidget(wrapForTest(const ReviewQueueScreen(), state));
    await tester.pumpAndSettle();
    // The queue speaks operator language; MULTI_BUBBLE_WARN is the stored
    // reason code, the tile says what it means.
    expect(find.textContaining('A question has two marks'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // The flagged field's four bubbles; the operator marks option A.
    expect(find.text('read as marked'), findsAtLeastNWidgets(2));
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save correction (1)'));
    await tester.pumpAndSettle();

    // Queue drained; the read is now a human-corrected single mark.
    expect(find.text('Nothing waiting for review'), findsOneWidget);
    final detail = await state.db.scansDao.fetchWithReads(scanId);
    final flagged = detail!.reads.where((r) => r.fieldKey == 'q5').toList()
      ..sort((a, b) => a.optionIndex.compareTo(b.optionIndex));
    expect(flagged.length, 4);
    expect(
      flagged.where((r) => r.markClass == MarkClass.filled).single.optionIndex,
      0,
    );
    expect(flagged.every((r) => r.isHumanCorrection), isTrue);

    // The corrected scan graded: exactly one published result now exists.
    final query = ResultsQuery(
      state.db,
      examId: seeded.examId,
      keyVersionId: seeded.keyVersionId,
    );
    final rows = await query.rows();
    expect(rows, hasLength(1));
    expect(rows.single.rollNo, 'R001');
  });

  testWidgets('unmatched roll: operator assigns the student, sheet grades', (
    tester,
  ) async {
    final seeded = await seedExamWithRoster(state, students: 1);
    await state.db.studentsDao.importRoster(
      state.tenantId,
      state.instituteId,
      const [RosterEntry(rollNo: '1234', name: 'Asha')],
    );
    final layoutVersion = (await GradingService(
      state.db,
    ).templateFor(seeded.examId)).layoutVersion;
    final scanId = await state.db.scansDao.insertScanWithReads(
      ScansCompanion.insert(
        tenantId: state.tenantId,
        examId: seeded.examId,
        rollNoRead: const Value('9999'),
        layoutVersion: layoutVersion,
        warpedImagePath: 'capture://pending',
        thumbPath: 'capture://pending',
        annotatedPath: 'capture://pending',
        status: const Value(ScanStatus.needsReview),
      ),
      const [],
    );
    await state.db.reviewDao.enqueue(
      tenantId: state.tenantId,
      scanId: scanId,
      reasonCode: 'ROLL_NOT_ON_ROSTER',
      severity: ReviewSeverity.mandatory,
      fieldRefs: const [],
    );

    await tester.pumpWidget(wrapForTest(const ReviewQueueScreen(), state));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.text('Whose sheet is this?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('assign-roll-field')),
      '0001234',
    );
    await tester.tap(find.text('Find'));
    await tester.pumpAndSettle();
    expect(find.text('Roll 1234 · Asha'), findsOneWidget);

    await tester.tap(find.text('Save and grade this sheet'));
    await tester.pumpAndSettle();

    final scan = (await state.db.scansDao.fetchWithReads(scanId))!.scan;
    final asha = await state.db.studentsDao.findByRoll(
      state.instituteId,
      '1234',
    );
    expect(scan.studentId, asha!.id);
    expect(scan.status, ScanStatus.reviewed);
    final rows = await ResultsQuery(
      state.db,
      examId: seeded.examId,
      keyVersionId: seeded.keyVersionId,
    ).rows();
    expect(rows.map((r) => r.rollNo), contains('1234'));
  });

  testWidgets('roster import: header skipped, duplicates reported', (
    tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const RosterScreen(), state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste a list'));
    await tester.pumpAndSettle();

    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(
      field,
      'roll,name,batch\n'
      'R001,Aarav,Batch-A\n'
      'R001,Imposter,\n'
      'R002,Dev,\n',
    );
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    // First copy wins in-file; the imoster never lands.
    expect(find.text('Import finished'), findsOneWidget);
    expect(find.textContaining('Imported: 2'), findsOneWidget);
    expect(find.textContaining('Repeated in file'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('R001'), findsOneWidget);
    expect(find.textContaining('Aarav · Batch-A'), findsOneWidget);
    expect(find.text('Imposter'), findsNothing);

    // A second import of R001 must not rewrite the enrolled name.
    await tester.tap(find.text('Paste a list'));
    await tester.pumpAndSettle();
    await tester.enterText(field, 'R001,SomeoneElse');
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Already on roster'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('SomeoneElse'), findsNothing);
  });

  testWidgets('reports tab generates a traceable CSV artifact', (tester) async {
    final seeded = await seedExamWithRoster(state, students: 2);
    final roster = await state.db.studentsDao.rosterFor(state.instituteId);
    for (var i = 0; i < 2; i++) {
      await insertDemoScan(
        db: state.db,
        examId: seeded.examId,
        studentId: roster[i].id,
        rollNo: roster[i].rollNo,
        studentIndex: i,
      );
    }
    await state.grade(seeded.examId, seeded.keyVersionId);

    await tester.pumpWidget(
      wrapForTest(ExamDetailScreen(examId: seeded.examId), state),
    );
    await tester.pumpAndSettle();

    // The Reports tab itself needs the share sheet (a platform channel), so
    // the UI stops at rendering; generation goes through the same runner the
    // tab calls.
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Class result list (PDF)'), findsOneWidget);

    final directory = Directory.systemTemp.createTempSync('omr-reports');
    final runner = ReportRunner(state.db);
    final query = ResultsQuery(
      state.db,
      examId: seeded.examId,
      keyVersionId: seeded.keyVersionId,
    );

    // Real file IO must run in a plain zone: testWidgets bodies run under
    // fakeAsync, where dart:io write events never dispatch and the await
    // below would never resume.
    final header = await query.header();
    final rows = await query.rows();
    final path = await tester.runAsync(
      () => runner.run(
        tenantId: state.tenantId,
        examId: seeded.examId,
        type: ReportJobType.csv,
        format: 'csv',
        directory: directory.path,
        fileName: 'csv-v1.csv',
        params: <String, Object?>{'keyVersionId': seeded.keyVersionId},
        build: () async => utf8.encode(CsvExporter().convert(header, rows)),
      ),
    );

    expect(path, isNotNull, reason: 'runAsync returned before completion');
    final artifact = File(path!);
    expect(artifact.existsSync(), isTrue);
    expect(artifact.readAsBytesSync().sublist(0, 3), const [
      0xEF,
      0xBB,
      0xBF,
    ], reason: 'UTF-8 BOM so Indian-language names survive Excel');
    expect(artifact.readAsLinesSync().first.split(',').first, 'Roll No');

    final jobs = await state.db.reportJobsDao.recentFor(seeded.examId);
    expect(jobs.single.status, ReportJobStatus.done);
    expect(jobs.single.filePath, path);
    directory.deleteSync(recursive: true);
  });

  testWidgets('add student: check digit shown, then listed on the roster', (
    tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const RosterScreen(), state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add-roll-field')), '1234');
    await tester.pump();
    expect(find.text('Check digit for the sheet: 2'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('add-name-field')), 'Asha');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('1234'), findsOneWidget);
    expect(find.textContaining('Asha · Check digit 2'), findsOneWidget);
  });

  testWidgets('add student refuses a roll that cannot be bubbled', (
    tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const RosterScreen(), state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('add-roll-field')), 'AB12');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Use digits only, up to 7'), findsOneWidget);
    expect(await state.db.studentsDao.count(state.instituteId), 0);
  });

  testWidgets('answer key: switching set tabs shows that set', (tester) async {
    final seeded = await seedExamWithRoster(state, students: 1);
    await tester.pumpWidget(
      wrapForTest(
        ExamDetailScreen(
          examId: seeded.examId,
          initialTab: ExamDetailScreen.answerKeyTab,
        ),
        state,
      ),
    );
    await tester.pumpAndSettle();

    // Set A is fully keyed by the seed; set B is empty.
    expect(find.text('Set A ✓'), findsOneWidget);
    expect(find.text('90 of 90 answered in set A'), findsOneWidget);
    await tester.tap(find.text('Set B'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 90 answered in set B'), findsOneWidget);
  });

  testWidgets('type answers fills the set in question order', (tester) async {
    final seeded = await seedExamWithRoster(state, students: 1);
    await tester.pumpWidget(
      wrapForTest(
        ExamDetailScreen(
          examId: seeded.examId,
          initialTab: ExamDetailScreen.answerKeyTab,
        ),
        state,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set B'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Type answers'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('type-answers-field')),
      'abcd, dcba 1x',
    );
    await tester.pump();
    // 'x' is a letter but not an option on a 4-option sheet: counted as
    // typed, skipped when filling.
    expect(find.text('9 of 90 answers typed'), findsOneWidget);
    await tester.tap(find.text('Fill answers'));
    await tester.pumpAndSettle();

    expect(find.text('8 of 90 answered in set B'), findsOneWidget);
    expect(find.text('Set B (8/90)'), findsOneWidget);
    expect(find.textContaining('Finish or clear set B'), findsOneWidget);
  });

  testWidgets('calculate marks with nothing scanned says so, stays unmarked', (
    tester,
  ) async {
    final seeded = await seedExamWithRoster(state, students: 1);
    await tester.pumpWidget(
      wrapForTest(ExamDetailScreen(examId: seeded.examId), state),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calculate marks'));
    await tester.pumpAndSettle();

    expect(
      find.text('No scanned sheets yet — scan them first.'),
      findsOneWidget,
    );
    final exam = await state.db.examsDao.byId(seeded.examId);
    expect(exam!.status, isNot(ExamStatus.graded));
  });

  testWidgets('pasting rolls that cannot be bubbled warns in the summary', (
    tester,
  ) async {
    await tester.pumpWidget(wrapForTest(const RosterScreen(), state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste a list'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'roll,name\n1001,Asha\nAB12,Ravi',
    );
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.text('Import finished'), findsOneWidget);
    expect(find.textContaining('cannot be filled in'), findsOneWidget);
    expect(find.textContaining('digits only, up to 7): AB12'), findsOneWidget);
  });
}
