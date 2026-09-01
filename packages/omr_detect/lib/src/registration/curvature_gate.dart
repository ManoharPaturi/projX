import 'dart:math' as math;

import '../thresholds/threshold_config.dart';

/// Stage-4 verdict: did the warped sheet stay flat?
class CurvatureReport {
  const CurvatureReport({
    required this.residualRms,
    required this.tolerancePx,
    required this.barsChecked,
    this.worstBar,
  });

  /// RMS of the mean-subtracted bar-centre residuals, px. The mean is
  /// subtracted first because a uniform shift is a registration offset, not
  /// curvature — only the *variation* across the track indicts the
  /// homography.
  final double residualRms;

  /// `curlBubbleHeightFraction × bubble height`, px — the plan's tolerance.
  final double tolerancePx;

  /// How many bars were compared (the smaller of measured/expected counts).
  final int barsChecked;

  /// The bar that wandered furthest, for the review UI to circle.
  final ({int index, double dx, double dy})? worstBar;

  /// residualRms over tolerancePx; > 1 means curled.
  double get ratio =>
      tolerancePx > 0 ? residualRms / tolerancePx : (residualRms > 0 ? 1 : 0);

  /// Beyond tolerance ⇒ the corner-only homography is not to be trusted and
  /// the sheet must be reviewed (manual corner-drag offered), not graded
  /// blind.
  bool get curlDetected => residualRms > tolerancePx && tolerancePx > 0;
}

/// Compares measured timing-bar centroids against the template grid.
///
/// A four-corner homography is exact for flat paper and silently wrong for
/// curled paper: the middle rows drift while the corners stay put. The
/// printed timing track measures that drift directly — one bar per MCQ row,
/// spanning the sheet's full height, already in canonical-canvas
/// coordinates. This stage never touches pixels; it consumes the centroids
/// measured on the warped canvas (plan §3 stage 4).
class CurvatureGate {
  const CurvatureGate({this.config = const ThresholdConfig()});

  final ThresholdConfig config;

  CurvatureReport evaluate({
    required List<({double x, double y})> measuredCentroids,
    required List<({double x, double y})> expectedCentroids,
    required double bubbleHeightPx,
  }) {
    final count = math.min(measuredCentroids.length, expectedCentroids.length);
    if (count == 0) {
      return const CurvatureReport(
        residualRms: 0,
        tolerancePx: 0,
        barsChecked: 0,
      );
    }

    var sumDx = 0.0;
    var sumDy = 0.0;
    for (var i = 0; i < count; i++) {
      sumDx += measuredCentroids[i].x - expectedCentroids[i].x;
      sumDy += measuredCentroids[i].y - expectedCentroids[i].y;
    }
    final meanDx = sumDx / count;
    final meanDy = sumDy / count;

    var acc = 0.0;
    ({int index, double dx, double dy})? worst;
    var worstMagnitude = -1.0;
    for (var i = 0; i < count; i++) {
      final dx = measuredCentroids[i].x - expectedCentroids[i].x - meanDx;
      final dy = measuredCentroids[i].y - expectedCentroids[i].y - meanDy;
      acc += dx * dx + dy * dy;
      final magnitude = math.sqrt(dx * dx + dy * dy);
      if (magnitude > worstMagnitude) {
        worstMagnitude = magnitude;
        worst = (index: i, dx: dx, dy: dy);
      }
    }

    final tolerance = config.curlBubbleHeightFraction * bubbleHeightPx;
    return CurvatureReport(
      residualRms: math.sqrt(acc / count),
      tolerancePx: tolerance,
      barsChecked: count,
      worstBar: worst,
    );
  }
}
