import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart';

/// Stage 6 against a synthetic warped canvas: the reader must average the
/// inner-70 % ROI of every template bubble in template order, with marked
/// bubbles dark and unmarked ones paper-bright.
void main() {
  final cv = OpencvDartImpl();
  final template = compileDetectionTemplate(buildStandard90());

  test('marked bubbles read dark, unmarked bright, in template order', () {
    final w = template.canvasWidth, h = template.canvasHeight;
    final bytes = Uint8List(w * h);
    bytes.fillRange(0, bytes.length, 235); // paper
    // Mark q1='B' and q2='D': ink the inner ROI of those bubbles only —
    // a deliberately smaller blob than the outline, as a real pen dot is.
    void ink(String fieldKey, String optionValue) {
      final b = template.bubbles.firstWhere((b) =>
          b.fieldKey == fieldKey && b.optionValue == optionValue);
      final roi = b.roi(fraction: 0.72);
      for (var y = roi.y; y < roi.y + roi.h; y++) {
        bytes.fillRange(y * w + roi.x, y * w + roi.x + roi.w, 18);
      }
    }

    ink('q1', 'B');
    ink('q2', 'D');

    final canvas = cv.grayFromBytes(w, h, bytes);
    addTearDown(() => cv.dispose(canvas));

    final samples = BubbleReader().read(cv, canvas, template);

    expect(samples.length, template.bubbles.length,
        reason: 'one sample per template bubble, block order preserved');
    for (var i = 0; i < samples.length; i++) {
      expect(samples[i].fieldKey, template.bubbles[i].fieldKey);
      expect(samples[i].optionIndex, template.bubbles[i].optionIndex);
    }

    double meanOf(String fieldKey, String optionValue) => samples
        .firstWhere((s) =>
            s.fieldKey == fieldKey && s.optionValue == optionValue)
        .meanIntensity;

    expect(meanOf('q1', 'B'), lessThan(45), reason: 'inked bubble must be dark');
    expect(meanOf('q1', 'A'), greaterThan(200),
        reason: 'neighbouring option stays paper-bright');
    expect(meanOf('q2', 'D'), lessThan(45));
    // Deep in the sheet, far from any mark: still paper.
    final lastQ = template.questionFieldKeys.last;
    expect(meanOf(lastQ, 'A'), greaterThan(200));
  });

  test('roll and set fields carry their block types', () {
    final w = template.canvasWidth, h = template.canvasHeight;
    final canvas = cv.grayFromBytes(w, h, Uint8List(w * h));
    addTearDown(() => cv.dispose(canvas));

    final samples = BubbleReader().read(cv, canvas, template);
    final byKey = <String, BlockType>{};
    for (final s in samples) {
      byKey.putIfAbsent(s.fieldKey, () => s.blockType);
    }
    expect(byKey['roll1'], BlockType.rollDigits);
    expect(byKey['set'], BlockType.setCode);
    expect(byKey['q1'], BlockType.mcq);
  });
}
