/// Number/label formatting shared by every renderer, so the same total prints
/// identically on PDF, XLSX and CSV.
library;

/// Marks render without a trailing '.0' (4 not 4.0) but keep genuine
/// fractions (2.5) — what teachers read aloud.
String formatMarks(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// 'physics' → 'Physics Marks'; ids that are already display-ready
/// ('Physics') pass through; snake_case becomes spaced title case.
String subjectColumnLabel(String subject, {String suffix = ' Marks'}) {
  final spaced = subject.replaceAll('_', ' ');
  final needsTitleCase =
      spaced == spaced.toLowerCase() || spaced == spaced.toUpperCase();
  final label = needsTitleCase
      ? spaced
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ')
      : spaced;
  return '$label$suffix';
}

/// '12 Aug 2026' — the date format Indian results pages use.
String formatExamDate(DateTime? dt) => dt == null
    ? ''
    : '${dt.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]} ${dt.year}';
