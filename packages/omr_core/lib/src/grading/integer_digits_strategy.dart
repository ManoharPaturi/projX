part of 'scoring_strategy.dart';

/// What stopped an integer-digit read from being a clean number.
enum IntegerDigitsIssue {
  /// The left-most digit column(s) were left blank while later columns were
  /// marked. Numerically harmless (the block is right-aligned), but it can also
  /// be a missed read of a real leading digit, so it is escalated.
  leadingBlankColumn,

  /// A digit column in the middle of the number was left blank.
  interiorBlankColumn,

  /// Two or more bubbles marked in the same digit column.
  multiMarkedColumn,

  /// An option id that does not follow the `column:digit` contract.
  malformedOptionId,
}

/// Decoded integer-digit field: [value] is what the marks would be *if* the
/// read is trusted, [ambiguous] says whether it may be trusted, and [issues]
/// says why not.
typedef IntegerDigitsRead = ({
  int? value,
  bool ambiguous,
  Set<IntegerDigitsIssue> issues,
});

/// Encodes and decodes integer answers as bubble option ids.
///
/// Contract with the detection layer: the option id for an integer question is
/// `'<columnIndex>:<digit>'` with column 0 the most-significant column, e.g. a
/// student bubbling `0` then `3` produces `{'0:0', '1:3'}`. Only marked bubbles
/// appear, so an unmarked column is invisible to the set and must be inferred
/// from the column indices — which is exactly how a *blank* leading column is
/// told apart from an *explicit* `0`:
///
/// * `{'0:0', '1:3'}` → 03 → value 3, clean.
/// * `{'1:3'}` → ` 3` → value 3 (same number), but flagged
///   [IntegerDigitsIssue.leadingBlankColumn] and treated as ambiguous.
///
/// Living here — in the grading core, not in detection — keeps one codec as the
/// single definition of "what the student's digits meant", so a re-grade cannot
/// drift from the original read.
final class IntegerDigitsCodec {
  const IntegerDigitsCodec._();

  /// Separator used in the option-id encoding.
  static const String separator = ':';

  /// Option id for [digit] bubbled in [column] (0 = most significant).
  static String encode(int column, int digit) => '$column$separator$digit';

  /// Builds the option-id set for a whole number written across [columns]
  /// digits, right-aligned and zero-padded — `'3'` over 2 columns gives the
  /// explicit `03` encoding, which is the unambiguous way to mark it.
  static Set<String> encodeNumber(int value, int columns) {
    if (columns < 1) {
      throw ArgumentError.value(columns, 'columns', 'must be at least 1');
    }
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'must not be negative');
    }
    final String padded = value.toString().padLeft(columns, '0');
    if (padded.length > columns) {
      throw ArgumentError.value(
        value,
        'value',
        'does not fit in $columns digit columns',
      );
    }
    return <String>{
      for (int i = 0; i < columns; i++) encode(i, int.parse(padded[i])),
    };
  }

  /// Decodes a chosen set into a value plus its trust issues.
  static IntegerDigitsRead decode(Set<String> chosen) {
    final Set<IntegerDigitsIssue> issues = <IntegerDigitsIssue>{};
    final Map<int, Set<int>> byColumn = <int, Set<int>>{};
    for (final String id in chosen) {
      final List<String> parts = id.split(separator);
      final int? column = parts.length == 2 ? int.tryParse(parts[0]) : null;
      final int? digit = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (column == null ||
          digit == null ||
          column < 0 ||
          digit < 0 ||
          digit > 9) {
        issues.add(IntegerDigitsIssue.malformedOptionId);
        continue;
      }
      byColumn.putIfAbsent(column, () => <int>{}).add(digit);
    }

    if (byColumn.isEmpty) {
      return (
        value: null,
        ambiguous: issues.isNotEmpty,
        issues: issues,
      );
    }

    final List<int> columns = byColumn.keys.toList()..sort();
    final bool multiMarked = byColumn.values.any(
      (Set<int> digits) => digits.length > 1,
    );
    if (multiMarked) issues.add(IntegerDigitsIssue.multiMarkedColumn);
    if (columns.first > 0) issues.add(IntegerDigitsIssue.leadingBlankColumn);
    bool interiorBlank = false;
    for (int i = 1; i < columns.length; i++) {
      if (columns[i] - columns[i - 1] > 1) {
        interiorBlank = true;
        issues.add(IntegerDigitsIssue.interiorBlankColumn);
      }
    }

    // A value is reported only when the digits can be read off in place: a
    // multi-marked column offers two digits for one slot, and a blank column
    // *inside* the number would silently shift every digit to its left. A blank
    // leading column is different — the block is right-aligned, so a missing
    // most-significant digit changes nothing, and the number is still reported
    // (the caller then decides whether to trust it).
    int? value;
    if (!multiMarked && !interiorBlank) {
      final StringBuffer buf = StringBuffer();
      for (final int c in columns) {
        buf.write(byColumn[c]!.single);
      }
      value = int.parse(buf.toString());
    }
    return (value: value, ambiguous: issues.isNotEmpty, issues: issues);
  }
}

/// Numeric-value questions (JEE-Main "numerical answer" type): the student
/// bubbles a multi-digit number, one digit per column.
///
/// Params:
/// * `correct` (num, default 4)
/// * `wrong` (num, default −1)
/// * `unattempted` (num, default 0)
/// * `ambiguousAction` (`wrong` | `unattempted`, default `wrong`)
///
/// Ambiguity is any of: a multi-marked digit column, a blank column inside the
/// number, or a *blank leading* column. The last one deserves calling out: a
/// blank leading column decodes to the same integer as an explicit leading
/// zero, but it may equally be a leading digit the camera missed, so the
/// strategy refuses to guess and hands the response to [ambiguousAction] while
/// the read is flagged for review. Explicit `0` is never penalised.
final class IntegerDigitsStrategy extends ScoringStrategy {
  /// Const singleton.
  const IntegerDigitsStrategy();

  @override
  ScoringStrategyKind get kind => ScoringStrategyKind.integerDigits;

  @override
  QuestionOutcome score(
    MarkedResponse response,
    KeyEntry key,
    ScoringRule rule,
  ) {
    final ScoringParams p = ScoringParams(rule.params);
    final String questionId = key.questionId;

    if (key.correctInteger == null) {
      throw ArgumentError(
        'integer-digit key for "$questionId" has no correctInteger value',
      );
    }
    if (response.chosen.isEmpty) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.unattempted,
        p.numOr('unattempted', 0),
        'unattempted',
      );
    }

    final IntegerDigitsRead read = IntegerDigitsCodec.decode(response.chosen);
    final String issues = read.issues
        .map((IntegerDigitsIssue i) => i.name)
        .toList()
        .join(', ');

    if (read.ambiguous) {
      final String action = p.enumOr(
        'ambiguousAction',
        const <String>{'wrong', 'unattempted'},
        'wrong',
      );
      return switch (action) {
        'unattempted' => QuestionOutcome.of(
          questionId,
          QuestionOutcomeKind.unattempted,
          0,
          'unattempted: ambiguous digit read ($issues) — ambiguousAction '
          'unattempted',
        ),
        _ => QuestionOutcome.of(
          questionId,
          QuestionOutcomeKind.wrong,
          p.numOr('wrong', -1),
          'wrong: ambiguous digit read ($issues) — ambiguousAction wrong',
        ),
      };
    }

    final int marked = read.value!;
    if (marked == key.correctInteger) {
      return QuestionOutcome.of(
        questionId,
        QuestionOutcomeKind.correct,
        p.numOr('correct', 4),
        'correct: $marked',
      );
    }
    return QuestionOutcome.of(
      questionId,
      QuestionOutcomeKind.wrong,
      p.numOr('wrong', -1),
      'wrong: marked $marked, key ${key.correctInteger}',
    );
  }

  @override
  void validate(ScoringRule rule) {
    final ScoringParams p = ScoringParams(rule.params);
    p.numOr('correct', 4);
    p.numOr('wrong', -1);
    p.numOr('unattempted', 0);
    p.enumOr(
      'ambiguousAction',
      const <String>{'wrong', 'unattempted'},
      'wrong',
    );
  }
}
