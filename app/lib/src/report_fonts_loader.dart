import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:omr_reports/omr_reports.dart';
import 'package:pdf/widgets.dart' as pw;

/// System font files the phone already ships (Android), most specific first.
/// Nothing is downloaded: exam halls are offline, and these cover the
/// scripts Indian rosters actually use.
const List<String> _baseCandidates = [
  '/system/fonts/Roboto-Regular.ttf',
  '/system/fonts/NotoSans-Regular.ttf',
  '/system/fonts/DroidSans.ttf',
];

const List<String> _boldCandidates = [
  '/system/fonts/Roboto-Bold.ttf',
  '/system/fonts/NotoSans-Bold.ttf',
  '/system/fonts/DroidSans-Bold.ttf',
];

const List<String> _scripts = [
  'Devanagari',
  'Bengali',
  'Gujarati',
  'Gurmukhi',
  'Kannada',
  'Malayalam',
  'Oriya',
  'Tamil',
  'Telugu',
];

List<String> _scriptCandidates(String script) => [
  '/system/fonts/NotoSans$script-Regular.ttf',
  '/system/fonts/NotoSans$script-VF.ttf',
  '/system/fonts/NotoSans${script}UI-Regular.ttf',
  '/system/fonts/NotoSans${script}UI-VF.ttf',
];

Future<ReportFonts?>? _cached;

/// The best offline [ReportFonts] this device offers, or null when no
/// usable TTF exists (desktop tests, unusual ROMs) — renderers then fall
/// back to the PDF built-ins, which still print every Latin field.
///
/// Loaded once per app run; failures are per-file and silent, because a
/// missing font must never block a report.
Future<ReportFonts?> loadReportFonts() => _cached ??= _load();

@visibleForTesting
void resetReportFontsCache() => _cached = null;

Future<ReportFonts?> _load() async {
  if (kIsWeb || !Platform.isAndroid) return null;
  final base = await _firstLoadable(_baseCandidates);
  if (base == null) return null;
  final bold = await _firstLoadable(_boldCandidates);
  final fallback = <pw.Font>[
    for (final script in _scripts)
      ?await _firstLoadable(_scriptCandidates(script)),
  ];
  return ReportFonts(base: base, bold: bold, fallback: fallback);
}

Future<pw.Font?> _firstLoadable(List<String> paths) async {
  for (final path in paths) {
    final file = File(path);
    try {
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      return pw.Font.ttf(ByteData.sublistView(Uint8List.fromList(bytes)));
    } catch (error) {
      // OTF/CFF or a malformed file: try the next candidate.
      debugPrint('report font skipped: $path ($error)');
    }
  }
  return null;
}
