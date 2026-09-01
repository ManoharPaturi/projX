import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart' show BlockType;

/// Builds a stage-6 style bubble measurement with defaults chosen to sit
/// far from the threshold (empty side) unless overridden.
BubbleSample sample(
  String fieldKey,
  int optionIndex,
  String optionValue, {
  required double mean,
  double fill = 0.5,
  bool stray = false,
  String blockId = 'mcq_c1',
  BlockType blockType = BlockType.mcq,
}) =>
    BubbleSample(
      fieldKey: fieldKey,
      blockId: blockId,
      blockType: blockType,
      optionIndex: optionIndex,
      optionValue: optionValue,
      meanIntensity: mean,
      fillRatio: fill,
      strayMark: stray,
    );

/// A [ThresholdResult] with hand-set thresholds so tests control the
/// decision boundary directly instead of going through the engine (which
/// has its own tests).
ThresholdResult thresholds({
  double global = 170,
  Map<String, double> perField = const {},
}) =>
    ThresholdResult(
      globalThreshold: global,
      globalLargestGap: 100,
      globalUsedFallback: false,
      globalStd: 30,
      strips: {
        for (final e in perField.entries)
          e.key: StripThreshold(
            threshold: e.value,
            largestGap: 100,
            confident: true,
            fromGlobal: false,
            distrusted: false,
          ),
      },
    );

/// Builds a post-classification [FieldRead] for decoder/aggregator tests.
///
/// [zones] is optional (defaults to all-empty); [selected] is the
/// preselected option index, if any.
FieldRead fieldRead(
  String fieldKey, {
  required MarkClass markClass,
  int? selected,
  List<BubbleZone> zones = const [],
  List<double> means = const [],
  List<bool> strays = const [],
  double fill = 0.5,
  double threshold = 170,
  String blockId = 'mcq_c1',
  BlockType blockType = BlockType.mcq,
  List<String> values = const ['A', 'B', 'C', 'D'],
}) {
  final bubbles = <BubbleRead>[
    for (var i = 0; i < values.length; i++)
      BubbleRead(
        sample: sample(
          fieldKey,
          i,
          values[i],
          mean: means.isEmpty ? 220 : means[i],
          fill: fill,
          stray: i < strays.length && strays[i],
          blockId: blockId,
          blockType: blockType,
        ),
        thresholdUsed: threshold,
        zone: i < zones.length ? zones[i] : BubbleZone.empty,
      ),
  ];
  return FieldRead(
    fieldKey: fieldKey,
    blockId: blockId,
    blockType: blockType,
    bubbles: bubbles,
    markClass: markClass,
    selectedOptionIndex: selected,
  );
}

const digitValues = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

/// One roll-digit column, bubbled with [digit] (or blank when `null`).
FieldRead rollColumn(String fieldKey, String? digit) => fieldRead(
      fieldKey,
      markClass: digit == null ? MarkClass.blank : MarkClass.filled,
      selected: digit == null ? null : digitValues.indexOf(digit),
      blockId: 'roll',
      blockType: BlockType.rollDigits,
      values: digitValues,
    );
