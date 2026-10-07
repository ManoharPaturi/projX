import 'package:omr_data/omr_data.dart';

/// Operator-facing wording for every stored code the UI shows.
///
/// Storage keeps its machine codes (they are audit keys and survive
/// translation); screens only ever show what these functions return. One
/// file, so the app speaks with one voice and a translation has one target.

/// What a review reason means, said the way a teacher would.
String reviewReasonLabel(String code) => switch (code) {
  'NO_MARKER_ERR' => 'Sheet corners not found',
  'ROLL_CHECKSUM_ERR' => 'Roll number and check digit disagree',
  'ROLL_NOT_ON_ROSTER' => 'Roll number is not on the student list',
  'ROLL_AMBIGUOUS' => 'Roll number is unclear',
  'SET_BLANK' => 'Question paper set left blank',
  'SET_MULTI' => 'Two question paper sets marked',
  'MULTI_BUBBLE_WARN' => 'A question has two marks',
  'PROBABLE_BUBBLE' => 'Some marks are faint',
  'CURL_WARN' => 'Sheet looked bent or curled',
  'LOW_CONFIDENCE' => 'Photo was hard to read',
  'DUPLICATE_SHEET' => 'This student already has a scanned sheet',
  _ => 'Needs a quick check',
};

/// What the operator should do about a review reason.
String reviewReasonHelp(String code) => switch (code) {
  'NO_MARKER_ERR' =>
    'Retake the photo with all four black corner squares visible.',
  'ROLL_CHECKSUM_ERR' ||
  'ROLL_NOT_ON_ROSTER' ||
  'ROLL_AMBIGUOUS' => 'Look at the sheet and type the student\'s roll number.',
  'DUPLICATE_SHEET' =>
    'Check the roll number on the paper. If it is another student\'s sheet, '
        'type their roll below. If it is a rescan of the same student, save '
        'to use this sheet instead of the earlier one. Otherwise reject it.',
  'SET_BLANK' || 'SET_MULTI' => 'Tap the set the student actually wrote.',
  'MULTI_BUBBLE_WARN' || 'PROBABLE_BUBBLE' =>
    'Look at the sheet and tap the answer the student really marked.',
  'CURL_WARN' || 'LOW_CONFIDENCE' =>
    'Check the answers below, or retake the photo on a flat surface.',
  _ => 'Compare the answers below with the paper sheet.',
};

/// Exam lifecycle in plain words.
String examStatusLabel(ExamStatus status) => switch (status) {
  ExamStatus.draft => 'Not started',
  ExamStatus.active => 'Scanning',
  ExamStatus.graded => 'Marked',
  ExamStatus.published => 'Results shared',
};

/// "q17" → "Question 17", "set" → "Question paper set", "roll3" → "Roll
/// digit 3".
String fieldLabel(String fieldKey) {
  final question = RegExp(r'^q(\d+)$').firstMatch(fieldKey);
  if (question != null) return 'Question ${question.group(1)}';
  final roll = RegExp(r'^roll(\d+)$').firstMatch(fieldKey);
  if (roll != null) return 'Roll digit ${roll.group(1)}';
  if (fieldKey == 'set') return 'Question paper set';
  return fieldKey;
}

/// "q17" → "17" for compact grids.
String questionNumber(String questionId) =>
    questionId.replaceFirst(RegExp(r'^q'), '');

/// A sheet layout as the operator chooses it.
String layoutLabel(String layoutId) => switch (layoutId) {
  'std90' => 'Standard sheet — 90 questions',
  'neet180' => 'NEET sheet — 180 questions',
  _ => layoutId,
};

/// Key version in plain words.
String keyVersionLabel(int version, KeyVersionStatus status) =>
    'Answer key $version'
    '${status == KeyVersionStatus.finalized ? '' : ' (draft)'}';

/// Report type names.
String reportTypeLabel(ReportJobType type) => switch (type) {
  ReportJobType.consolidated => 'Class result list (PDF)',
  ReportJobType.excel => 'Excel workbook',
  ReportJobType.csv => 'Spreadsheet (CSV)',
  ReportJobType.marksheet => 'Student marksheet (PDF)',
  ReportJobType.analytics => 'Analysis',
};

/// "7 Oct 2026, 14:05" in local time.
String formatDateTime(DateTime when) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final t = when.toLocal();
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]} ${t.year}, $hh:$mm';
}

/// "7 Oct 2026".
String formatDate(DateTime when) {
  final full = formatDateTime(when);
  return full.substring(0, full.indexOf(','));
}
