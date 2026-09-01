import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'format.dart';
import 'results_query.dart';

/// Renders the whole cohort as one paginated class list PDF (plan §7).
///
/// `MultiPage` + `maxPages: 500` is deliberate: the pdf package's default
/// maxPages of 20 throws mid-generation on ~200 students — the M3 acceptance
/// criterion ("paginates past 20 pages without throwing") pins exactly this.
class ConsolidatedPdf {
  ConsolidatedPdf({this.font, this.pageFormat = PdfPageFormat.a4});

  /// Optional unicode font (loaded TTF) for non-Latin student names.
  final pw.Font? font;

  final PdfPageFormat pageFormat;

  /// Builds the PDF bytes for every published row of the query.
  Future<List<int>> build(ResultsQuery query) async =>
      (await document(query)).save();

  /// The unsaved document — for callers that preview or append pages before
  /// serializing. Tests read its page count.
  Future<pw.Document> document(ResultsQuery query) async {
    final header = await query.header();
    final rows = await query.rows();

    final doc = pw.Document(theme: font == null ? null : _themeFor(font!));
    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(36, 44, 36, 36),
        maxPages: 500,
        header: (context) =>
            _repeatingHeader(header, context.pageNumber, context.pagesCount),
        build: (context) => [
          _titleBlock(header),
          pw.SizedBox(height: 8),
          _resultsTable(header, rows),
        ],
      ),
    );
    return doc;
  }

  pw.ThemeData _themeFor(pw.Font f) =>
      pw.ThemeData(defaultTextStyle: pw.TextStyle(font: f, fontSize: 9));

  /// Runs on EVERY page — page n of m must survive a teacher photocopying one
  /// sheet of the stack.
  pw.Widget _repeatingHeader(ExamHeader header, int pageNumber, int pages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Plain hyphen, not an em-dash: the built-in WinAnsi font can't
          // draw U+2014, and a repeating header must never warn per page.
          pw.Text(
            '${header.instituteName} - ${header.examName} '
            '(key v${header.keyVersionNumber})',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Text(
            'Page $pageNumber of $pages',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _titleBlock(ExamHeader header) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Consolidated Result Sheet',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        'Held ${formatExamDate(header.heldAt)} • ${header.studentCount} '
        'students • ${header.totalQuestions} questions • top score '
        '${formatMarks(header.maxTotal)}',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    ],
  );

  pw.Widget _resultsTable(ExamHeader header, List<ReportRow> rows) {
    final headers = <String>[
      '#',
      'Roll No',
      'Name',
      'Rank',
      'Total',
      'C',
      'W',
      'U',
      ...header.subjects.map((s) => subjectColumnLabel(s, suffix: '')),
      'Status',
    ];
    final data = <List<String>>[
      for (var i = 0; i < rows.length; i++) _tableRow(header, i + 1, rows[i]),
    ];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.center,
      oddCellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
    );
  }

  List<String> _tableRow(ExamHeader header, int serial, ReportRow row) => [
    serial.toString(),
    row.rollNo,
    row.name ?? '',
    row.rank?.toString() ?? '',
    formatMarks(row.total),
    row.correct.toString(),
    row.wrong.toString(),
    row.unattempted.toString(),
    ...header.subjects.map((s) => formatMarks(row.subjectTotals[s] ?? 0)),
    row.status.name,
  ];
}
