import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';

/// The composed live loop: one frame in, one scanner state out. The fixtures
/// are the pipeline suite's desk-plus-sheet photos at analysis-stream size —
/// a bright textured sheet on a dark desk — and the assertions target the
/// COMPOSITION (dwell fed only by clean frames, hint passthrough, quad
/// choice), since gates and hysteresis have their own suites.
void main() {
  const w = 640, h = 480;

  /// Desk 60, sheet 238 with ±40 deterministic grain. The grain is what the
  /// Laplacian sees (raw frame) while the quad detector's blurred+ Cannied
  /// view stays a clean rectangle — the same trick a real printed sheet
  /// pulls on both measurements.
  Uint8List photo(int x, int y, int qw, int qh, {int seed = 7}) {
    final rng = math.Random(seed);
    final bytes = Uint8List(w * h);
    bytes.fillRange(0, bytes.length, 60);
    for (var yy = y; yy < y + qh; yy++) {
      for (var xx = x; xx < x + qw; xx++) {
        final n = (rng.nextDouble() - 0.5) * 80;
        bytes[yy * w + xx] = math.max(0, math.min(255, (238 + n).round()));
      }
    }
    return bytes;
  }

  LiveFrame frameOf(Uint8List bytes) =>
      LiveFrame(width: w, height: h, gray: bytes);

  LiveFrameAnalyzer analyzer({
    CaptureQualityGates? gates,
    double? stillShortSidePx = 3000,
    double? requiredSheetPxOnStill = 1680,
  }) =>
      LiveFrameAnalyzer(
        cv: OpencvDartImpl(),
        gates: gates,
        stillShortSidePx: stillShortSidePx,
        requiredSheetPxOnStill: requiredSheetPxOnStill,
      );

  test('steady clean stream: locks on, then auto-captures after the dwell',
      () async {
    // Exposure to 255: the fixture sheet is a bright 238, which the DEFAULT
    // exposure band would (correctly) coach away — here the dwell is under
    // test, not the lighting gate.
    final a = analyzer(
        gates: CaptureQualityGates(exposureMax: 255));
    final bytes = photo(60, 40, 520, 400);

    var triggeredAt = -1;
    ScannerTick? last;
    for (var i = 1; i <= 40; i++) {
      last = a.update(frameOf(bytes));
      if (last.autoShutter) {
        triggeredAt = i;
        break;
      }
      expect(last.hint, isNull, reason: 'frame $i: ${last.gates}');
      expect(last.lockedOn, isTrue);
    }

    expect(triggeredAt, 36, reason: 'same dwell as the hysteresis suite');
    expect(last!.quad, isNotNull);
    // The overlay quad is the CONSENSUS of the agreeing window — spot-check
    // one corner lands within a few px of the drawn sheet's tl.
    final tl = last.quad!.reduce((p, q) => (p.x + p.y) < (q.x + q.y) ? p : q);
    expect(tl.x, inInclusiveRange(50, 75));
    expect(tl.y, inInclusiveRange(30, 55));
  });

  test('a steady but badly lit sheet never earns shutter credit', () {
    // Same fixture, default exposure band: mean ~238 > 200 fails every
    // frame, so the dwell must starve — the ring stays at zero and the
    // overlay coaches lighting instead of locking on.
    final a = analyzer();
    final bytes = photo(60, 40, 520, 400);

    for (var i = 0; i < 60; i++) {
      final tick = a.update(frameOf(bytes));
      expect(tick.autoShutter, isFalse);
      expect(tick.lockedOn, isFalse);
      expect(tick.hint, 'too bright — avoid direct light on the sheet');
      expect(tick.hysteresis.progress, 0,
          reason: 'gate-failing frames are misses, not dwell credit');
    }
  });

  test('a jiggling clean sheet never triggers', () {
    final a = analyzer(gates: CaptureQualityGates(exposureMax: 255));
    final at = photo(60, 40, 520, 400, seed: 1);
    final bt = photo(80, 60, 520, 400, seed: 2); // 20 px off — real motion

    var triggered = false;
    for (var i = 0; i < 100; i++) {
      final tick = a.update(frameOf(i.isEven ? at : bt));
      triggered |= tick.autoShutter;
    }
    expect(triggered, isFalse);
  });

  test('empty desk: no quad, align hint, silent measurement gates', () {
    final a = analyzer();
    final desk = Uint8List(w * h);
    desk.fillRange(0, desk.length, 60);

    final tick = a.update(frameOf(desk));
    expect(tick.quad, isNull);
    expect(tick.hint, 'align the sheet inside the frame');
    expect(tick.gates.length, 5);
    expect(tick.hysteresis.progress, 0);
  });

  test('reset() clears both the blur norm and the dwell', () {
    final a = analyzer(gates: CaptureQualityGates(exposureMax: 255));
    final bytes = photo(60, 40, 520, 400);
    for (var i = 0; i < 20; i++) {
      a.update(frameOf(bytes));
    }
    a.reset();

    final tick = a.update(frameOf(bytes));
    expect(tick.hysteresis.stableCount, 1, reason: 'dwell starts over');
    expect(tick.hint, isNull);
  });
}
