import 'dart:convert';
import 'dart:io';

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

  testWidgets('dashboard → exam → ranked results (flagged sheet excluded)',
      (tester) async {
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

    // Dashboard lists the exam.
    expect(find.text('JEE Mock 1'), findsOneWidget);
    await tester.tap(find.text('JEE Mock 1'));
    await tester.pumpAndSettle();

    // Results tab shows exactly the two review-cleared students, ranked.
    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();
    // Student 0's fixture attempts 54 of 90 (all correct at +4) = 216.
    expect(find.text('2 students · top 216 · key v1'), findsOneWidget);

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
    expect(find.text('R003'), findsNothing, reason: 'needs-review sheets do '
        'not publish marks');
  });

  testWidgets('review correction rewrites the read and re-grades',
      (tester) async {
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

    await tester.pumpWidget(
      wrapForTest(const ReviewQueueScreen(), state),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('MULTI_BUBBLE_WARN'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // The flagged field's four bubbles; the operator marks option A.
    expect(find.text('machine'), findsAtLeastNWidgets(2));
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

  testWidgets('roster import: header skipped, duplicates reported',
      (tester) async {
    await tester.pumpWidget(wrapForTest(const RosterScreen(), state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import CSV'));
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
    expect(find.text('Aarav · Batch-A'), findsOneWidget);
    expect(find.text('Imposter'), findsNothing);

    // A second import of R001 must not rewrite the enrolled name.
    await tester.tap(find.text('Import CSV'));
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
    expect(find.text('Consolidated class PDF'), findsOneWidget);

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
    expect(artifact.readAsBytesSync().sublist(0, 3), const [0xEF, 0xBB, 0xBF],
        reason: 'UTF-8 BOM so Indian-language names survive Excel');
    expect(
      artifact.readAsLinesSync().first.split(',').first,
      'Roll No',
    );

    final jobs = await state.db.reportJobsDao.recentFor(seeded.examId);
    expect(jobs.single.status, ReportJobStatus.done);
    expect(jobs.single.filePath, path);
    directory.deleteSync(recursive: true);
  });
}
