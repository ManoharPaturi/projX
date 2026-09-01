import 'package:omr_spec/omr_spec.dart';
import 'package:test/test.dart';

void main() {
  group('FieldBlock geometry', () {
    test('vertical block: fields down, options right', () {
      const b = FieldBlock(
        blockId: 'c1',
        blockType: BlockType.mcq,
        originMm: MmPoint(24, 42),
        bubblePitchMm: 7.6,
        rowPitchMm: 7.8,
        direction: BlockDirection.vertical,
        options: 4,
        fieldLabels: ['q1..q2'],
      );

      expect(b.bubbleCenter(0, 0), const MmPoint(24, 42));
      expect(b.bubbleCenter(0, 3), const MmPoint(24 + 3 * 7.6, 42));
      expect(b.bubbleCenter(1, 0), const MmPoint(24, 42 + 7.8));
    });

    test('horizontal block: fields right, options down', () {
      const b = FieldBlock(
        blockId: 'roll',
        blockType: BlockType.rollDigits,
        originMm: MmPoint(132, 42),
        bubblePitchMm: 7.4,
        rowPitchMm: 8.5,
        direction: BlockDirection.horizontal,
        options: 10,
        fieldLabels: ['roll1..roll2'],
      );

      expect(b.bubbleCenter(0, 0), const MmPoint(132, 42));
      expect(b.bubbleCenter(0, 9), const MmPoint(132, 42 + 9 * 7.4));
      expect(b.bubbleCenter(1, 0), const MmPoint(132 + 8.5, 42));
    });

    test('extent spans outlines inclusive of bubble halves', () {
      const b = FieldBlock(
        blockId: 'c1',
        blockType: BlockType.mcq,
        originMm: MmPoint(24, 42),
        bubblePitchMm: 7.6,
        rowPitchMm: 7.8,
        direction: BlockDirection.vertical,
        options: 4,
        fieldLabels: ['q1..q30'],
      );
      final e = b.extentMm(bubbleW: 5.0, bubbleH: 3.5);
      // width = 3*7.6 + 5.0 = 27.8, height = 29*7.8 + 3.5 = 229.7
      expect(e.left, closeTo(21.5, 1e-9));
      expect(e.w, closeTo(27.8, 1e-9));
      expect(e.h, closeTo(29 * 7.8 + 3.5, 1e-9));
    });

    test('default option values by type', () {
      const mcq = FieldBlock(
        blockId: 'm',
        blockType: BlockType.mcq,
        originMm: MmPoint(0, 0),
        bubblePitchMm: 8,
        rowPitchMm: 8,
        direction: BlockDirection.vertical,
        fieldLabels: ['q1'],
      );
      expect(mcq.optionValues, ['A', 'B', 'C', 'D']);

      const roll = FieldBlock(
        blockId: 'r',
        blockType: BlockType.rollDigits,
        originMm: MmPoint(0, 0),
        bubblePitchMm: 8,
        rowPitchMm: 8,
        direction: BlockDirection.horizontal,
        options: 10,
        fieldLabels: ['roll1'],
      );
      expect(roll.optionValues, hasLength(10));
      expect(roll.optionValues.first, '0');
      expect(roll.optionValues.last, '9');
    });

    test('json roundtrip', () {
      const b = FieldBlock(
        blockId: 'set',
        blockType: BlockType.setCode,
        originMm: MmPoint(147.9, 132),
        bubblePitchMm: 7.6,
        rowPitchMm: 7.8,
        direction: BlockDirection.vertical,
        options: 4,
        bubbleValues: ['A', 'B', 'C', 'D'],
        fieldLabels: ['set'],
      );
      final b2 = FieldBlock.fromJson(b.toJson());
      expect(b2.blockId, b.blockId);
      expect(b2.bubbleCenter(0, 2), b.bubbleCenter(0, 2));
      expect(b2.bubbleValues, b.bubbleValues);
    });
  });
}
