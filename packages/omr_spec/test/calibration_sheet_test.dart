import 'dart:typed_data';

import 'package:omr_spec/omr_spec.dart';
import 'package:test/test.dart';

/// The calibration sheet (plan §9 / M4): a validated spec on the Standard-90
/// frame whose reference fills are print-only ink — never spec JSON, never
/// the detection template's concern.
void main() {
  test('the calibration spec passes the same validator as production sheets',
      () {
    final sheet = buildCalibrationSheet();
    // buildCalibrationSpec already validateOrThrow's; compiling the detection
    // template is the second gate — both must accept it unchanged.
    final template = compileDetectionTemplate(sheet.spec);
    expect(template.canvasWidth, 1680);
    expect(template.canvasHeight, 2376);
  });

  test('field keys cover column x band x level; rows span the page', () {
    final sheet = buildCalibrationSheet();
    final keys = {
      for (final b in sheet.spec.fieldBlocks) ...b.fields,
    };
    expect(keys, containsAll([
      for (var c = 1; c <= 3; c++)
        for (final band in calibrationBands)
          for (final level in calibrationLevels) 'cal_c${c}_${band}_$level',
    ]));
    expect(keys.length, 36 + 8 /* roll */ + 1 /* set */);

    // The 18mm grid samples the full content height: first row at std90's
    // own origin, last row bottom edge past y=240.
    final cal = sheet.spec.fieldBlocks
        .firstWhere((b) => b.blockId == 'cal_c1');
    expect(cal.fields.length, 12);
    expect(cal.originMm.y, 42.0);
    expect(cal.rowPitchMm, 18.0);
    expect(
      cal.bubbleCenter(11, 0).y + sheet.spec.bubbleStyle.hMm / 2,
      greaterThan(240),
    );
  });

  test('fills print a real PDF; the spec hash ignores fills', () async {
    final sheet = buildCalibrationSheet();
    final Uint8List bytes = await compileSheetPdf(
      sheet.spec,
      examTitle: 'CALIBRATION SHEET',
      bubbleFills: sheet.fills,
    );
    expect(bytes.lengthInBytes, greaterThan(10_000));

    // Fill ink is not geometry: the spec hashes identically with or without
    // the fills map — layoutVersion never bumps for ink.
    final bare = await compileSheetPdf(sheet.spec);
    expect(bare.lengthInBytes, greaterThan(10_000));
    expect(specSha256(sheet.spec), specSha256(buildCalibrationSpec()));
  });

  test('mid level leaves one option unfilled so every row keeps an in-row '
      'empty sample', () {
    final fills = calibrationFills();
    expect(fills['cal_c1_t_mid']!.optionIndexes, [0, 1, 2]);
    expect(fills['cal_c1_t_empty'], isNull,
        reason: 'the empty row carries no fill by construction');
    expect(fills.length, 3 /* cols */ * 3 /* bands */ * 3 /* filled levels */);
  });
}
