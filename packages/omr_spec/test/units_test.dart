import 'package:omr_spec/omr_spec.dart';
import 'package:test/test.dart';

void main() {
  group('MmPoint', () {
    test('arithmetic', () {
      const a = MmPoint(10, 20);
      const b = MmPoint(1, 2);
      expect((a + b).x, 11);
      expect((a + b).y, 22);
      expect((a - b).x, 9);
      expect((a - b).y, 18);
    });
  });

  group('MmRect', () {
    const r = MmRect(10, 20, 30, 40);

    test('edges and centre', () {
      expect(r.left, 10);
      expect(r.top, 20);
      expect(r.right, 40);
      expect(r.bottom, 60);
      expect(r.centerX, 25);
      expect(r.centerY, 40);
    });

    test('inflate grows symmetrically and negative shrinks', () {
      expect(r.inflate(5).left, 5);
      expect(r.inflate(5).w, 40);
      expect(r.inflate(-5).right, 35);
    });

    test('contains', () {
      expect(r.contains(const MmRect(11, 21, 28, 38)), isTrue);
      expect(r.contains(const MmRect(9, 21, 28, 38)), isFalse);
      expect(r.contains(r), isTrue); // closed on its own boundary
    });

    test('intersects', () {
      expect(r.intersects(const MmRect(35, 55, 10, 10)), isTrue);
      expect(r.intersects(const MmRect(41, 20, 5, 5)), isFalse);
      expect(r.intersects(const MmRect(10, 60, 30, 5)), isFalse); // touches
    });
  });

  group('expandLabels', () {
    test('expands ascending ranges with zero padding', () {
      expect(expandLabels(['q1..q3']), ['q1', 'q2', 'q3']);
      expect(expandLabels(['d01..d03']), ['d01', 'd02', 'd03']);
    });

    test('plain tokens pass through in order', () {
      expect(expandLabels(['set', 'q1', 'q2']), ['set', 'q1', 'q2']);
    });

    test('mixes ranges and tokens', () {
      expect(expandLabels(['q1..q2', 'set']), ['q1', 'q2', 'set']);
    });

    test('rejects prefix mismatch', () {
      expect(() => expandLabels(['a1..b3']), throwsFormatException);
    });

    test('rejects descending ranges', () {
      expect(() => expandLabels(['q5..q1']), throwsFormatException);
    });
  });
}
