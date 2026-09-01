import 'package:omr_detect/omr_detect.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const classifier = BubbleClassifier();

  test('a clear single mark classifies filled with that option selected',
      () {
    final reads = classifier.classify([
      sample('q1', 0, 'A', mean: 220),
      sample('q1', 1, 'B', mean: 110),
      sample('q1', 2, 'C', mean: 218),
      sample('q1', 3, 'D', mean: 222),
    ], thresholds());

    final field = reads.single;
    expect(field.markClass, MarkClass.filled);
    expect(field.selectedOptionValue, 'B');
    expect(field.bubbles[1].zone, BubbleZone.filled);
    expect(field.bubbles.map((b) => b.zone), contains(BubbleZone.empty));
  });

  test('a row with no dark bubble is blank — never an argmax guess', () {
    final reads = classifier.classify([
      for (var i = 0; i < 4; i++)
        sample('q2', i, 'ABCD'[i], mean: 200 + i * 5),
    ], thresholds());

    expect(reads.single.markClass, MarkClass.blank);
    expect(reads.single.selectedOptionIndex, isNull);
  });

  test('two clear marks are multiple and select nothing', () {
    final reads = classifier.classify([
      sample('q3', 0, 'A', mean: 110),
      sample('q3', 1, 'B', mean: 222),
      sample('q3', 2, 'C', mean: 105),
      sample('q3', 3, 'D', mean: 220),
    ], thresholds());

    expect(reads.single.markClass, MarkClass.multiple);
    expect(reads.single.selectedOptionIndex, isNull);
  });

  test('a mean inside the band is probable', () {
    // T=170, band=12: |165-170| = 5 < 12.
    final reads = classifier.classify([
      sample('q4', 0, 'A', mean: 165),
      sample('q4', 1, 'B', mean: 220),
      sample('q4', 2, 'C', mean: 222),
      sample('q4', 3, 'D', mean: 218),
    ], thresholds());

    expect(reads.single.markClass, MarkClass.probable);
    expect(reads.single.bubbles[0].zone, BubbleZone.probable);
  });

  test('one clear mark plus one in the band is probable, not filled', () {
    final reads = classifier.classify([
      sample('q5', 0, 'A', mean: 108),
      sample('q5', 1, 'B', mean: 160),
      sample('q5', 2, 'C', mean: 220),
      sample('q5', 3, 'D', mean: 222),
    ], thresholds());

    expect(reads.single.markClass, MarkClass.probable);
    expect(reads.single.selectedOptionIndex, isNull);
  });

  test('a saturating single mark is overfilled but keeps its selection', () {
    final reads = classifier.classify([
      sample('q6', 0, 'A', mean: 220),
      sample('q6', 1, 'B', mean: 30, fill: 0.97),
      sample('q6', 2, 'C', mean: 218),
      sample('q6', 3, 'D', mean: 222),
    ], thresholds());

    expect(reads.single.markClass, MarkClass.overfilled);
    expect(reads.single.selectedOptionValue, 'B');
  });

  test('fields group in first-appearance order, bubbles by optionIndex', () {
    // Deliberately interleaved and unsorted input.
    final reads = classifier.classify([
      sample('q8', 3, 'D', mean: 220),
      sample('q7', 2, 'C', mean: 110),
      sample('q8', 0, 'A', mean: 108),
      sample('q7', 0, 'A', mean: 222),
    ], thresholds());

    expect(reads.map((f) => f.fieldKey), ['q8', 'q7']);
    expect(reads[0].bubbles.map((b) => b.sample.optionIndex), [0, 3]);
    expect(reads[0].markClass, MarkClass.filled);
    expect(reads[1].markClass, MarkClass.filled);
    expect(reads[1].selectedOptionValue, 'C');
  });

  test('a field missing from the strip map falls back to the global', () {
    final reads = classifier.classify([
      sample('q9', 0, 'A', mean: 110),
      sample('q9', 1, 'B', mean: 220),
      sample('q9', 2, 'C', mean: 222),
      sample('q9', 3, 'D', mean: 218),
    ], thresholds(global: 170)); // no per-field entry for q9

    expect(reads.single.bubbles.first.thresholdUsed, 170);
    expect(reads.single.markClass, MarkClass.filled);
  });

  test('per-field thresholds are used, not the global', () {
    // Under the global 170, a mean of 150 lands in the FILLED zone (< 158);
    // this field's own strip says 120, putting it EMPTY (> 132). Which
    // verdict comes out proves which threshold was consulted.
    final reads = classifier.classify([
      sample('q10', 0, 'A', mean: 150),
      sample('q10', 1, 'B', mean: 240),
      sample('q10', 2, 'C', mean: 242),
      sample('q10', 3, 'D', mean: 238),
    ], thresholds(perField: {'q10': 120}));

    expect(reads.single.bubbles.first.thresholdUsed, 120);
    expect(reads.single.bubbles.first.zone, BubbleZone.empty);
    expect(reads.single.markClass, MarkClass.blank);
  });
}
