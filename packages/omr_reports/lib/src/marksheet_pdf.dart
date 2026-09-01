import 'package:omr_core/omr_core.dart' as core;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'format.dart';
import 'results_query.dart';

/// Renders ONE student's marksheet as a single-page A4 PDF (plan §7).
///
/// Per-question outcomes are rebuilt lazily through [ResultsQuery.outcomesFor]
/// — the same pure function the grading pass used — so a marksheet printed
/// today from an old key version reproduces that version's marks exactly.
///
/// Glyphs stay ASCII (`+4`, `-1`, `0`) because the built-in PDF fonts are
/// WinAnsi-only. Pass [font] with a Devanagari-capable TTF from the app layer
/// (where the asset lives) to render student names beyond Latin.
class MarksheetPdf {
  MarksheetPdf({this.font, this.pageFormat = PdfPageFormat.a4});

  /// Optional unicode font (loaded TTF) used for all text when provided.
  final pw.Font? font;

  final PdfPageFormat pageFormat;

  /// Builds the PDF bytes for [row].
  Future<List<int>> build(ResultsQuery query, ReportRow row) async =>
      (await document(query, row)).save();

  /// The unsaved document — for callers that preview, print via `printing`,
  /// or append pages before serializing. Tests read its page count.
  Future<pw.Document> document(ResultsQuery query, ReportRow row) async {
    final header = await query.header();
    final outcomes = await query.outcomesFor(row);

    final doc = pw.Document(theme: font == null ? null : _themeFor(font!));
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => _page(header, row, outcomes),
      ),
    );
    return doc;
  }

  pw.ThemeData _themeFor(pw.Font f) =>
      pw.ThemeData(defaultTextStyle: pw.TextStyle(font: f, fontSize: 10));

  pw.Widget _page(
    ExamHeader header,
    ReportRow row,
    List<core.QuestionOutcome> outcomes,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _headerBlock(header),
        pw.SizedBox(height: 10),
        _studentBlock(row),
        pw.SizedBox(height: 10),
        _summaryTable(header, row, outcomes),
        pw.SizedBox(height: 12),
        pw.Text(
          'Question-wise Marks',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Expanded(child: _questionGrid(outcomes)),
        pw.SizedBox(height: 6),
        _footer(header),
      ],
    );
  }

  pw.Widget _headerBlock(ExamHeader header) => pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1.2),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              header.instituteName,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(header.examName),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Held: ${formatExamDate(header.heldAt)}'),
            pw.Text('Key version: v${header.keyVersionNumber}'),
            pw.Text(
              'Students: ${header.studentCount}  •  Questions: ${header.totalQuestions}',
            ),
          ],
        ),
      ],
    ),
  );

  /// Roll leads; name prints only when the institute recorded one (DPDP: the
  /// roll is the student key, names are optional PII).
  pw.Widget _studentBlock(ReportRow row) => pw.Container(
    padding: const pw.EdgeInsets.all(10),
    color: PdfColors.grey100,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Roll No: ${row.rollNo}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (row.name != null && row.name!.isNotEmpty)
              pw.Text('Name: ${row.name!}'),
          ],
        ),
        pw.Text(
          row.rank == null ? 'Unranked' : 'Rank ${row.rank}',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  pw.Widget _summaryTable(
    ExamHeader header,
    ReportRow row,
    List<core.QuestionOutcome> outcomes,
  ) {
    final cells = <List<String>>[
      ['Total', 'Correct', 'Wrong', 'Unattempted', 'Attempted'],
      [
        formatMarks(row.total),
        row.correct.toString(),
        row.wrong.toString(),
        row.unattempted.toString(),
        row.attempted.toString(),
      ],
    ];
    return pw.TableHelper.fromTextArray(
      headers: cells[0],
      data: [cells[1]],
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(fontSize: 12),
    );
  }

  /// 90 outcomes as a compact grid: `12 +4` cells, green for marks gained,
  /// red for penalty, grey for zero. Two columns of the grid read left-right
  /// then next band, matching the sheet's own column order.
  pw.Widget _questionGrid(List<core.QuestionOutcome> outcomes) {
    return pw.GridView(
      crossAxisCount: 6,
      childAspectRatio: 2.4,
      children: [
        for (var i = 0; i < outcomes.length; i++)
          _questionCell(i + 1, outcomes[i]),
      ],
    );
  }

  pw.Widget _questionCell(int serial, core.QuestionOutcome outcome) {
    final color = outcome.marksAwarded > 0
        ? PdfColors.green800
        : outcome.marksAwarded < 0
        ? PdfColors.red700
        : PdfColors.grey600;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$serial', style: const pw.TextStyle(fontSize: 8)),
          pw.Text(
            formatMarks(outcome.marksAwarded),
            style: pw.TextStyle(fontSize: 9, color: color),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(ExamHeader header) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.only(top: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
    ),
    child: pw.Text(
      'Generated ${formatExamDate(header.generatedAt)} UTC • '
      'key v${header.keyVersionNumber} • cohort top score '
      '${formatMarks(header.maxTotal)}',
      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
    ),
  );
}
