import 'package:pdf/widgets.dart' as pw;

/// Fonts a report renders with.
///
/// The PDF built-ins (Helvetica) are Latin-1 only: a Devanagari or Tamil
/// student name would print as blanks. The app layer hands in whatever
/// Unicode TTFs it can load offline (bundled assets, else the phone's own
/// system fonts), and every renderer builds its theme from this one object.
/// [fallback] fonts are consulted per glyph when [base] lacks it — that is
/// how one marksheet mixes Latin roll numbers with Indic names.
class ReportFonts {
  const ReportFonts({required this.base, this.bold, this.fallback = const []});

  final pw.Font base;
  final pw.Font? bold;
  final List<pw.Font> fallback;

  /// Document theme at [fontSize]; bold text uses [bold] when given, else
  /// the base face (synthetic bold is not available for TTFs).
  pw.ThemeData theme({required double fontSize}) =>
      pw.ThemeData.withFont(
        base: base,
        bold: bold ?? base,
        fontFallback: fallback,
      ).copyWith(
        defaultTextStyle: pw.TextStyle(
          font: base,
          fontBold: bold ?? base,
          fontFallback: fallback,
          fontSize: fontSize,
        ),
      );
}
