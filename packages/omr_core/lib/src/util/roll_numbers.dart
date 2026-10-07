/// Roll-number identity rules shared by detection, the roster and intake.
///
/// A roll number is bubbled into fixed digit columns, so the SAME student can
/// legitimately arrive as `0001234` (every column filled) or `1234` (leading
/// columns left blank), and a roster typed in a spreadsheet often loses its
/// leading zeros altogether. Every comparison therefore goes through
/// [canonicalRoll]; the stored roster value is kept exactly as entered.
library;

/// Payload digit columns on every shipped sheet preset.
const int kSheetRollDigits = 7;

final RegExp _digitsOnly = RegExp(r'^[0-9]+$');

/// The comparison form of a roll number.
///
/// Numeric rolls compare by value (leading zeros dropped, all-zero → `0`);
/// anything else compares trimmed and case-folded, so legacy alphanumeric
/// rosters still match themselves even though they can never be bubbled.
String canonicalRoll(String roll) {
  final trimmed = roll.trim();
  if (_digitsOnly.hasMatch(trimmed)) {
    final stripped = trimmed.replaceFirst(RegExp(r'^0+'), '');
    return stripped.isEmpty ? '0' : stripped;
  }
  return trimmed.toUpperCase();
}

/// True when [roll] can be bubbled on a sheet with [digits] payload columns:
/// digits only, and no more significant digits than there are columns.
bool isScannableRoll(String roll, {int digits = kSheetRollDigits}) {
  final trimmed = roll.trim();
  if (!_digitsOnly.hasMatch(trimmed)) return false;
  return canonicalRoll(trimmed).length <= digits;
}

/// Weighted check digit over a payload of digit columns (`null` = blank):
/// `(Σ dᵢ · wᵢ) mod 10`, weights 3,1,3,1,… from the most-significant column.
///
/// Every single-digit substitution and every adjacent transposition of
/// distinct digits changes the result, which a plain digit sum would miss.
int rollChecksumOf(List<int?> payload) {
  var sum = 0;
  for (var i = 0; i < payload.length; i++) {
    sum += (payload[i] ?? 0) * (i.isEven ? 3 : 1);
  }
  return sum % 10;
}

/// The check digit a student must bubble in the sheet's last roll column for
/// [roll], or `null` when the roll cannot be bubbled at all.
///
/// The roll is right-aligned into [digits] columns; blank leading columns
/// weigh as zero, so `1234` and `0001234` share one check digit.
int? rollCheckDigit(String roll, {int digits = kSheetRollDigits}) {
  if (!isScannableRoll(roll, digits: digits)) return null;
  final value = canonicalRoll(roll);
  final padded = value.padLeft(digits, '0');
  return rollChecksumOf([for (final unit in padded.codeUnits) unit - 0x30]);
}
