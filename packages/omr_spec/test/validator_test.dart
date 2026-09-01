import 'package:omr_spec/omr_spec.dart';
import 'package:test/test.dart';

/// Validator tests: every layout-physics rule fires with the actual mm
/// numbers, and the two presets sail through — these tests are the reason a
/// layout typo can never reach a printer.
void main() {
  group('presets are valid', () {
    test('standard90 and neet180 pass unchanged', () {
      expect(() => buildStandard90(), returnsNormally);
      expect(() => buildNeet180(), returnsNormally);
    });

    test('json roundtrip still validates', () {
      final spec = SheetSpec.fromJson(buildNeet180().toJson());
      expect(() => validateSheetSpec(spec), returnsNormally);
    });
  });

  group('rejects geometry violations', () {
    test('block overflowing the content rect', () {
      final base = buildStandard90();
      final overflow = base.fieldBlocks.map((b) {
        if (b.blockId != 'mcq_c1') return b;
        // 60 rows at 7.8mm cannot fit under a 30mm header on A4.
        return FieldBlock(
          blockId: b.blockId,
          blockType: b.blockType,
          originMm: b.originMm,
          bubblePitchMm: b.bubblePitchMm,
          rowPitchMm: b.rowPitchMm,
          direction: b.direction,
          options: b.options,
          fieldLabels: ['q1..q60'],
        );
      }).toList();
      _expectReject(
        base.copyWith(fieldBlocks: overflow),
        contains('overflows the content rect'),
      );
    });

    test('option pitch below 1.4x major axis', () {
      final base = buildStandard90();
      _expectReject(
        base.copyWith(bubbleStyle: base.bubbleStyle.copyWith(wMm: 5.8)),
        contains('bleed between neighbouring options'),
      );
    });

    test('bubble outside the 3-6mm band', () {
      final base = buildStandard90();
      _expectReject(
        base.copyWith(bubbleStyle: base.bubbleStyle.copyWith(wMm: 2.5)),
        contains('outside [3.0, 6.0]'),
      );
    });

    test('stroke outside the 0.15-0.35mm band', () {
      final base = buildStandard90();
      _expectReject(
        base.copyWith(bubbleStyle: base.bubbleStyle.copyWith(strokeMm: 0.5)),
        contains('drop out'),
      );
    });

    test('margin below 10mm', () {
      _expectReject(buildStandard90().copyWith(marginMm: 8),
          contains('marginMm 8.0 < 10.0'));
    });

    test('QR smaller than 15mm', () {
      final base = buildStandard90();
      _expectReject(
        base.copyWith(qrZone: QrZone(sizeMm: 12)),
        contains('qrZone.sizeMm 12.0 < 15.0'),
      );
    });

    test('fiducial too small relative to the bubble', () {
      final base = buildStandard90();
      _expectReject(
        base.copyWith(
          fiducials: base.fiducials.copyWith(sizeMm: 7.0),
        ),
        anyOf(contains('outside [6.0, 12.0]'), contains('2.5-3x')),
      );
    });
  });

  group('rejects structural violations', () {
    test('duplicate field keys across blocks', () {
      final base = buildStandard90();
      final dup = base.fieldBlocks.map((b) {
        if (b.blockId != 'mcq_c2') return b;
        return FieldBlock(
          blockId: b.blockId,
          blockType: b.blockType,
          originMm: b.originMm,
          bubblePitchMm: b.bubblePitchMm,
          rowPitchMm: b.rowPitchMm,
          direction: b.direction,
          options: b.options,
          fieldLabels: ['q1..q30'], // collides with mcq_c1
        );
      }).toList();
      _expectReject(base.copyWith(fieldBlocks: dup),
          contains('globally unique'));
    });

    test('section coverage gap', () {
      final base = buildStandard90();
      final sections = [
        SectionSpec(
            id: 'only', name: 'Only', subject: 'X',
            questionLabels: ['q1..q45']), // q46..q90 uncovered
      ];
      _expectReject(base.copyWith(sections: sections),
          contains('not covered by any section'));
    });

    test('section references a non-existent question', () {
      final base = buildStandard90();
      final sections = [
        ...base.sections,
        SectionSpec(
            id: 'ghost', name: 'Ghost', subject: 'X',
            questionLabels: ['q91..q95']),
      ];
      _expectReject(base.copyWith(sections: sections),
          contains('non-existent questions'));
    });

    test('roll column count disagrees with rollDigits+checksum', () {
      _expectReject(
        buildStandard90().copyWith(rollChecksum: false),
        contains('roll block has 8 columns'),
      );
    });

    test('set block values disagree with setValues', () {
      _expectReject(
        buildStandard90().copyWith(setValues: ['A', 'B', 'C']),
        contains('bubbleValues'),
      );
    });

    test('MCQ blocks off the shared row grid', () {
      final base = buildStandard90();
      final shifted = base.fieldBlocks.map((b) {
        if (b.blockId != 'mcq_c3') return b;
        return FieldBlock(
          blockId: b.blockId,
          blockType: b.blockType,
          originMm: MmPoint(b.originMm.x, b.originMm.y + 2.0),
          bubblePitchMm: b.bubblePitchMm,
          rowPitchMm: b.rowPitchMm,
          direction: b.direction,
          options: b.options,
          fieldLabels: b.fieldLabels,
        );
      }).toList();
      _expectReject(
          base.copyWith(fieldBlocks: shifted), contains('share the grid'));
    });

    test('block invading a fiducial white surround', () {
      final base = buildStandard90();
      final invading = base.fieldBlocks.map((b) {
        if (b.blockId != 'mcq_c1') return b;
        return FieldBlock(
          blockId: b.blockId,
          blockType: b.blockType,
          originMm: const MmPoint(16.0, 268.2), // inside the BL fiducial zone
          bubblePitchMm: b.bubblePitchMm,
          rowPitchMm: b.rowPitchMm,
          direction: b.direction,
          options: b.options,
          fieldLabels: ['q1..q1'],
        );
      }).toList();
      _expectReject(base.copyWith(fieldBlocks: invading),
          anyOf(contains('white surround'), contains('timing')));
    });

    test('block violating timing-track clearance', () {
      final base = buildStandard90();
      final tooClose = base.fieldBlocks.map((b) {
        if (b.blockId != 'mcq_c1') return b;
        return FieldBlock(
          blockId: b.blockId,
          blockType: b.blockType,
          originMm: MmPoint(18.0, b.originMm.y), // left edge 15.5 < zone 20.5
          bubblePitchMm: b.bubblePitchMm,
          rowPitchMm: b.rowPitchMm,
          direction: b.direction,
          options: b.options,
          fieldLabels: b.fieldLabels,
        );
      }).toList();
      _expectReject(base.copyWith(fieldBlocks: tooClose),
          anyOf(contains('timing track'), contains('timing')));
    });
  });

  group('error reporting', () {
    test('collects multiple violations, not just the first', () {
      final base = buildStandard90();
      late SpecValidationException ex;
      try {
        validateSheetSpec(base.copyWith(
          marginMm: 5,
          qrZone: const QrZone(sizeMm: 10),
        ));
        fail('expected SpecValidationException');
      } on SpecValidationException catch (e) {
        ex = e;
      }
      expect(ex.errors.length, greaterThanOrEqualTo(2));
      expect(ex.toString(), contains('marginMm'));
      expect(ex.toString(), contains('qrZone.sizeMm'));
    });
  });
}

void _expectReject(SheetSpec spec, dynamic matcher) {
  expect(
    () => validateSheetSpec(spec),
    throwsA(isA<SpecValidationException>().having(
      (e) => e.toString(),
      'message',
      matcher,
    )),
    reason: 'spec should be rejected',
  );
}
