import 'package:omr_spec/omr_spec.dart'
    show BlockType, BubbleRect, DetectionTemplate;

import '../cv/opencv_service.dart' show CvMat, CvRectI, OpencvService;
import '../models/bubble_read.dart' show BubbleSample;

/// Stage 6: measures every bubble ROI on the warped canvas.
///
/// For each bubble in the template, the inner-70 % ROI (the printed
/// 0.25 mm outline stroke is excluded by construction) is averaged on the
/// selected single channel — lower means darker means marked. The morph
/// copy's fillRatio and strayMark arrive separately (stray-mark detection
/// runs on the CLAHE'd morphology copy, plan §3 stage 6) and are merged
/// here; until that pass exists they default, and the classifier's
/// three-zone logic degrades to intensity-only exactly as documented.
///
/// The output ordering is the template's flat block-ordered bubble list —
/// strips (a question's option run) stay contiguous slices, which the
/// threshold engine and the strip map rely on.
class BubbleReader {
  const BubbleReader({this.roiFraction = 0.70});

  /// Inner fraction of the outline the measurement ROI covers.
  final double roiFraction;

  List<BubbleSample> read(OpencvService cv, CvMat channel, DetectionTemplate template) {
    return [
      for (final b in template.bubbles)
        _measure(cv, channel, b, template.canvasWidth, template.canvasHeight),
    ];
  }

  BubbleSample _measure(
    OpencvService cv,
    CvMat channel,
    BubbleRect b,
    int canvasWidth,
    int canvasHeight,
  ) {
    final roi = b.roi(fraction: roiFraction);
    // Clamp to canvas: a warp can land a border bubble's ROI half a pixel
    // outside; OpenCV would assert on a negative or oversized rect.
    final rect = CvRectI(
      roi.x.clamp(0, canvasWidth - 1),
      roi.y.clamp(0, canvasHeight - 1),
      roi.w.clamp(1, canvasWidth),
      roi.h.clamp(1, canvasHeight),
    );
    final mean = cv.roiMean(channel, rect);
    return BubbleSample(
      fieldKey: b.fieldKey,
      blockId: b.blockId,
      blockType: _blockTypeOf(b),
      optionIndex: b.optionIndex,
      optionValue: b.optionValue,
      meanIntensity: mean,
      // Morphology-copy signals land in a later M1 increment; until then
      // every fillRatio is the conservative "fully unsaturated" and stray
      // marks are unreported — the classifier's intensity zones still work.
      fillRatio: 0,
    );
  }

  /// The template's bubbles don't carry their block type (the spec does);
  /// derive it from the field-key convention shared with the spec
  /// compilers: roll columns `roll<n>`, set `set`, everything else an MCQ
  /// question. Integer blocks ship in a later layout version.
  static BlockType _blockTypeOf(BubbleRect b) {
    if (b.fieldKey.startsWith('roll')) return BlockType.rollDigits;
    if (b.fieldKey == 'set') return BlockType.setCode;
    return BlockType.mcq;
  }
}
