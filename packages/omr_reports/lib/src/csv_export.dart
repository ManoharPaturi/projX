import 'package:csv/csv.dart';

import 'format.dart';
import 'results_query.dart';

/// Renders the canonical results table as UTF-8 CSV (plan §7).
///
/// Two Excel-compat details are load-bearing for Indian institutes:
/// - **UTF-8 BOM** — without it Excel reads Devanagari names as mojibake
///   (the M3 acceptance criterion names this exactly).
/// - **comma delimiter, `QuoteMode.necessary`** — `Csv.excel()` presets the
///   European ';' delimiter; Indian-locale Excel expects ','.
///
/// Rows stream through the csv-8 encoder's [StreamTransformer] so a full
/// batch never has to sit in one buffer (the 10k-row safety) — [rows] to a
/// sink, [convert] for the in-memory one-shot.
class CsvExporter {
  CsvExporter({String fieldDelimiter = ','})
    : _csv = Csv(fieldDelimiter: fieldDelimiter, addBom: true);

  final Csv _csv;

  /// Column headers for the fixed prefix + this exam's subject columns.
  List<String> headerFor(ExamHeader header) => [
    'Roll No',
    'Name',
    'Rank',
    'Total',
    'Correct',
    'Wrong',
    'Unattempted',
    'Attempted',
    ...header.subjects.map((s) => subjectColumnLabel(s, suffix: '')),
    'Status',
  ];

  /// One CSV row for a [ReportRow]; `null` name renders empty, not "null".
  List<String> rowFor(ExamHeader header, ReportRow row) => [
    row.rollNo,
    row.name ?? '',
    row.rank?.toString() ?? '',
    formatMarks(row.total),
    row.correct.toString(),
    row.wrong.toString(),
    row.unattempted.toString(),
    row.attempted.toString(),
    ...header.subjects.map((s) => formatMarks(row.subjectTotals[s] ?? 0)),
    row.status.name,
  ];

  /// Full document as a string, BOM first.
  String convert(ExamHeader header, List<ReportRow> rows) =>
      _csv.encode([headerFor(header), for (final r in rows) rowFor(header, r)]);

  /// Streaming encode for large cohorts — one newline-terminated String event
  /// per row, BOM prepended to the first only. Feed to `utf8.encoder` then a
  /// file sink; the batch [convert] never has to hold 10k rows in memory.
  Stream<String> stream(ExamHeader header, Stream<ReportRow> rows) async* {
    // A bare encoder: the BOM-enabled one stamps every convert() batch (and
    // each streamed row is its own batch) with a fresh BOM.
    final e = Csv(fieldDelimiter: _csv.encoder.fieldDelimiter).encoder;
    yield '\ufeff${e.convert([headerFor(header)])}${e.lineDelimiter}';
    await for (final row in rows) {
      yield '${e.convert([rowFor(header, row)])}${e.lineDelimiter}';
    }
  }
}
