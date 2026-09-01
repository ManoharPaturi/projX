import 'package:omr_core/omr_core.dart';
import 'package:omr_spec/omr_spec.dart' show BlockType;

import '../models/bubble_read.dart';
import '../thresholds/threshold_config.dart';

/// Stage 9: classified fields → the [SheetRead] that grading consumes.
///
/// This is where field verdicts become semantics: a BLANK MCQ is an
/// unattempted question (empty chosen set — never a guess, the
/// unmarked-row floor), a MULTIPLE MCQ carries every clear mark into
/// `chosen` so the scoring strategy (and its `multiMarkAction`) decides,
/// not detection. Roll columns decode under an exactly-one-per-column rule
/// with a weighted checksum; the set code decodes only when unambiguous.
///
/// Every anomaly raises a [SheetReadFlag] — by construction a flag IS a
/// review reason, so `flags.isNotEmpty` is the review router.
class FieldDecoder {
  const FieldDecoder({
    this.rollDigits = 7,
    this.rollChecksum = true,
    this.roster,
    this.config = const ThresholdConfig(),
  });

  /// Payload digit columns (excluding the checksum column).
  final int rollDigits;

  /// Whether the sheet carries a checksum column after the payload.
  final bool rollChecksum;

  /// Known roll numbers; `null` when no roster is loaded (the check is
  /// skipped, not failed).
  final Set<String>? roster;

  final ThresholdConfig config;

  SheetRead decode({
    required List<FieldRead> fields,
    required double sheetConfidence,
    double rollConfidence = 1,
    bool curlDetected = false,
  }) {
    final flags = <SheetReadFlag>{};
    if (curlDetected) flags.add(SheetReadFlag.curlDetected);
    if (sheetConfidence < config.reviewConfidenceFloor) {
      flags.add(SheetReadFlag.lowConfidence);
    }

    final responses = <QuestionId, MarkedResponse>{};
    final rollFields = <FieldRead>[];
    final intOrder = <String>[];
    final intBlocks = <String, List<FieldRead>>{};
    String? setCodeRead;

    for (final field in fields) {
      switch (field.blockType) {
        case BlockType.mcq || BlockType.matrix:
          responses[field.fieldKey] = _mcqResponse(field, flags);
        case BlockType.setCode:
          setCodeRead = _decodeSet(field, flags);
        case BlockType.rollDigits:
          rollFields.add(field);
        case BlockType.intDigits:
          intBlocks
              .putIfAbsent(field.blockId, () {
                intOrder.add(field.blockId);
                return <FieldRead>[];
              })
              .add(field);
      }
    }

    // Integer blocks: columns arrive as separate fields of one block, in
    // emission (significance) order. QuestionId falls back to the block id —
    // no preset ships an INT_DIGITS block yet, and the block-id → canonical
    // qId join belongs to the question-set map when one does.
    for (final blockId in intOrder) {
      responses[blockId] = _intDigitsResponse(intBlocks[blockId]!, flags);
    }

    final rollNo = rollFields.isEmpty ? null : _decodeRoll(rollFields, flags);

    return SheetRead(
      responses: responses,
      sheetConfidence: sheetConfidence,
      rollNoRead: rollNo,
      rollConfidence: rollConfidence,
      setCodeRead: setCodeRead,
      flags: flags,
    );
  }

  // -------------------------------------------------------------- MCQ fields

  MarkedResponse _mcqResponse(FieldRead field, Set<SheetReadFlag> flags) {
    switch (field.markClass) {
      case MarkClass.filled:
        return MarkedResponse(
          chosen: {field.selectedOptionValue!},
          confidence: field.confidence,
        );
      case MarkClass.overfilled:
        // Intent likely clear, reading suspect — grade the read value but
        // route through review before it counts.
        flags.add(SheetReadFlag.multiMarkedField);
        return MarkedResponse(
          chosen: {field.selectedOptionValue!},
          confidence: field.confidence,
        );
      case MarkClass.blank:
        // Unattempted: an empty set, never an argmax guess.
        return MarkedResponse(
          chosen: const <OptionId>{},
          confidence: field.confidence,
        );
      case MarkClass.probable:
        flags.add(SheetReadFlag.probableBubblesPresent);
        return MarkedResponse(
          chosen: const <OptionId>{},
          confidence: field.confidence,
          validity: ResponseValidity.probable,
        );
      case MarkClass.multiple:
        // Carry EVERY clear mark: the scoring strategy's multiMarkAction
        // decides marks; detection must not pre-decide by dropping one.
        flags.add(SheetReadFlag.multiMarkedField);
        return MarkedResponse(
          chosen: _filledValues(field),
          confidence: field.confidence,
          validity: ResponseValidity.multiMarked,
        );
    }
  }

  Set<OptionId> _filledValues(FieldRead field) => {
        for (final bubble in field.bubbles)
          if (bubble.zone == BubbleZone.filled) bubble.sample.optionValue,
        };

  // ------------------------------------------------------------- set code

  String? _decodeSet(FieldRead field, Set<SheetReadFlag> flags) {
    switch (field.markClass) {
      case MarkClass.filled:
        return field.selectedOptionValue;
      case MarkClass.overfilled:
        flags.add(SheetReadFlag.multiMarkedField);
        return field.selectedOptionValue;
      case MarkClass.blank:
        flags.add(SheetReadFlag.setCodeBlank);
        return null;
      case MarkClass.multiple:
        flags.add(SheetReadFlag.setCodeMulti);
        return null;
      case MarkClass.probable:
        flags.add(SheetReadFlag.probableBubblesPresent);
        return null;
    }
  }

  // ---------------------------------------------------------- roll decoding

  /// Payload digits with a checksum column, per the sheet's roll field:
  ///
  /// `check = (Σ dᵢ · wᵢ) mod 10`, weights alternating 3,1,3,1,… from the
  /// most-significant payload column. Every single-digit substitution
  /// changes the weighted sum by `w·δ` with `δ ∈ 1..9` — never a multiple
  /// of 10 — and adjacent transpositions change it too (3a+b ≠ 3b+a unless
  /// a = b), which a plain digit sum would miss. Leading blank columns
  /// weigh in as 0, so an unpadded roll and its zero-padded roster form
  /// produce the same check digit.
  static int rollChecksumOf(List<int?> payload) {
    var sum = 0;
    for (var i = 0; i < payload.length; i++) {
      sum += (payload[i] ?? 0) * (i.isEven ? 3 : 1);
    }
    return sum % 10;
  }

  String? _decodeRoll(List<FieldRead> rollFields, Set<SheetReadFlag> flags) {
    // Column digit, null = blank column. Ambiguous columns (MULTIPLE or
    // PROBABLE) abort the read: a roll number is exactly-one-per-column,
    // and any exception must surface, not resolve.
    final digits = <int?>[];
    var ambiguous = false;
    for (final field in rollFields) {
      switch (field.markClass) {
        case MarkClass.filled || MarkClass.overfilled:
          final digit = int.tryParse(field.selectedOptionValue ?? '');
          if (digit == null) {
            ambiguous = true;
            digits.add(null);
          } else {
            digits.add(digit);
          }
        case MarkClass.blank:
          digits.add(null);
        case MarkClass.probable || MarkClass.multiple:
          ambiguous = true;
          digits.add(null);
      }
    }

    var hasChecksum = false;
    var payload = digits;
    if (rollChecksum && digits.length == rollDigits + 1) {
      hasChecksum = true;
      payload = digits.sublist(0, rollDigits);
    }

    String? rollNo;
    var readable = !ambiguous;
    if (readable) {
      final lastMarked = payload.lastIndexWhere((d) => d != null);
      if (lastMarked < 0) {
        // Entirely blank roll: nothing to attribute the sheet to.
        readable = false;
      } else {
        // Leading and trailing blanks are fine (the number is what it is);
        // a hole BETWEEN marked columns would silently shift every digit
        // after it — refuse rather than mis-attribute the sheet.
        final firstMarked = payload.indexWhere((d) => d != null);
        readable = !payload
            .getRange(firstMarked, lastMarked + 1)
            .contains(null);
      }
    }
    if (readable) {
      final buf = StringBuffer();
      for (final d in payload) {
        if (d != null) buf.write(d);
      }
      rollNo = buf.toString();
    } else {
      flags.add(SheetReadFlag.rollColumnAmbiguous);
    }

    if (hasChecksum && rollNo != null) {
      final actual = digits[rollDigits];
      if (actual == null) {
        // Readable payload but an unreadable checksum column: the roll
        // cannot be verified, which is reviewable — never a crash, and
        // never silently "verified".
        flags.add(SheetReadFlag.rollColumnAmbiguous);
      } else if (actual != rollChecksumOf(payload)) {
        flags.add(SheetReadFlag.rollChecksumMismatch);
      }
    }

    final roster = this.roster;
    if (roster != null &&
        rollNo != null &&
        rollNo.isNotEmpty &&
        !roster.contains(rollNo)) {
      flags.add(SheetReadFlag.rollNotOnRoster);
    }

    return rollNo;
  }

  // ------------------------------------------------------ integer answers

  MarkedResponse _intDigitsResponse(
    List<FieldRead> columns,
    Set<SheetReadFlag> flags,
  ) {
    final chosen = <OptionId>{};
    var validity = ResponseValidity.valid;
    var confidence = 1.0;
    for (var column = 0; column < columns.length; column++) {
      final field = columns[column];
      if (field.confidence < confidence) confidence = field.confidence;
      switch (field.markClass) {
        case MarkClass.filled:
          chosen.add(
            IntegerDigitsCodec.encode(
              column,
              int.parse(field.selectedOptionValue!),
            ),
          );
        case MarkClass.overfilled:
          flags.add(SheetReadFlag.multiMarkedField);
          chosen.add(
            IntegerDigitsCodec.encode(
              column,
              int.parse(field.selectedOptionValue!),
            ),
          );
        case MarkClass.blank:
          // Absent from the set; the codec's decode flags leading/interior
          // blank columns during grading.
          break;
        case MarkClass.probable:
          flags.add(SheetReadFlag.probableBubblesPresent);
          validity = ResponseValidity.probable;
        case MarkClass.multiple:
          flags.add(SheetReadFlag.multiMarkedField);
          validity = ResponseValidity.multiMarked;
          // Both digits for the column: the codec reports
          // multiMarkedColumn rather than silently picking one.
          for (final bubble in field.bubbles) {
            if (bubble.zone == BubbleZone.filled) {
              chosen.add(
                IntegerDigitsCodec.encode(
                  column,
                  int.parse(bubble.sample.optionValue),
                ),
              );
            }
          }
      }
    }
    return MarkedResponse(
      chosen: chosen,
      confidence: confidence,
      validity: validity,
    );
  }
}
