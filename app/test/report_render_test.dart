import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/src/report_render.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart' show ResultStatus;
import 'package:omr_reports/omr_reports.dart';

/// The Reports tab's background renderers: each takes plain data, crosses
/// to an isolate, and returns the file bytes — including non-Latin names
/// and the workbook's Per Question sheet.
void main() {
  final snapshot = ReportSnapshot(
    header: ExamHeader(
      examId: 'e1',
      examName: 'Mock 1',
      instituteName: 'Test Institute',
      heldAt: null,
      totalQuestions: 2,
      keyVersionId: 'k1',
      keyVersionNumber: 1,
      subjects: const ['Physics'],
      studentCount: 2,
      maxTotal: 8,
      generatedAt: DateTime.utc(2026, 10, 14),
    ),
    rows: const [
      ReportRow(
        studentId: 's1',
        rollNo: 'R001',
        name: 'आरव शर्मा',
        rank: 1,
        total: 8,
        correct: 2,
        wrong: 0,
        unattempted: 0,
        subjectTotals: {'Physics': 8},
        status: ResultStatus.ok,
        scanId: 'scan1',
      ),
      ReportRow(
        studentId: 's2',
        rollNo: 'R002',
        name: null,
        rank: 2,
        total: 3,
        correct: 1,
        wrong: 1,
        unattempted: 0,
        subjectTotals: {'Physics': 3},
        status: ResultStatus.doubtful,
        scanId: 'scan2',
      ),
    ],
    outcomesByRoll: {
      'R001': const [
        core.QuestionOutcome(
          questionId: 'q1',
          kind: core.QuestionOutcomeKind.correct,
          marksAwarded: 4,
          reason: 'matches key',
        ),
        core.QuestionOutcome(
          questionId: 'q2',
          kind: core.QuestionOutcomeKind.correct,
          marksAwarded: 4,
          reason: 'matches key',
        ),
      ],
      'R002': const [
        core.QuestionOutcome(
          questionId: 'q1',
          kind: core.QuestionOutcomeKind.correct,
          marksAwarded: 4,
          reason: 'matches key',
        ),
        core.QuestionOutcome(
          questionId: 'q2',
          kind: core.QuestionOutcomeKind.wrong,
          marksAwarded: -1,
          reason: 'differs from key',
        ),
      ],
    },
  );

  test('class PDF renders off the UI isolate', () async {
    final bytes = await renderClassPdf(snapshot, null);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('class PDF embeds fonts sent across as bytes', () async {
    // Any TrueType font the host has; the phone path uses /system/fonts.
    final ttf = [
      '/System/Library/Fonts/Supplemental/Arial.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ].map(File.new).where((f) => f.existsSync()).firstOrNull;
    if (ttf == null) {
      markTestSkipped('no TrueType font on this host');
      return;
    }
    final data = ByteData.sublistView(ttf.readAsBytesSync());
    final withFont = await renderClassPdf(
      snapshot,
      ReportFontBytes(base: data),
    );
    final builtIn = await renderClassPdf(snapshot, null);
    expect(String.fromCharCodes(withFont.take(5)), '%PDF-');
    expect(
      withFont.length,
      greaterThan(builtIn.length),
      reason: 'the TTF (subset) is embedded in the document',
    );
  });

  test('workbook renders off the UI isolate with Per Question', () async {
    final excel = Excel.decodeBytes(await renderWorkbook(snapshot));
    expect(excel.sheets.keys, containsAll(['Summary', 'Per Question']));
    expect(excel['Per Question'].maxRows, 3);
  });

  test('CSV renders off the UI isolate and keeps Devanagari', () async {
    final text = utf8.decode(await renderCsv(snapshot));
    expect(text, contains('आरव शर्मा'));
    expect(text, contains('Check sheet'));
  });
}
