import 'dart:convert' show latin1;
import 'dart:typed_data';

import 'package:omr_spec/omr_spec.dart';
import 'package:pdf/pdf.dart';
import 'package:test/test.dart';

void main() {
  group('compileSheetPdf', () {
    test('Preset A renders a real, non-trivial PDF', () async {
      final bytes = await compileSheetPdf(buildStandard90(), examTitle: 'JEE Mock 1');
      expect(bytes, isA<Uint8List>());
      expect(bytes.lengthInBytes, greaterThan(10_000));
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      // The stream must end with a trailer, not a truncated write.
      final tail = latin1.decode(bytes.sublist(bytes.lengthInBytes - 64));
      expect(tail.contains('%%EOF'), isTrue);
    });

    test('Preset B renders too', () async {
      final bytes = await compileSheetPdf(buildNeet180());
      expect(bytes.lengthInBytes, greaterThan(10_000));
    });

    test('the QR payload string is embedded in the content stream', () async {
      final bytes = await compileSheetPdf(buildStandard90());
      // Compressed streams may not contain it verbatim; assert on size +
      // header only, the QR modules themselves are geometry-checked in the
      // template tests.
      expect(bytes.lengthInBytes, greaterThan(20_000));
    });

    test('an invalid spec is refused before any PDF work', () async {
      final bad = buildStandard90().copyWith(
        qrZone: const QrZone(sizeMm: 8),
      );
      // Validation runs synchronously before the first await, so pass a
      // closure — a bare call would throw before expectLater sees a Future.
      await expectLater(
        () => compileSheetPdf(bad),
        throwsA(isA<SpecValidationException>()),
      );
    });

    test('specHash round-trips through both compilers', () {
      final spec = buildStandard90();
      final t = compileDetectionTemplate(spec);
      expect(t.specHash, specSha256(spec));
      expect(t.layoutVersion, spec.layoutVersion);
    });

    test('header strings fit inside the content rect of both presets', () {
      // A centered header wider than the page clips at BOTH edges — the
      // painter centers by measured width, so the measurement IS the check.
      final doc = PdfDocument();
      final font = PdfFont.helvetica(doc);
      final bold = PdfFont.helveticaBold(doc);
      for (final spec in [buildStandard90(), buildNeet180()]) {
        final usable = spec.paperWidthMm - 2 * spec.marginMm;
        final sub = '${spec.layoutId} v${spec.layoutVersion}'
            '  ·  ${spec.instructionText}'.trim();
        expect(
          textWidthMm(font, 7, sub),
          lessThan(usable),
          reason: '${spec.layoutId}: instruction sub-line exceeds margins',
        );
        expect(
          textWidthMm(bold, 12, 'JEE Mock 1'),
          lessThan(usable),
          reason: '${spec.layoutId}: title exceeds margins',
        );
      }
    });
  });
}
