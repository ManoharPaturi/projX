import '../models/bubble_read.dart';
import '../thresholds/threshold_config.dart';
import '../thresholds/threshold_engine.dart';

/// Stage 8: judges every measured bubble against its strip threshold and
/// rolls each field's bubbles into one [MarkClass] verdict.
///
/// The three zones are distance bands of the threshold
/// ([ThresholdConfig.zoneBand], grey levels): darker than `T − band` is
/// filled, lighter than `T + band` is empty, the band between is PROBABLE.
/// Two invariants outrank the zones themselves:
///
/// * **The unmarked-row floor** — a row with no dark bubble is BLANK, never
///   an argmax over faint differences. A guessed option would silently turn
///   an unattempted question into a wrong answer (and, with negative
///   marking, into a penalty).
/// * **MULTIPLE is never resolved here** — two clear marks is a human
///   decision (or a multi-correct key); the classifier only reports it.
class BubbleClassifier {
  const BubbleClassifier({this.config = const ThresholdConfig()});

  final ThresholdConfig config;

  /// [samples] may arrive in any order; fields are grouped and emitted in
  /// first-appearance order (block order) and each field's bubbles are
  /// sorted by optionIndex.
  List<FieldRead> classify(
    List<BubbleSample> samples,
    ThresholdResult thresholds,
  ) {
    final fieldOrder = <String>[];
    final byField = <String, List<BubbleSample>>{};
    for (final sample in samples) {
      byField
          .putIfAbsent(sample.fieldKey, () {
            fieldOrder.add(sample.fieldKey);
            return <BubbleSample>[];
          })
          .add(sample);
    }

    return [
      for (final key in fieldOrder)
        _classifyField(key, byField[key]!, thresholds),
    ];
  }

  FieldRead _classifyField(
    String fieldKey,
    List<BubbleSample> samples,
    ThresholdResult thresholds,
  ) {
    final ordered = [...samples]
      ..sort((a, b) => a.optionIndex.compareTo(b.optionIndex));
    final first = ordered.first;
    // A field absent from the strip map cannot normally happen (both derive
    // from the same sample set), but a missing entry must still classify —
    // against the global threshold rather than crashing the pipeline.
    final threshold =
        thresholds.strips[fieldKey]?.threshold ?? thresholds.globalThreshold;

    final bubbles = <BubbleRead>[];
    var filledCount = 0;
    var probableCount = 0;
    for (final sample in ordered) {
      final zone = _zone(sample.meanIntensity, threshold);
      if (zone == BubbleZone.filled) filledCount++;
      if (zone == BubbleZone.probable) probableCount++;
      bubbles.add(BubbleRead(
        sample: sample,
        thresholdUsed: threshold,
        zone: zone,
      ));
    }

    MarkClass markClass;
    int? selected;
    if (filledCount >= 2) {
      markClass = MarkClass.multiple;
    } else if (filledCount == 1) {
      if (probableCount > 0) {
        // One clear mark plus one in the band: probably an erasure ghost or
        // a faint second mark — neither is safe to auto-resolve.
        markClass = MarkClass.probable;
      } else {
        final index =
            bubbles.indexWhere((b) => b.zone == BubbleZone.filled);
        final read = bubbles[index];
        selected = index;
        markClass = read.sample.fillRatio >= config.overfillRatio
            ? MarkClass.overfilled
            : MarkClass.filled;
      }
    } else if (probableCount > 0) {
      markClass = MarkClass.probable;
    } else {
      markClass = MarkClass.blank;
    }

    return FieldRead(
      fieldKey: fieldKey,
      blockId: first.blockId,
      blockType: first.blockType,
      bubbles: bubbles,
      markClass: markClass,
      selectedOptionIndex: selected,
    );
  }

  BubbleZone _zone(double mean, double threshold) {
    if (mean < threshold - config.zoneBand) return BubbleZone.filled;
    if (mean > threshold + config.zoneBand) return BubbleZone.empty;
    return BubbleZone.probable;
  }
}
