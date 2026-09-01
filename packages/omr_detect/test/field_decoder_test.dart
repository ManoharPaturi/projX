import 'package:omr_core/omr_core.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart' show BlockType;
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const decoder = FieldDecoder();

  FieldRead mcq(String key, MarkClass mc, {String? selected}) => fieldRead(
        key,
        markClass: mc,
        selected: selected == null ? null : 'ABCD'.indexOf(selected),
      );

  FieldRead mcqMulti(String key, List<String> markedOptions) => fieldRead(
        key,
        markClass: MarkClass.multiple,
        zones: [
          for (final v in ['A', 'B', 'C', 'D'])
            if (markedOptions.contains(v)) BubbleZone.filled
            else BubbleZone.empty,
        ],
        means: [
          for (final v in ['A', 'B', 'C', 'D'])
            markedOptions.contains(v) ? 110.0 : 220.0,
        ],
      );

  group('MCQ fields', () {
    test('filled → chosen option, valid', () {
      final read = decoder
          .decode(fields: [mcq('q1', MarkClass.filled, selected: 'B')],
              sheetConfidence: 0.95);
      expect(read.responses['q1']!.chosen, {'B'});
      expect(read.responses['q1']!.validity, ResponseValidity.valid);
      expect(read.flags, isEmpty);
    });

    test('blank → unattempted, never a guess', () {
      final read = decoder
          .decode(fields: [mcq('q2', MarkClass.blank)], sheetConfidence: 0.95);
      expect(read.responses['q2']!.chosen, isEmpty);
      expect(read.responses['q2']!.validity, ResponseValidity.valid);
      expect(read.flags, isEmpty);
    });

    test('multiple → every clear mark carried, flagged for review', () {
      final read = decoder.decode(
        fields: [mcqMulti('q3', ['A', 'C'])],
        sheetConfidence: 0.95,
      );
      expect(read.responses['q3']!.chosen, {'A', 'C'});
      expect(read.responses['q3']!.validity, ResponseValidity.multiMarked);
      expect(read.flags, contains(SheetReadFlag.multiMarkedField));
    });

    test('probable → empty chosen, probable validity, flagged', () {
      final read = decoder
          .decode(fields: [mcq('q4', MarkClass.probable)], sheetConfidence: 0.95);
      expect(read.responses['q4']!.chosen, isEmpty);
      expect(read.responses['q4']!.validity, ResponseValidity.probable);
      expect(read.flags, contains(SheetReadFlag.probableBubblesPresent));
    });

    test('overfilled → read value kept but flagged', () {
      final read = decoder.decode(
        fields: [mcq('q5', MarkClass.overfilled, selected: 'D')],
        sheetConfidence: 0.95,
      );
      expect(read.responses['q5']!.chosen, {'D'});
      expect(read.flags, contains(SheetReadFlag.multiMarkedField));
    });
  });

  group('set code', () {
    FieldRead set(MarkClass mc, {String? selected}) => fieldRead(
          'set',
          markClass: mc,
          selected: selected == null ? null : 'ABCD'.indexOf(selected),
          blockId: 'set',
          blockType: BlockType.setCode,
        );

    test('filled set decodes to its value', () {
      final read = decoder
          .decode(fields: [set(MarkClass.filled, selected: 'A')],
              sheetConfidence: 0.95);
      expect(read.setCodeRead, 'A');
      expect(read.flags, isEmpty);
    });

    test('blank set is flagged', () {
      final read = decoder
          .decode(fields: [set(MarkClass.blank)], sheetConfidence: 0.95);
      expect(read.setCodeRead, isNull);
      expect(read.flags, contains(SheetReadFlag.setCodeBlank));
    });

    test('multi-marked set is flagged', () {
      final read = decoder
          .decode(fields: [set(MarkClass.multiple)], sheetConfidence: 0.95);
      expect(read.setCodeRead, isNull);
      expect(read.flags, contains(SheetReadFlag.setCodeMulti));
    });
  });

  group('roll decoding', () {
    test('checksum weights catch substitution and transposition', () {
      // 1..7 → 3·1+1·2+3·3+1·4+3·5+1·6+3·7 = 60 → 0.
      expect(FieldDecoder.rollChecksumOf([1, 2, 3, 4, 5, 6, 7]), 0);
      // Leading blanks weigh 0, matching the zero-padded roster form.
      expect(FieldDecoder.rollChecksumOf([null, null, 1, 2, 3, 4, 5]), 33 % 10);
      // Transposing the first two digits changes the weighted sum.
      expect(FieldDecoder.rollChecksumOf([2, 1, 3, 4, 5, 6, 7]), isNot(0));
    });

    test('a clean roll with a matching checksum decodes with no flags', () {
      final read = decoder.decode(
        fields: [
          rollColumn('roll1', '1'),
          rollColumn('roll2', '2'),
          rollColumn('roll3', '3'),
          rollColumn('roll4', '4'),
          rollColumn('roll5', '5'),
          rollColumn('roll6', '6'),
          rollColumn('roll7', '7'),
          rollColumn('roll8', '0'), // checksum
        ],
        sheetConfidence: 0.95,
      );
      expect(read.rollNoRead, '1234567');
      expect(read.flags, isEmpty);
    });

    test('checksum mismatch keeps the read but flags it', () {
      final read = decoder.decode(
        fields: [
          rollColumn('roll1', '1'),
          rollColumn('roll2', '2'),
          rollColumn('roll3', '3'),
          rollColumn('roll4', '4'),
          rollColumn('roll5', '5'),
          rollColumn('roll6', '6'),
          rollColumn('roll7', '7'),
          rollColumn('roll8', '3'), // wrong checksum
        ],
        sheetConfidence: 0.95,
      );
      expect(read.rollNoRead, '1234567');
      expect(read.flags, contains(SheetReadFlag.rollChecksumMismatch));
    });

    test('blank checksum column flags ambiguity instead of crashing', () {
      // Regression: a readable payload with an UNREADABLE checksum column
      // used to hit a null assertion (`digits[rollDigits]!`).
      final read = decoder.decode(
        fields: [
          rollColumn('roll1', '1'),
          rollColumn('roll2', '2'),
          rollColumn('roll3', '3'),
          rollColumn('roll4', '4'),
          rollColumn('roll5', '5'),
          rollColumn('roll6', '6'),
          rollColumn('roll7', '7'),
          rollColumn('roll8', null), // checksum column not bubbled
        ],
        sheetConfidence: 0.95,
      );
      expect(read.rollNoRead, '1234567');
      expect(read.flags, contains(SheetReadFlag.rollColumnAmbiguous));
      expect(
          read.flags, isNot(contains(SheetReadFlag.rollChecksumMismatch)));
    });

    test('leading blanks are legal and distinct from explicit zeros', () {
      // Unpadded '12345' + checksum 3 (weights see the blanks as 0).
      final read = decoder.decode(
        fields: [
          rollColumn('roll1', null),
          rollColumn('roll2', null),
          rollColumn('roll3', '1'),
          rollColumn('roll4', '2'),
          rollColumn('roll5', '3'),
          rollColumn('roll6', '4'),
          rollColumn('roll7', '5'),
          rollColumn('roll8', '3'),
        ],
        sheetConfidence: 0.95,
      );
      expect(read.rollNoRead, '12345');
      expect(read.flags, isEmpty);
    });

    test('an interior blank column refuses the read', () {
      final read = decoder.decode(
        fields: [
          rollColumn('roll1', '1'),
          rollColumn('roll2', null), // hole: 1_34567
          rollColumn('roll3', '3'),
          rollColumn('roll4', '4'),
          rollColumn('roll5', '5'),
          rollColumn('roll6', '6'),
          rollColumn('roll7', '7'),
          rollColumn('roll8', '0'),
        ],
        sheetConfidence: 0.95,
      );
      expect(read.rollNoRead, isNull);
      expect(read.flags, contains(SheetReadFlag.rollColumnAmbiguous));
    });

    test('a probable or multi-marked column refuses the read', () {
      for (final mc in [MarkClass.probable, MarkClass.multiple]) {
        final read = decoder.decode(
          fields: [
            rollColumn('roll1', '1'),
            rollColumn('roll2', '2'),
            rollColumn('roll3', '3'),
            rollColumn('roll4', '4'),
            fieldRead(
              'roll5',
              markClass: mc,
              blockId: 'roll',
              blockType: BlockType.rollDigits,
              values: digitValues,
            ),
            rollColumn('roll6', '6'),
            rollColumn('roll7', '7'),
            rollColumn('roll8', '0'),
          ],
          sheetConfidence: 0.95,
        );
        expect(read.rollNoRead, isNull, reason: '$mc column');
        expect(read.flags, contains(SheetReadFlag.rollColumnAmbiguous));
      }
    });

    test('an entirely blank roll is flagged, not guessed', () {
      final read = decoder.decode(
        fields: [for (var i = 1; i <= 8; i++) rollColumn('roll$i', null)],
        sheetConfidence: 0.95,
      );
      expect(read.rollNoRead, isNull);
      expect(read.flags, contains(SheetReadFlag.rollColumnAmbiguous));
    });

    test('roster membership is checked only when a roster is provided', () {
      final fields = [
        rollColumn('roll1', '9'),
        rollColumn('roll2', '9'),
        rollColumn('roll3', '9'),
        rollColumn('roll4', '9'),
        rollColumn('roll5', '9'),
        rollColumn('roll6', '9'),
        rollColumn('roll7', '9'),
        rollColumn('roll8', '9'),
      ];
      // 9·(3+1+3+1+3+1+3) = 9·15 = 135 → 5; 9 ≠ 5 → checksum mismatch too,
      // which is exactly the situation the roster check must not mask.
      final offRoster = FieldDecoder(roster: {'1234567'}).decode(
        fields: fields,
        sheetConfidence: 0.95,
      );
      expect(offRoster.flags, contains(SheetReadFlag.rollNotOnRoster));
      expect(offRoster.flags, contains(SheetReadFlag.rollChecksumMismatch));

      final noRoster = decoder.decode(fields: fields, sheetConfidence: 0.95);
      expect(noRoster.flags.contains(SheetReadFlag.rollNotOnRoster), isFalse);
    });
  });

  group('integer answers', () {
    FieldRead intCol(String key, int blockColumn, String? digit) => fieldRead(
          key,
          markClass: digit == null ? MarkClass.blank : MarkClass.filled,
          selected: digit == null ? null : digitValues.indexOf(digit),
          blockId: 'int1',
          blockType: BlockType.intDigits,
          values: digitValues,
        );

    test('columns encode through IntegerDigitsCodec', () {
      final read = decoder.decode(
        fields: [intCol('a1c1', 0, '0'), intCol('a1c2', 1, '3')],
        sheetConfidence: 0.95,
      );
      expect(read.responses['int1']!.chosen, {'0:0', '1:3'});
      expect(read.responses['int1']!.validity, ResponseValidity.valid);
      expect(read.flags, isEmpty);
    });

    test('a multi-marked column carries both digits, flagged', () {
      final read = decoder.decode(
        fields: [
          intCol('a1c1', 0, '0'),
          fieldRead(
            'a1c2',
            markClass: MarkClass.multiple,
            blockId: 'int1',
            blockType: BlockType.intDigits,
            values: digitValues,
            zones: [
              for (final d in digitValues)
                (d == '3' || d == '7') ? BubbleZone.filled : BubbleZone.empty,
            ],
            means: [
              for (final d in digitValues)
                (d == '3' || d == '7') ? 110.0 : 220.0,
            ],
          ),
        ],
        sheetConfidence: 0.95,
      );
      expect(read.responses['int1']!.chosen, {'0:0', '1:3', '1:7'});
      expect(read.responses['int1']!.validity, ResponseValidity.multiMarked);
      expect(read.flags, contains(SheetReadFlag.multiMarkedField));
    });
  });

  group('sheet-level routing', () {
    test('curl and low confidence flags route the sheet to review', () {
      final curled = decoder.decode(
        fields: [mcq('q1', MarkClass.filled, selected: 'A')],
        sheetConfidence: 0.95,
        curlDetected: true,
      );
      expect(curled.flags, contains(SheetReadFlag.curlDetected));

      final weak = decoder.decode(
        fields: [mcq('q1', MarkClass.filled, selected: 'A')],
        sheetConfidence: 0.5,
      );
      expect(weak.flags, contains(SheetReadFlag.lowConfidence));

      final ok = decoder.decode(
        fields: [mcq('q1', MarkClass.filled, selected: 'A')],
        sheetConfidence: 0.95,
      );
      expect(ok.flags, isEmpty);
    });

    test('roll and sheet confidence pass through untouched', () {
      final read = decoder.decode(
        fields: [mcq('q1', MarkClass.filled, selected: 'A')],
        sheetConfidence: 0.92,
        rollConfidence: 0.61,
      );
      expect(read.sheetConfidence, 0.92);
      expect(read.rollConfidence, 0.61);
    });
  });
}
