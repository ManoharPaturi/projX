import 'dart:math' as math;

import '../cv/opencv_service.dart' show CvPointI;

/// One hysteresis update's outcome.
class HysteresisState {
  const HysteresisState({
    required this.progress,
    required this.stableCount,
    required this.tracking,
    this.consensusQuad,
    this.triggered = false,
  });

  /// stableCount / requiredPasses, clamped 0..1 — the progress ring value.
  final double progress;

  final int stableCount;

  /// Whether the rolling queue currently agrees on a quad (the overlay
  /// switches from searching to locked-on).
  final bool tracking;

  /// The averaged stable quad, canvas for the overlay, when [tracking].
  final List<CvPointI>? consensusQuad;

  /// The auto-shutter fired on THIS update. One-shot: the counter resets
  /// with the trigger.
  final bool triggered;
}

/// Steady-state auto-capture (plan §3, WeScan-derived constants).
///
/// A quad is only shutter-worthy after the phone has been STILL over the
/// SAME sheet for a while: 8-quad rolling queue, a minimum of 3 agreeing
/// within 6 px per corner, 35 consecutive stable passes, and a full reset
/// after 3 misses. The 35-pass dwell is what kills motion blur — the sheet
/// is captured at the END of a still period, never mid-move.
class QuadHysteresis {
  QuadHysteresis({
    this.queueCapacity = 8,
    this.minAgreeingQuads = 3,
    this.cornerConsensusPx = 6,
    this.requiredStablePasses = 35,
    this.resetAfterMisses = 3,
  }) : _queue = <List<CvPointI>>[];

  final int queueCapacity;
  final int minAgreeingQuads;
  final int cornerConsensusPx;
  final int requiredStablePasses;
  final int resetAfterMisses;

  final List<List<CvPointI>> _queue;
  int _stableCount = 0;
  int _missCount = 0;

  /// Feeds the latest analysis-frame quad (null = none detected).
  HysteresisState update(List<CvPointI>? quad) {
    if (quad == null || quad.length != 4) {
      _missCount++;
      if (_missCount >= resetAfterMisses) {
        _queue.clear();
        _stableCount = 0;
      }
      return _state(tracking: false, triggered: false);
    }

    _missCount = 0;
    _queue.add(quad);
    if (_queue.length > queueCapacity) {
      _queue.removeRange(0, _queue.length - queueCapacity);
    }

    if (_agreesWithRecent(quad)) {
      _stableCount++;
    } else {
      // A moving quad starts its own stability window from this frame.
      _stableCount = 1;
    }

    if (_stableCount >= requiredStablePasses) {
      // Hand out the consensus the dwell triggered ON before the queue
      // resets — the shutter instant still needs to know where the sheet is.
      final consensus = _averageQuad(_queue.sublist(
          _queue.length - math.min(minAgreeingQuads, _queue.length)));
      _stableCount = 0;
      _queue.clear();
      return _state(
          tracking: true, triggered: true, consensus: consensus);
    }
    return _state(tracking: true, triggered: false);
  }

  /// Full manual reset (new sheet, capture session restarted).
  void reset() {
    _queue.clear();
    _stableCount = 0;
    _missCount = 0;
  }

  /// Whether the newest quad agrees with enough of the recent queue, every
  /// corner within [cornerConsensusPx].
  bool _agreesWithRecent(List<CvPointI> quad) {
    if (_queue.length < minAgreeingQuads) return false;
    final recent = _queue.sublist(_queue.length - minAgreeingQuads);
    for (final other in recent) {
      if (identical(other, quad)) continue;
      for (var i = 0; i < 4; i++) {
        if ((quad[i].x - other[i].x).abs() > cornerConsensusPx ||
            (quad[i].y - other[i].y).abs() > cornerConsensusPx) {
          return false;
        }
      }
    }
    return true;
  }

  HysteresisState _state(
      {required bool tracking,
      required bool triggered,
      List<CvPointI>? consensus}) {
    return HysteresisState(
      progress:
          (_stableCount / requiredStablePasses).clamp(0.0, 1.0).toDouble(),
      stableCount: _stableCount,
      tracking: tracking,
      consensusQuad: consensus ??
          (tracking && _queue.isNotEmpty
              ? _averageQuad(_queue.sublist(
                  _queue.length - math.min(minAgreeingQuads, _queue.length)))
              : null),
      triggered: triggered,
    );
  }

  /// Corner-wise mean of the agreeing window — what the overlay draws.
  static List<CvPointI> _averageQuad(List<List<CvPointI>> quads) {
    return [
      for (var i = 0; i < 4; i++)
        CvPointI(
          quads.map((q) => q[i].x).reduce((a, b) => a + b) ~/ quads.length,
          quads.map((q) => q[i].y).reduce((a, b) => a + b) ~/ quads.length,
        ),
    ];
  }
}
