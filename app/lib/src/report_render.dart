import 'dart:convert';
import 'dart:isolate';

import 'package:omr_reports/omr_reports.dart';

/// Whole-class report rendering on a background isolate.
///
/// The data is read first, on the caller's isolate (the database lives
/// there); laying out a 100-page class PDF or a few thousand spreadsheet
/// cells is then pure CPU, and on the UI isolate it froze the screen for
/// the whole build. Top-level functions so each isolate closure captures
/// only its plain-data arguments.

Future<List<int>> renderClassPdf(
  ReportSnapshot snapshot,
  ReportFontBytes? fonts,
) => Isolate.run(
  () => ConsolidatedPdf(fonts: fonts?.toFonts()).render(snapshot),
  debugName: 'report-pdf',
);

Future<List<int>> renderWorkbook(ReportSnapshot snapshot) => Isolate.run(
  () => ExcelExporter().render(snapshot),
  debugName: 'report-xlsx',
);

/// UTF-8, not code units: Devanagari names must survive the file.
Future<List<int>> renderCsv(ReportSnapshot snapshot) => Isolate.run(
  () => utf8.encode(CsvExporter().convert(snapshot.header, snapshot.rows)),
  debugName: 'report-csv',
);
