import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_detect/testing.dart' show inkAt, renderSheetPhoto;
import 'package:omr_spec/omr_spec.dart'
    show buildCalibrationSpec, compileDetectionTemplate;

/// The calibration analyzer over a synthetic photo of the printed
/// calibration sheet: inked full/faint/mid reference rows must register,
/// pool into the three bands, and separate comfortably.
void main() {
  final cv = OpencvDartImpl();
  final template = compileDetectionTemplate(buildCalibrationSpec());
  const imgW = 1200, imgH = 1600;

  Uint8List photo({List<({int x, int y, int w, int h})> marks = const []}) =>
      renderSheetPhoto(
        cv,
        template,
        imageWidth: imgW,
        imageHeight: imgH,
        marks: marks,
      );

  /// Ink every option the printed sheet fills, at the analyzer's own
  /// `filledOptions` truth — the same data `calibrationFills()` prints.
  /// MCQ bubbles carry letter option values (A..D).
  List<({int x, int y, int w, int h})> allPrintedInk() => [
    for (final entry in CalibrationAnalyzer.calibrationFilledOptions.entries)
      for (final option in entry.value)
        inkAt(template, entry.key, 'ABCD'[option]),
  ];

  test('inked calibration photo: three bands, comfortable margins', () {
    final report = CalibrationAnalyzer().analyze(
      cv: cv,
      template: template,
      imageWidth: imgW,
      imageHeight: imgH,
      grayBytes: photo(marks: allPrintedInk()),
    );

    expect(report.registrationOk, isTrue);
    expect(report.fiducialScores.length, 4);
    expect(report.regions.map((r) => r.band), containsAll(['t', 'm', 'b']));
    for (final region in report.regions) {
      // Ink paints near-black (18) against a ~238 paper: every band must
      // clear the confident-jump margin comfortably.
      expect(region.separation, greaterThan(100));
      expect(region.samples, greaterThanOrEqualTo(9));
    }
    expect(report.overall, CalibrationVerdict.comfortable);
    expect(report.suggestedStrictness, 'normal');
  });

  test('blank calibration photo: empties only, still comfortable', () {
    final report = CalibrationAnalyzer().analyze(
      cv: cv,
      template: template,
      imageWidth: imgW,
      imageHeight: imgH,
      grayBytes: photo(), // nothing inked: no full population to separate
    );

    expect(report.registrationOk, isTrue);
    for (final region in report.regions) {
      expect(region.fullMax, greaterThan(region.emptyMin - 5));
    }
    // No filled population ⇒ separation collapses ⇒ not a pass.
    expect(report.overall, isNot(CalibrationVerdict.comfortable));
  });

  test('unregisterable noise: report says retake, no regions', () {
    final noise = Uint8List.fromList(List.filled(imgW * imgH, 128));
    final report = CalibrationAnalyzer().analyze(
      cv: cv,
      template: template,
      imageWidth: imgW,
      imageHeight: imgH,
      grayBytes: noise,
    );

    expect(report.registrationOk, isFalse);
    expect(report.regions, isEmpty);
    expect(report.overall, CalibrationVerdict.failed);
    expect(report.summary, contains('retake'));
  });
}
