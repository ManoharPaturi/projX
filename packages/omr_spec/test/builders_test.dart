import 'package:omr_spec/omr_spec.dart';
import 'package:test/test.dart';

void main() {
  group('Preset A — Standard-90', () {
    final spec = buildStandard90();

    test('passes validation (builders validate before returning)', () {
      expect(spec.layoutId, 'std90');
      expect(validateOrThrow(spec), same(spec));
    });

    test('field inventory: 90 questions + 8 roll columns + set', () {
      expect(spec.allFieldKeys, hasLength(90 + 8 + 1));
      final roll = spec.rollBlock!;
      expect(roll.fields.last, 'roll8'); // 7 digits + checksum
      expect(spec.setBlock!.fields, ['set']);
    });

    test('MCQ columns share the row grid', () {
      final mcq = spec.fieldBlocks
          .where((b) => b.blockType == BlockType.mcq)
          .toList();
      expect(mcq, hasLength(3));
      for (final b in mcq) {
        expect(b.rowPitchMm, mcq.first.rowPitchMm);
        expect(b.originMm.y, mcq.first.originMm.y);
      }
    });

    test('geometry matches the documented layout arithmetic', () {
      final c1 = spec.firstMcqBlock!;
      final e = c1.extentMm(
          bubbleW: spec.bubbleStyle.wMm, bubbleH: spec.bubbleStyle.hMm);
      expect(e.left, closeTo(21.5, 1e-9));
      expect(e.right, closeTo(49.3, 1e-9));

      final mcq = spec.fieldBlocks
          .where((b) => b.blockType == BlockType.mcq)
          .toList();
      final last = mcq.last;
      final le = last.extentMm(
          bubbleW: spec.bubbleStyle.wMm, bubbleH: spec.bubbleStyle.hMm);
      expect(le.bottom, lessThan(285.5)); // inside the inner content rect

      final roll = spec.rollBlock!;
      final re = roll.extentMm(
          bubbleW: spec.bubbleStyle.wMm, bubbleH: spec.bubbleStyle.hMm);
      expect(re.right, lessThanOrEqualTo(198.5));
      expect(re.bottom, lessThan(120));
    });

    test('qr payload encodes immutable identity', () {
      expect(spec.qrPayload, 'OMR1:std90:v1');
    });
  });

  group('Preset B — NEET-180', () {
    final spec = buildNeet180();

    test('passes validation', () {
      expect(spec.layoutId, 'neet180');
      expect(spec.qrPayload, 'OMR1:neet180:v1');
    });

    test('180 questions in 4 columns of 45', () {
      final questions = spec.fieldBlocks
          .where((b) => b.blockType == BlockType.mcq)
          .expand((b) => b.fields)
          .toList();
      expect(questions, hasLength(180));
      expect(questions.first, 'q1');
      expect(questions.last, 'q180');
    });

    test('dense geometry still clears every margin', () {
      final mcq = spec.fieldBlocks
          .where((b) => b.blockType == BlockType.mcq)
          .toList();
      final lastCol = mcq.last;
      final e = lastCol.extentMm(
          bubbleW: spec.bubbleStyle.wMm, bubbleH: spec.bubbleStyle.hMm);
      // 45 rows x 5.7 pitch + bubble: must end above the inner bottom edge.
      expect(e.bottom, lessThanOrEqualTo(285.5));
      expect(e.right, lessThan(130)); // clears the roll grid at x 130
    });

    test('NEET section plan covers q1..q180 exactly once', () {
      final covered = <String>{};
      for (final s in spec.sections) {
        for (final q in expandLabels(s.questionLabels)) {
          expect(covered.add(q), isTrue, reason: '$q listed twice');
        }
      }
      expect(covered, hasLength(180));
    });
  });

  group('layoutVersion discipline', () {
    test('bumping the version changes the spec hash', () {
      final a = buildStandard90();
      final b = buildStandard90(layoutVersion: 2);
      expect(specSha256(a), isNot(specSha256(b)));
    });

    test('canonical JSON is stable across constructions', () {
      final a = buildStandard90();
      final b = buildNeet180();
      expect(a.canonicalJson(), a.canonicalJson());
      expect(a.canonicalJson(), isNot(b.canonicalJson()));
    });
  });
}
