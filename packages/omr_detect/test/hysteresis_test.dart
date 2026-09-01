import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';

/// The steady-state auto-shutter: a same-quad stream triggers after the
/// dwell, a moving quad never does, a slow drift still counts as still,
/// misses reset progress only after the third, and the trigger is one-shot.
void main() {
  List<CvPointI> quadAt(int x, int y, int w, int h) => [
        CvPointI(x, y),
        CvPointI(x + w, y),
        CvPointI(x + w, y + h),
        CvPointI(x, y + h),
      ];

  final sheet = quadAt(60, 40, 520, 400);

  test('a still phone auto-captures after the dwell, exactly once', () {
    final hyst = QuadHysteresis();
    var firedAt = -1;
    HysteresisState? fired;
    for (var i = 1; i <= 40; i++) {
      final s = hyst.update(sheet);
      if (s.triggered) {
        firedAt = i;
        fired = s;
        break;
      }
    }

    // The queue needs minAgreeingQuads (3) samples before any frame can
    // "agree", so two identical frames warm up and 34 agreeing updates ride
    // on them — the shutter fires on update 36.
    expect(firedAt, 36, reason: 'dwell must be ~35 stable passes, not instant');
    expect(fired!.progress, 0, reason: 'the trigger consumes the counter');
    expect(fired.consensusQuad, sheet,
        reason: 'the shutter instant still knows where the sheet is');

    // One-shot: the next identical frame starts a fresh window, not another
    // trigger — the session owns the shutter consequence.
    final after = hyst.update(sheet);
    expect(after.triggered, isFalse);
    expect(after.stableCount, 1);
    expect(after.progress, closeTo(1 / 35, 0.001));
  });

  test('progress ring ramps toward 1 across the dwell', () {
    final hyst = QuadHysteresis();
    HysteresisState? last;
    for (var i = 0; i < 35; i++) {
      last = hyst.update(sheet);
    }
    expect(last!.tracking, isTrue);
    expect(last.stableCount, 34);
    expect(last.progress, closeTo(34 / 35, 0.001));
    expect(last.triggered, isFalse);
    expect(last.consensusQuad, isNotNull,
        reason: 'a locked-on overlay needs the averaged quad');
  });

  test('a jiggling phone never triggers', () {
    final hyst = QuadHysteresis();
    final a = quadAt(60, 40, 520, 400);
    final b = quadAt(80, 60, 520, 400); // 20 px off — beyond the 6 px consensus

    var triggered = false;
    for (var i = 0; i < 200; i++) {
      final s = hyst.update(i.isEven ? a : b);
      triggered |= s.triggered;
      expect(s.stableCount, 1,
          reason: 'every frame disagrees with the recent window');
    }
    expect(triggered, isFalse);
  });

  test('a slow drift within the consensus radius still counts as still', () {
    // WeScan behaviour: 1 px/frame of handheld pan stays inside the 6 px
    // corner consensus across the 3-quad window, so a deliberately moving
    // but smooth capture still shutters — the dwell kills JIGGLE, not
    // patience.
    final hyst = QuadHysteresis();
    var triggered = false;
    for (var i = 0; i < 100; i++) {
      triggered |= hyst
          .update(quadAt(60 + i, 40 + i, 520, 400))
          .triggered;
    }
    expect(triggered, isTrue);
  });

  test('consensus quad is the corner-wise mean of the agreeing window', () {
    final hyst = QuadHysteresis();
    hyst.update(quadAt(100, 100, 400, 300));
    hyst.update(quadAt(110, 100, 400, 300));
    final s = hyst.update(quadAt(120, 100, 400, 300));

    expect(s.consensusQuad, isNotNull);
    // Mean of the last minAgreeingQuads quads: x +10, y unchanged.
    expect(s.consensusQuad![0], const CvPointI(110, 100));
    expect(s.consensusQuad![1], const CvPointI(510, 100));
    expect(s.consensusQuad![2], const CvPointI(510, 400));
    expect(s.consensusQuad![3], const CvPointI(110, 400));
  });

  group('misses', () {
    test('one missed frame does not lose the dwell', () {
      final hyst = QuadHysteresis();
      for (var i = 0; i < 10; i++) {
        hyst.update(sheet);
      }
      final s = hyst.update(null);
      expect(s.tracking, isFalse);
      expect(s.stableCount, 9, reason: 'dwell survives transient detector loss');
    });

    test('three consecutive misses reset the dwell entirely', () {
      final hyst = QuadHysteresis();
      for (var i = 0; i < 20; i++) {
        hyst.update(sheet);
      }
      hyst.update(null);
      hyst.update(null);
      final s = hyst.update(null);
      expect(s.tracking, isFalse);
      expect(s.stableCount, 0);
      expect(s.progress, 0);
      expect(s.consensusQuad, isNull);

      // And the next sighting starts from warm-up, not from the old window.
      final fresh = hyst.update(sheet);
      expect(fresh.stableCount, 1);
      expect(fresh.consensusQuad, isNotNull,
          reason: 'a single quad is its own overlay candidate');
    });

    test('a malformed quad counts as a miss, not as agreement', () {
      final hyst = QuadHysteresis();
      for (var i = 0; i < 10; i++) {
        hyst.update(sheet);
      }
      final s = hyst.update(sheet.sublist(0, 3)); // detector glitch
      expect(s.tracking, isFalse);
    });
  });

  test('manual reset clears queue, dwell, and misses', () {
    final hyst = QuadHysteresis();
    for (var i = 0; i < 30; i++) {
      hyst.update(sheet);
    }
    hyst.update(null);
    hyst.reset();

    final s = hyst.update(sheet);
    expect(s.stableCount, 1);
    expect(s.progress, closeTo(1 / 35, 0.001));
  });
}
