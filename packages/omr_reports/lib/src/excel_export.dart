import 'package:excel_plus/excel_plus.dart';
import 'package:omr_core/omr_core.dart' as core;

import 'format.dart';
import 'results_query.dart';

/// Renders the cohort as an .xlsx workbook (plan §7): a Summary sheet (one
/// row per student, percentile as a live formula) and a Per Question sheet
/// (marks matrix, roll × question) so institutes can extend with their own
/// formulas instead of re-typing data.
class ExcelExporter {
  /// Builds the workbook bytes for every published row of the query.
  ///
  /// [outcomesByRoll] is optional: without it only the Summary sheet is
  /// written (cheap, list screens); with it the Per Question matrix follows.
  Future<List<int>> build(
    ResultsQuery query, {
    Map<String, List<core.QuestionOutcome>>? outcomesByRoll,
  }) async {
    final header = await query.header();
    final rows = await query.rows();

    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Summary');
    _writeSummary(excel['Summary'], header, rows);
    if (outcomesByRoll != null && outcomesByRoll.isNotEmpty) {
      _writePerQuestion(excel['Per Question'], header, rows, outcomesByRoll);
    }
    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('excel_plus produced no bytes');
    }
    return bytes;
  }

  void _writeSummary(Sheet sheet, ExamHeader header, List<ReportRow> rows) {
    sheet.appendRow([
      for (final h in _summaryHeaders(header)) TextCellValue(h),
    ]);
    for (var i = 0; i < rows.length; i++) {
      // Spreadsheet row of this student: row 1 is the header, so first
      // student sits at 2 — the percentile formula references its own row.
      sheet.appendRow(
        _summaryRow(
          header,
          rows[i],
          spreadsheetRow: i + 2,
          rowCount: rows.length,
        ),
      );
    }
  }

  List<String> _summaryHeaders(ExamHeader header) => [
    'Roll No',
    'Name',
    'Rank',
    'Total',
    'Correct',
    'Wrong',
    'Unattempted',
    'Attempted',
    ...header.subjects.map((s) => subjectColumnLabel(s)),
    'Percentile',
    'Status',
  ];

  List<CellValue?> _summaryRow(
    ExamHeader header,
    ReportRow row, {
    required int spreadsheetRow,
    required int rowCount,
  }) {
    // A=Roll, B=Name, C=Rank, D=Total, E..H counts, subjects, then percentile.
    const totalCol = 'D';
    final lastDataRow = rowCount + 1; // row 1 is the header
    final range = '\$$totalCol\$2:\$$totalCol\$$lastDataRow';
    // Coaching-institute percentile: percent of the cohort strictly below
    // this total. A formula, not a constant — institutes sort/filter on it
    // and expect it to survive their own edits.
    final percentile = FormulaCellValue(
      'ROUND(COUNTIF($range,">"&$totalCol$spreadsheetRow)'
      '/COUNT($range)*100,2)',
    );
    return <CellValue?>[
      TextCellValue(row.rollNo),
      TextCellValue(row.name ?? ''),
      row.rank == null ? null : IntCellValue(row.rank!),
      _num(row.total),
      IntCellValue(row.correct),
      IntCellValue(row.wrong),
      IntCellValue(row.unattempted),
      IntCellValue(row.attempted),
      ...header.subjects.map((s) => _num(row.subjectTotals[s] ?? 0)),
      percentile,
      TextCellValue(row.status.name),
    ];
  }

  void _writePerQuestion(
    Sheet sheet,
    ExamHeader header,
    List<ReportRow> rows,
    Map<String, List<core.QuestionOutcome>> outcomesByRoll,
  ) {
    // Serial order comes from any cohort member's outcomes — they are all the
    // same layout. Rows without outcomes (shouldn't happen) print blanks.
    final questionIds = <String>[
      for (final o in outcomesByRoll.values.first) o.questionId,
    ];
    sheet.appendRow([
      TextCellValue('Roll No'),
      for (final q in questionIds) TextCellValue(q),
    ]);
    for (final row in rows) {
      final outcomes = outcomesByRoll[row.rollNo];
      sheet.appendRow([
        TextCellValue(row.rollNo),
        if (outcomes == null)
          ...questionIds.map((_) => null)
        else
          ...outcomes.map((o) => _num(o.marksAwarded)),
      ]);
    }
  }

  /// Marks keep their numeric type so Excel can SUM them: integers stay
  /// integers, genuine fractions become doubles.
  CellValue _num(double v) =>
      v == v.roundToDouble() ? IntCellValue(v.toInt()) : DoubleCellValue(v);
}
