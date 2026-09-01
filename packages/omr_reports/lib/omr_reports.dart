/// Report renderers (plan §7) — one canonical [ResultsQuery] feeding the
/// per-student marksheet PDF, the consolidated class PDF, XLSX and CSV
/// exporters, and the job runner that records every generation.
library;

export 'src/consolidated_pdf.dart';
export 'src/csv_export.dart';
export 'src/excel_export.dart';
export 'src/format.dart';
export 'src/marksheet_pdf.dart';
export 'src/report_runner.dart';
export 'src/results_query.dart';
