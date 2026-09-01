import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';

/// The five live capture gates as pure decision functions: verdicts,
/// directional hints, hint priority, the blur gate's calibration-free
/// rolling-percentile behaviour (tremor fails, re-adapts, resets), and the
/// silent-pass rule for anything a frame couldn't measure.
void main() {
  /// Axis-aligned quad (tl, tr, br, bl) — what a flat, square capture looks
  /// like to the detector.
  List<CvPointI> quadAt(int x, int y, int w, int h) => [
        CvPointI(x, y),
        CvPointI(x + w, y),
        CvPointI(x + w, y + h),
        CvPointI(x, y + h),
      ];

  /// The standard well-framed quad as a const, so it can be a parameter
  /// DEFAULT — an explicitly passed `null` still means "no quad detected"
  /// (Dart: explicit null overrides the default).
  const goodQuad = [
    CvPointI(60, 40),
    CvPointI(580, 40),
    CvPointI(580, 440),
    CvPointI(60, 440),
  ];

  /// A clean 640×480 analysis frame with every measurement present.
  GateInput frame({
    List<CvPointI>? quad = goodQuad,
    double? sharpness = 150,
    double? exposureMean = 110,
    double? stillShortSidePx = 3000,
    double? requiredSheetPxOnStill = 1680,
  }) =>
      GateInput(
        frameWidth: 640,
        frameHeight: 480,
        quad: quad,
        sharpness: sharpness,
        exposureMean: exposureMean,
        stillShortSidePx: stillShortSidePx,
        requiredSheetPxOnStill: requiredSheetPxOnStill,
      );

  GateResult resultFor(List<GateResult> results, GateType type) =>
      results.firstWhere((r) => r.type == type);

  test('clean frame: every gate passes, no hint', () {
    final gates = CaptureQualityGates();
    final results = gates.evaluate(frame());

    expect(gates.allPassed(results), isTrue);
    expect(gates.hintFor(results), isNull);
  });

  group('area gate', () {
    test('no quad at all → fails with the align hint', () {
      final gates = CaptureQualityGates();
      final results = gates.evaluate(frame(quad: null, sharpness: null));

      final area = resultFor(results, GateType.area);
      expect(area.passed, isFalse);
      expect(area.hint, 'align the sheet inside the frame');
      expect(gates.hintFor(results), 'align the sheet inside the frame');
    });

    test('tiny quad → directional move-closer hint', () {
      final gates = CaptureQualityGates();
      final results =
          gates.evaluate(frame(quad: quadAt(240, 190, 150, 200)));

      final area = resultFor(results, GateType.area);
      expect(area.passed, isFalse);
      expect(area.hint, 'move closer — sheet too small in frame');
      expect(area.measured, closeTo(30000 / 307200, 0.001));
      expect(area.required, 0.20);
    });

    test('corner clipped by the frame edge → move-away hint even in-range', () {
      // Fraction is a healthy 0.68 — only the x=2 corner (inside the 4 px
      // margin) makes this unusable: the warp would invent content for the
      // missing band.
      final gates = CaptureQualityGates();
      final results = gates.evaluate(frame(quad: quadAt(2, 40, 520, 400)));

      final area = resultFor(results, GateType.area);
      expect(area.passed, isFalse);
      expect(area.hint, 'move away — sheet touches the frame edge');
    });

    test('dominantly large quad → move-away hint', () {
      final gates = CaptureQualityGates();
      final results =
          gates.evaluate(frame(quad: quadAt(2, 2, 636, 476)));

      expect(resultFor(results, GateType.area).passed, isFalse);
      expect(gates.hintFor(results), 'move away — sheet touches the frame edge');
    });
  });

  group('angle gate', () {
    test('strong trapezoid perspective → fails alone with its hint', () {
      final gates = CaptureQualityGates();
      // Near edge 880 px, far edge 1120 px on a 1280×720 frame: a
      // stood-off-phone keystone. Cosine at tl ≈ 0.22, well over 0.085;
      // every other gate stays green (area 0.59, sharp, lit, resolved).
      final results = gates.evaluate(GateInput(
        frameWidth: 1280,
        frameHeight: 720,
        quad: [
          const CvPointI(200, 120),
          const CvPointI(1080, 120),
          const CvPointI(1200, 660),
          const CvPointI(80, 660),
        ],
        sharpness: 150,
        exposureMean: 110,
        stillShortSidePx: 3000,
        requiredSheetPxOnStill: 1680,
      ));

      final angle = resultFor(results, GateType.angle);
      expect(angle.passed, isFalse);
      expect(angle.measured, greaterThan(0.085));
      expect(gates.hintFor(results), 'hold the phone flat over the sheet');
    });
  });

  group('blur gate', () {
    test('below the absolute floor fails on the very first frame', () {
      final gates = CaptureQualityGates();
      final results = gates.evaluate(frame(sharpness: 40));

      final blur = resultFor(results, GateType.blur);
      expect(blur.passed, isFalse);
      expect(blur.measured, 40);
      expect(blur.required, 80); // Strictness.normal floor
      expect(gates.hintFor(results), 'hold still — sheet is not sharp');
    });

    test('strictness presets move the floor (100: normal pass, strict fail)', () {
      final normal = CaptureQualityGates()
          .evaluate(frame(sharpness: 100));
      final strict = CaptureQualityGates(strictness: Strictness.strict)
          .evaluate(frame(sharpness: 100));
      final relaxed = CaptureQualityGates(strictness: Strictness.relaxed)
          .evaluate(frame(sharpness: 60));

      expect(resultFor(normal, GateType.blur).passed, isTrue);
      expect(resultFor(strict, GateType.blur).passed, isFalse);
      expect(resultFor(relaxed, GateType.blur).passed, isTrue);
    });

    test('hand tremor: sharp frame fails against its own recent norm', () {
      // The calibration-free core of the gate: 200-variance frames establish
      // the recent norm; a 100-variance tremor is still above the absolute
      // floor but far below 55% of the rolling p75 — it must fail.
      final gates = CaptureQualityGates();
      for (var i = 0; i < 8; i++) {
        expect(
          resultFor(gates.evaluate(frame(sharpness: 200)), GateType.blur)
              .passed,
          isTrue,
        );
      }
      final tremor = resultFor(gates.evaluate(frame(sharpness: 100)),
          GateType.blur);
      expect(tremor.passed, isFalse);
      expect(tremor.required, closeTo(110, 0.01)); // 0.55 × p75(200)
    });

    test('re-adapts when the whole scene genuinely softens', () {
      // The phone settles over a real softer scene (macro texture, dimmer
      // desk): after the dip dominates the 24-frame window the p75 falls to
      // the new norm and the same 100-variance frame passes again.
      final gates = CaptureQualityGates();
      for (var i = 0; i < 24; i++) {
        gates.evaluate(frame(sharpness: 200));
      }
      var verdict = resultFor(
          gates.evaluate(frame(sharpness: 100)), GateType.blur);
      expect(verdict.passed, isFalse, reason: 'first dipped frame is a tremor');

      for (var i = 0; i < 19; i++) {
        gates.evaluate(frame(sharpness: 100));
      }
      verdict = resultFor(gates.evaluate(frame(sharpness: 100)), GateType.blur);
      expect(verdict.passed, isTrue,
          reason: 'a sustained soft scene becomes the norm');
    });

    test('reset() forgets the norm — torch toggle, new session', () {
      final gates = CaptureQualityGates();
      for (var i = 0; i < 8; i++) {
        gates.evaluate(frame(sharpness: 200));
      }
      gates.reset();
      final verdict = resultFor(
          gates.evaluate(frame(sharpness: 100)), GateType.blur);
      expect(verdict.passed, isTrue, reason: 'absolute floor only, no history');
    });

    test('unmeasurable sharpness passes silently', () {
      final gates = CaptureQualityGates();
      final results = gates.evaluate(frame(sharpness: null));
      expect(resultFor(results, GateType.blur).passed, isTrue);
    });
  });

  group('exposure gate', () {
    test('dark and bright produce directional hints', () {
      final gates = CaptureQualityGates();
      final dark = gates.evaluate(frame(exposureMean: 40));
      final bright = gates.evaluate(frame(exposureMean: 240));

      expect(resultFor(dark, GateType.exposure).passed, isFalse);
      expect(gates.hintFor(dark), 'too dark — find brighter light');
      expect(resultFor(bright, GateType.exposure).passed, isFalse);
      expect(
          gates.hintFor(bright), 'too bright — avoid direct light on the sheet');
    });

    test('unmeasurable exposure passes silently — not its call yet', () {
      final gates = CaptureQualityGates();
      final results =
          gates.evaluate(frame(quad: null, exposureMean: 40, sharpness: null));
      expect(resultFor(results, GateType.exposure).passed, isTrue);
    });
  });

  group('resolution gate', () {
    test('same framing passes once the still is big enough', () {
      final gates = CaptureQualityGates();
      final quad = quadAt(200, 160, 240, 280); // 240 px on the 480 px side
      final smallStill =
          gates.evaluate(frame(quad: quad, stillShortSidePx: 3000));
      final bigStill =
          gates.evaluate(frame(quad: quad, stillShortSidePx: 4000));

      // 1680 sheet-px need 0.56 of the short side; this quad covers 0.50.
      final fail = resultFor(smallStill, GateType.resolution);
      expect(fail.passed, isFalse);
      expect(fail.measured, closeTo(0.5, 0.001));
      expect(
          gates.hintFor(smallStill), 'move closer — sheet too small in frame');

      // Identical framing, bigger sensor: 0.50 ≥ 1680/4000 — the gate is
      // about delivered pixels, not framing.
      expect(resultFor(bigStill, GateType.resolution).passed, isTrue);
    });
  });

  test('hint priority follows gate declaration order', () {
    // Area AND exposure both fail; the overlay must coach area first.
    final gates = CaptureQualityGates();
    final results = gates.evaluate(
      frame(quad: quadAt(240, 190, 150, 200), exposureMean: 40),
    );
    expect(gates.hintFor(results), 'move closer — sheet too small in frame');
    expect(gates.allPassed(results), isFalse);
  });
}
