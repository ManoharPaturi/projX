import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:test/test.dart';

import 'fixture.dart';

/// M3 renderer contracts (plan §7): one canonical ResultsQuery feeding the
/// marksheet PDF, consolidated PDF, XLSX and CSV — plus the job runner that
/// makes every generation traceable.
void main() {
  late AppDb db;
  late GradedFixture fx;

  setUp(() async {
    db = await openTestDb();
    fx = await seedGradedExam(db);
  });

  tearDown(() => db.close());

  test(
    'ResultsQuery rows carry rank-order, subjects and scan linkage',
    () async {
      final header = await fx.query().header();
      final rows = await fx.query().rows();

      expect(header.subjects, ['Physics', 'Chemistry', 'Mathematics']);
      expect(header.studentCount, 3);
      expect(header.maxTotal, 12.0);
      expect(header.examName, 'JEE Mock 1');
      expect(header.instituteName, 'Test Institute');

      expect(rows.map((r) => r.rollNo), [
        'R002',
        'R001',
        'R003',
      ], reason: 'rank order: 12, 3, -1');
      final r001 = rows.singleWhere((r) => r.rollNo == 'R001');
      final r002 = rows.first;
      final r003 = rows.last;
      expect(r002.rank, 1);
      expect(r002.total, 12.0);
      expect(r002.subjectTotals['Physics'], 12.0);
      expect(r001.rank, 2);
      expect(r001.name, 'आरव शर्मा');
      expect(r001.total, 3.0);
      expect(r003.rank, 3);
      expect(r003.total, -1.0);
      // Every row points at the scan that produced it — the lazy detail key.
      expect(r001.scanId, fx.scanIdByRoll['R001']);
    },
  );

  test(
    'outcomesFor rebuilds per-question detail without touching pixels',
    () async {
      final rows = await fx.query().rows();
      final r001 = rows.singleWhere((r) => r.rollNo == 'R001');

      final outcomes = await fx.query().outcomesFor(r001);

      expect(outcomes.length, 90);
      final q1 = outcomes.singleWhere((o) => o.questionId == 'q1');
      final q2 = outcomes.singleWhere((o) => o.questionId == 'q2');
      final q4 = outcomes.singleWhere((o) => o.questionId == 'q4');
      expect(q1.kind, core.QuestionOutcomeKind.correct);
      expect(q1.marksAwarded, 4.0);
      expect(q2.kind, core.QuestionOutcomeKind.wrong);
      expect(q2.marksAwarded, -1.0);
      expect(q4.kind, core.QuestionOutcomeKind.unattempted);
    },
  );

  test('CSV round-trips with BOM and Devanagari intact', () async {
    final query = fx.query();
    final csvText = CsvExporter().convert(
      await query.header(),
      await query.rows(),
    );

    // BOM first — without it Excel mojibakes the name (M3 criterion).
    expect(csvText.startsWith('﻿'), isTrue);
    final decoded = Csv().decode(csvText.substring(1));
    expect(decoded.length, 4); // header + 3 students
    expect(decoded[0], [
      'Roll No',
      'Name',
      'Rank',
      'Total',
      'Correct',
      'Wrong',
      'Unattempted',
      'Attempted',
      'Physics',
      'Chemistry',
      'Mathematics',
      'Status',
    ]);
    final r001 = decoded.singleWhere((r) => r.first == 'R001');
    expect(
      r001[1],
      'आरव शर्मा',
      reason: 'UTF-8 must survive encode→decode byte-for-byte',
    );
    expect(r001[3], '3');
    expect(r001[10], '0');
  });

  test(
    'CSV streams row-per-event with the same content as the batch encode',
    () async {
      final header = await fx.query().header();
      final rows = await fx.query().rows();
      final streamed = await CsvExporter()
          .stream(header, Stream.fromIterable(rows))
          .join();
      // Batch omits the final line delimiter; a streaming writer terminates
      // every row — both are correct CSV, differ only in that trailing CRLF.
      expect(streamed, '${CsvExporter().convert(header, rows)}\r\n');
      expect(
        '﻿'.allMatches(streamed).length,
        1,
        reason: 'exactly one BOM, not one per streamed row',
      );
    },
  );

  test('XLSX has a Summary sheet with live percentile formulas and a '
      'Per Question matrix', () async {
    final query = fx.query();
    final rows = await query.rows();
    final outcomesByRoll = <String, List<core.QuestionOutcome>>{
      for (final row in rows) row.rollNo: await query.outcomesFor(row),
    };
    final bytes = await ExcelExporter().build(
      query,
      outcomesByRoll: outcomesByRoll,
    );

    final excel = Excel.decodeBytes(bytes);
    expect(excel.sheets.keys, containsAll(['Summary', 'Per Question']));

    final summary = excel['Summary'];
    final grid = summary.selectRangeValuesWithString('A1:L4');
    final headerRow = grid[0]!;
    expect(_text(headerRow[0]), 'Roll No');
    expect(headerRow.map(_text), contains('Percentile'));

    // Rank order preserved: R002 (12) first, its percentile = strictly-below
    // share = 2/3 → 66.67.
    final first = grid[1]!;
    expect(_text(first[0]), 'R002');
    expect(_int(first[3]), 12);
    final percentile =
        first[headerRow.indexWhere((c) => _text(c) == 'Percentile')]!;
    expect(percentile, isA<FormulaCellValue>());
    expect(
      (percentile as FormulaCellValue).formula,
      'ROUND(COUNTIF(\$D\$2:\$D\$4,">"&D2)/COUNT(\$D\$2:\$D\$4)*100,2)',
    );

    final perQuestion = excel['Per Question'];
    // roll + 90 questions = 91 columns → A..CM.
    final pqGrid = perQuestion.selectRangeValuesWithString('A1:CM2');
    expect(pqGrid[0]!.length, 91, reason: 'roll + 90 questions');
    expect(_text(pqGrid[0]![1]), 'q1');
    expect(_text(pqGrid[0]!.last), 'q90');
    expect(_int(pqGrid[1]![1]), 4, reason: 'R002 q1 correct = +4');
  });

  test('marksheet PDF is a real single-page document', () async {
    final rows = await fx.query().rows();
    final r001 = rows.singleWhere((r) => r.rollNo == 'R001');

    final doc = await MarksheetPdf().document(fx.query(), r001);

    expect(
      doc.document.pdfPageList.pages.length,
      1,
      reason: 'one student = one page',
    );
    final bytes = await doc.save();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(3000));
  });

  test('consolidated PDF paginates a large cohort without throwing', () async {
    // 120 students on the same exam, one grading pass, one render. The pdf
    // package's default maxPages=20 throws around 200 students — maxPages:
    // 500 is exactly what this test guards.
    await seedExtraCohort(db, fx, 120);
    final doc = await ConsolidatedPdf().document(fx.query());
    final bytes = await doc.save();

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(doc.document.pdfPageList.pages.length, greaterThan(2));
    expect(bytes.length, greaterThan(20000));
  });

  test(
    'ReportRunner records done jobs with paths and failed jobs with errors',
    () async {
      final dir = await Directory.systemTemp.createTemp('omr_reports_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final runner = ReportRunner(db);

      final path = await runner.run(
        tenantId: kTenantId,
        examId: fx.examId,
        type: ReportJobType.csv,
        format: 'csv',
        directory: dir.path,
        fileName: 'results.csv',
        params: {'keyVersionId': fx.keyVersionId},
        build: () async => utf8.encode('roll,total\nR001,3\n'),
      );
      expect(File(path).readAsStringSync(), startsWith('roll'));

      await expectLater(
        runner.run(
          tenantId: kTenantId,
          examId: fx.examId,
          type: ReportJobType.marksheet,
          format: 'pdf',
          directory: dir.path,
          fileName: 'boom.pdf',
          params: const {},
          build: () async => throw StateError('render exploded'),
        ),
        throwsStateError,
      );

      final jobs = await db.reportJobsDao.recentFor(fx.examId);
      expect(jobs.length, 2);
      final done = jobs.singleWhere((j) => j.status == ReportJobStatus.done);
      expect(done.filePath, path);
      expect(done.generatedAt, isNotNull);
      final failed = jobs.singleWhere(
        (j) => j.status == ReportJobStatus.failed,
      );
      expect(failed.errorText, contains('render exploded'));
    },
  );
}

String? _text(dynamic cell) => cell is TextCellValue ? cell.value.text : null;

int? _int(dynamic cell) => cell is IntCellValue ? cell.value : null;
