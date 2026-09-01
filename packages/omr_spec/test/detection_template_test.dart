import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:omr_spec/omr_spec.dart';
import 'package:test/test.dart';

void main() {
  group('compileDetectionTemplate — Preset A', () {
    final spec = buildStandard90();
    final t = compileDetectionTemplate(spec);

    test('canonical canvas: 8 px/mm on portrait A4', () {
      expect(t.canvasWidth, 210 * 8);
      expect(t.canvasHeight, 297 * 8);
      expect(pxPerMm, 8.0);
    });

    test('bubble inventory: 90x4 MCQ + 8x10 roll + 4 set = 448', () {
      expect(t.bubbles, hasLength(90 * 4 + 8 * 10 + 4));
    });

    test('bubble geometry equals spec mm x 8, exactly', () {
      final c1 = spec.firstMcqBlock!;
      final q1A = t.bubbles.firstWhere((b) =>
          b.fieldKey == 'q1' && b.optionIndex == 0);
      expect(q1A.centerX, c1.originMm.x * pxPerMm);
      expect(q1A.centerY, c1.originMm.y * pxPerMm);
      expect(q1A.optionValue, 'A');

      // A 5.0x3.5mm bubble -> 40x28 px; the major axis is the proven 40.
      expect(q1A.w, spec.bubbleStyle.wMm * pxPerMm);
      expect(q1A.w, 40.0);
    });

    test('measurement ROI is the inner 70% excluding the stroke', () {
      final b = t.bubbles.first;
      final roi = b.roi();
      expect(roi.w, closeTo(28, 0.5)); // 40 * 0.7
      expect(roi.h, closeTo(19.6, 0.5)); // 28 * 0.7
      expect(roi.x + roi.w / 2, closeTo(b.centerX, 0.5));
    });

    test('field keys map to contiguous slices', () {
      final q17 = t.bubbles
          .where((b) => b.fieldKey == 'q17')
          .map((b) => b.optionIndex)
          .toList();
      expect(q17, [0, 1, 2, 3]);
      final roll3 = t.bubbles
          .where((b) => b.fieldKey == 'roll3')
          .map((b) => b.optionValue)
          .toList();
      expect(roll3, ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']);
    });

    test('key inventories', () {
      expect(t.rollFieldKeys, hasLength(8));
      expect(t.rollFieldKeys.last, 'roll8');
      expect(t.setFieldKey, 'set');
      expect(t.questionFieldKeys, hasLength(90));
      expect(t.questionFieldKeys.first, 'q1');
      expect(t.questionFieldKeys.last, 'q90');
    });

    test('four fiducial anchors, exactly one L', () {
      expect(t.fiducials, hasLength(4));
      expect(t.fiducials.where((f) => f.isAltAnchor), hasLength(1));
      expect(t.fiducials.firstWhere((f) => f.isAltAnchor).corner, 'bl');
      // TL anchor at (12mm, 12mm) -> (96, 96) px
      final tl = t.fiducials.firstWhere((f) => f.corner == 'tl');
      expect(tl.centerX, 12 * 8);
      expect(tl.centerY, 12 * 8);
      expect(tl.size, 9 * 8);
    });

    test('timing bars: one per MCQ row, derived not authored', () {
      expect(t.timingBars, hasLength(30));
      final first = t.timingBars.first;
      expect(first.y + first.h / 2, closeTo(spec.firstMcqBlock!.originMm.y * 8, 0.01));
      final last = t.timingBars.last;
      expect(last.y + last.h / 2,
          closeTo((spec.firstMcqBlock!.originMm.y + 29 * 7.8) * 8, 0.01));
      expect(first.x, 10 * 8); // hugs the left margin
    });

    test('qr rect sits inside the page', () {
      expect(t.qrRect.w, 16 * 8);
      expect(t.qrRect.x + t.qrRect.w, lessThan(t.canvasWidth));
      expect(t.qrRect.y, 10 * 8);
      expect(t.qrPayload, 'OMR1:std90:v1');
    });

    test('specHash is sha256 of the canonical spec JSON', () {
      final manual =
          crypto.sha256.convert(utf8.encode(spec.canonicalJson())).toString();
      expect(t.specHash, manual);
      expect(t.specHash, hasLength(64));
    });

    test('capture-resolution floor for 3.5mm bubbles', () {
      // 40px on the MINOR axis -> 11.43 px/mm -> ~2400px across a 210mm sheet.
      expect(t.minPxPerMmOnCapture, closeTo(40 / 3.5, 1e-9));
    });

    test('json roundtrip preserves every bubble and anchor', () {
      final t2 = DetectionTemplate.fromJsonString(t.toJsonString());
      expect(t2.canvasWidth, t.canvasWidth);
      expect(t2.bubbles, hasLength(t.bubbles.length));
      expect(t2.bubbles.first.fieldKey, t.bubbles.first.fieldKey);
      expect(t2.bubbles.first.centerX, t.bubbles.first.centerX);
      expect(t2.fiducials.length, 4);
      expect(t2.timingBars.length, t.timingBars.length);
      expect(t2.qrPayload, t.qrPayload);
      expect(t2.minPxPerMmOnCapture, t.minPxPerMmOnCapture);
      expect(t2.specHash, t.specHash);
    });
  });

  group('compileDetectionTemplate — Preset B', () {
    final spec = buildNeet180();
    final t = compileDetectionTemplate(spec);

    test('bubble inventory: 180x4 + 8x10 + 4 = 804', () {
      expect(t.bubbles, hasLength(180 * 4 + 8 * 10 + 4));
      expect(t.questionFieldKeys, hasLength(180));
    });

    test('dense bubbles are 32px on the major axis', () {
      expect(t.bubbles.first.w, 4.0 * 8);
      // capture floor rises accordingly: 40px / 3.0mm minor axis
      expect(t.minPxPerMmOnCapture, closeTo(40 / 3.0, 1e-9));
    });

    test('timing bars follow the 45-row grid', () {
      expect(t.timingBars, hasLength(45));
    });
  });
}
