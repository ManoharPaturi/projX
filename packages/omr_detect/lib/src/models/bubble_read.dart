import 'package:omr_spec/omr_spec.dart' show BlockType;

/// Three-zone verdict for ONE bubble, relative to its strip threshold
/// (stage 8). The zones are the distance bands of the strip threshold:
/// outside [ThresholdConfig.zoneBand] on the dark side is [filled], outside
/// on the light side is [empty], inside the band is [probable].
enum BubbleZone { filled, empty, probable }

/// Field-level verdict (the Addmen taxonomy the review queue displays).
///
/// [multiple] and [blank] are row states, not bubble states — which is why
/// this lives on [FieldRead], not on individual bubbles.
enum MarkClass {
  /// Exactly one bubble clearly filled — the good case.
  filled,

  /// No bubble filled and none probable — an unattempted row.
  blank,

  /// At least one bubble inside the uncertain band (or one filled + one
  /// probable) — routed to human review.
  probable,

  /// Two or more bubbles filled — never auto-resolved; review decides.
  multiple,

  /// A single mark whose fill saturates the ROI (pen through paper / heavy
  /// scribble) — the ROI reading is suspect even though the intent is clear.
  overfilled,
}

/// Stage-6 measurement of one bubble ROI — what the reader extracts from the
/// warped canvas. Pure data; no classification.
class BubbleSample {
  const BubbleSample({
    required this.fieldKey,
    required this.blockId,
    required this.blockType,
    required this.optionIndex,
    required this.optionValue,
    required this.meanIntensity,
    required this.fillRatio,
    this.strayMark = false,
  });

  /// Globally-unique field key (`q17`, `roll3`, `set`) — the join key shared
  /// with the detection template and the drift layer.
  final String fieldKey;

  /// Owning block (`mcq_col1`, `roll`, `set`).
  final String blockId;

  final BlockType blockType;

  /// 0-based option position inside the field (option-axis order).
  final int optionIndex;

  /// Value this bubble represents: `'A'`..`'E'` for MCQ/set, `'0'`..`'9'`
  /// for digit grids — identical to the detection template's optionValues.
  final String optionValue;

  /// Mean intensity 0..255 of the inner-70 % ROI on the selected channel
  /// (lower = darker = marked).
  final double meanIntensity;

  /// Dark-pixel fraction 0..1 of the ROI, measured on the morphology copy —
  /// the saturation signal behind [MarkClass.overfilled].
  final double fillRatio;

  /// Whether the morphology copy found a stray mark overlapping this ROI
  /// (tick outside the bubble bleeding in, erasure ghost, fold shadow).
  final bool strayMark;

  @override
  String toString() =>
      '$fieldKey[$optionValue] mean=$meanIntensity fill=$fillRatio'
      '${strayMark ? ' stray' : ''}';
}

/// A classified bubble: the sample plus the strip threshold it was judged
/// against, its zone, and (after aggregation) its confidence.
class BubbleRead {
  const BubbleRead({
    required this.sample,
    required this.thresholdUsed,
    required this.zone,
    this.confidence = 0,
  });

  final BubbleSample sample;
  final double thresholdUsed;
  final BubbleZone zone;

  /// 0..1, set by the confidence aggregator; 0 until then.
  final double confidence;

  BubbleRead copyWith({BubbleZone? zone, double? confidence}) => BubbleRead(
        sample: sample,
        thresholdUsed: thresholdUsed,
        zone: zone ?? this.zone,
        confidence: confidence ?? this.confidence,
      );

  @override
  String toString() =>
      '${sample.fieldKey}[${sample.optionValue}] ${zone.name} '
      'conf=$confidence';
}

/// One field (question / digit column / set code) after classification.
class FieldRead {
  const FieldRead({
    required this.fieldKey,
    required this.blockId,
    required this.blockType,
    required this.bubbles,
    required this.markClass,
    this.selectedOptionIndex,
    this.confidence = 0,
  });

  final String fieldKey;
  final String blockId;
  final BlockType blockType;

  /// Ordered by optionIndex.
  final List<BubbleRead> bubbles;

  final MarkClass markClass;

  /// The selected option when the verdict is unambiguous enough to preselect
  /// it in the review UI; `null` for blank/probable-only rows. NEVER a
  /// guess — the unmarked-row floor means we argmax nothing.
  final int? selectedOptionIndex;

  /// 0..1, set by the confidence aggregator; 0 until then.
  final double confidence;

  /// The option VALUE of the selected bubble, or `null`.
  String? get selectedOptionValue {
    final i = selectedOptionIndex;
    if (i == null || i < 0 || i >= bubbles.length) return null;
    return bubbles[i].sample.optionValue;
  }

  FieldRead copyWith({
    List<BubbleRead>? bubbles,
    MarkClass? markClass,
    int? selectedOptionIndex,
    double? confidence,
  }) =>
      FieldRead(
        fieldKey: fieldKey,
        blockId: blockId,
        blockType: blockType,
        bubbles: bubbles ?? this.bubbles,
        markClass: markClass ?? this.markClass,
        selectedOptionIndex: selectedOptionIndex ?? this.selectedOptionIndex,
        confidence: confidence ?? this.confidence,
      );

  @override
  String toString() =>
      '$fieldKey: ${markClass.name}'
      '${selectedOptionValue != null ? '($selectedOptionValue)' : ''} '
      'conf=$confidence';
}
