import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart' show BlockType;
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const aggregator = ConfidenceAggregator();

  FieldRead good(String key, {String option = 'A'}) => fieldRead(
        key,
        markClass: MarkClass.filled,
        selected: 'ABCD'.indexOf(option),
        zones: [
          BubbleZone.filled,
          BubbleZone.empty,
          BubbleZone.empty,
          BubbleZone.empty,
        ],
        means: [110, 220, 222, 218],
      );

  test('bubble confidence is 1 beyond one band width, 0 at the band edge',
      () {
    // T=170, band=12: 110 is 60 away → 1; 158 is 12 away → 0; 164 is 6
    // away → 0; 200 is 30 away → 1.
    final read = BubbleRead(
      sample: sample('q1', 0, 'A', mean: 110),
      thresholdUsed: 170,
      zone: BubbleZone.filled,
    );
    final near = BubbleRead(
      sample: sample('q1', 1, 'B', mean: 158),
      thresholdUsed: 170,
      zone: BubbleZone.probable,
    );
    final mid = BubbleRead(
      sample: sample('q1', 2, 'C', mean: 164),
      thresholdUsed: 170,
      zone: BubbleZone.probable,
    );
    final light = BubbleRead(
      sample: sample('q1', 3, 'D', mean: 200),
      thresholdUsed: 170,
      zone: BubbleZone.empty,
    );

    expect(aggregator.bubbleConfidence(read), closeTo(1, 1e-9));
    expect(aggregator.bubbleConfidence(near), 0);
    expect(aggregator.bubbleConfidence(mid), 0);
    expect(aggregator.bubbleConfidence(light), closeTo(1, 1e-9));
  });

  test('a stray mark multiplies bubble confidence by the stray penalty', () {
    final clean = BubbleRead(
      sample: sample('q1', 0, 'A', mean: 110),
      thresholdUsed: 170,
      zone: BubbleZone.filled,
    );
    final stray = BubbleRead(
      sample: sample('q1', 0, 'A', mean: 110, stray: true),
      thresholdUsed: 170,
      zone: BubbleZone.filled,
    );

    expect(aggregator.bubbleConfidence(stray),
        closeTo(aggregator.bubbleConfidence(clean) * 0.7, 1e-9));
  });

  test('field confidence is the weakest bubble, minus class penalties', () {
    // Weakest bubble (110 vs T=170) has confidence 1, so the class penalty
    // is all that remains.
    final filled = fieldRead(
      'q1',
      markClass: MarkClass.filled,
      selected: 0,
      zones: [
        BubbleZone.filled,
        BubbleZone.empty,
        BubbleZone.empty,
        BubbleZone.empty,
      ],
      means: [110, 200, 202, 204],
    );
    final probable = fieldRead(
      'q2',
      markClass: MarkClass.probable,
      zones: [
        BubbleZone.probable,
        BubbleZone.empty,
        BubbleZone.empty,
        BubbleZone.empty,
      ],
      means: [110, 200, 202, 204],
    );
    final multi = fieldRead(
      'q3',
      markClass: MarkClass.multiple,
      zones: [
        BubbleZone.filled,
        BubbleZone.filled,
        BubbleZone.empty,
        BubbleZone.empty,
      ],
      means: [110, 112, 200, 202],
    );

    final assessed = aggregator.assess([filled, probable, multi]).fields;
    expect(assessed[0].confidence, closeTo(1, 1e-9));
    expect(assessed[1].confidence, closeTo(0.75, 1e-9));
    expect(assessed[2].confidence, closeTo(0.5, 1e-9));
  });

  test('sheet confidence caps at 0.95 for a flawless read', () {
    final fields = [for (var i = 0; i < 5; i++) good('q$i')];
    final assessment = aggregator.assess(fields);
    expect(assessment.sheetConfidence, closeTo(0.95, 1e-9));
  });

  test('registration quality flows into the sheet confidence', () {
    final fields = [for (var i = 0; i < 5; i++) good('q$i')];

    var assessment = aggregator.assess(
      fields,
      registration: const RegistrationQuality(fiducialScores: [0.98, 0.82]),
    );
    expect(assessment.sheetConfidence, closeTo(0.82, 1e-9));

    assessment = aggregator.assess(
      fields,
      registration: const RegistrationQuality(timingResidualRatio: 0.5),
    );
    expect(assessment.sheetConfidence, closeTo(0.5, 1e-9));

    assessment = aggregator.assess(
      fields,
      registration: const RegistrationQuality(confidenceCap: 0.85),
    );
    expect(assessment.sheetConfidence, closeTo(0.85, 1e-9));

    // A curled sheet (ratio > 1) clamps to 0, guaranteeing review.
    assessment = aggregator.assess(
      fields,
      registration: const RegistrationQuality(timingResidualRatio: 1.5),
    );
    expect(assessment.sheetConfidence, 0);
  });

  test('the weaker half wins: median is the lower median', () {
    final mixed = [
      good('q1'),
      good('q2'),
      // Two probable fields drag the lower median below 1.
      fieldRead('q3', markClass: MarkClass.probable),
      fieldRead('q4', markClass: MarkClass.probable),
    ];
    final assessment = aggregator.assess(mixed);
    // Probable field conf 0.75 → lower median 0.75.
    expect(assessment.sheetConfidence, closeTo(0.75, 1e-9));
  });

  test('roll confidence is the weakest roll digit, ignoring MCQ fields', () {
    final fields = [
      good('q1'),
      fieldRead(
        'roll1',
        markClass: MarkClass.filled,
        selected: 1,
        blockId: 'roll',
        blockType: BlockType.rollDigits,
        values: digitValues,
        zones: [
          BubbleZone.empty,
          BubbleZone.filled,
          ...List.filled(8, BubbleZone.empty),
        ],
        means: [
          200,
          110,
          ...List.filled(8, 210),
        ],
      ),
      fieldRead(
        'roll2',
        markClass: MarkClass.filled,
        selected: 2,
        blockId: 'roll',
        blockType: BlockType.rollDigits,
        values: digitValues,
        zones: [
          BubbleZone.empty,
          BubbleZone.empty,
          BubbleZone.filled,
          ...List.filled(7, BubbleZone.empty),
        ],
        means: [
          200,
          202,
          150, // 20 from T=170 → (20-12)/12 = 0.667
          ...List.filled(7, 210),
        ],
      ),
    ];

    final assessment = aggregator.assess(fields);
    expect(assessment.rollConfidence, closeTo(2 / 3, 0.01));
  });

  test('empty input assesses to a confident, roll-less sheet', () {
    final assessment = aggregator.assess(const []);
    expect(assessment.sheetConfidence, closeTo(0.95, 1e-9));
    expect(assessment.rollConfidence, 1);
  });
}
