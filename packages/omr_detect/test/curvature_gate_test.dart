import 'package:omr_detect/omr_detect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gate = CurvatureGate();

  // std90 timing bars: 30 bars, 7.8mm = 62.4px apart; bubble 3.5mm = 28px.
  final expected = [
    for (var i = 0; i < 7; i++) (x: 80.0, y: 336.0 + i * 62.4),
  ];

  List<({double x, double y})> shift(List<({double x, double y})> pts,
          double dx, double dy) =>
      [
        for (final p in pts) (x: p.x + dx, y: p.y + dy),
      ];

  test('a flat sheet has zero residual and no curl', () {
    final report = gate.evaluate(
      measuredCentroids: expected,
      expectedCentroids: expected,
      bubbleHeightPx: 28,
    );
    expect(report.residualRms, 0);
    expect(report.curlDetected, isFalse);
    expect(report.ratio, 0);
    expect(report.barsChecked, 7);
  });

  test('a uniform shift is a registration offset, not curl', () {
    final report = gate.evaluate(
      measuredCentroids: shift(expected, 3, 4),
      expectedCentroids: expected,
      bubbleHeightPx: 28,
    );
    // The mean residual is subtracted: only variation indicts the warp.
    expect(report.residualRms, closeTo(0, 1e-9));
    expect(report.curlDetected, isFalse);
  });

  test('a bell-curve bow beyond tolerance is flagged as curl', () {
    // Peak 27px ≈ 3.4mm mid-sheet bow. Tolerance 0.30 × 28 = 8.4px; the
    // mean-subtracted RMS of this shape is ≈ 9.27px.
    const bow = [0.0, 9, 18, 27, 18, 9, 0];
    final measured = [
      for (var i = 0; i < expected.length; i++)
        (x: expected[i].x, y: expected[i].y + bow[i]),
    ];
    final report = gate.evaluate(
      measuredCentroids: measured,
      expectedCentroids: expected,
      bubbleHeightPx: 28,
    );

    expect(report.residualRms, closeTo(9.27, 0.05));
    expect(report.ratio, greaterThan(1));
    expect(report.curlDetected, isTrue);
    expect(report.worstBar!.index, 3); // the middle bar wandered furthest
    expect(report.tolerancePx, closeTo(8.4, 1e-9));
  });

  test('a small bow inside tolerance passes', () {
    const bow = [0.0, 3, 6, 8, 6, 3, 0];
    final measured = [
      for (var i = 0; i < expected.length; i++)
        (x: expected[i].x, y: expected[i].y + bow[i]),
    ];
    final report = gate.evaluate(
      measuredCentroids: measured,
      expectedCentroids: expected,
      bubbleHeightPx: 28,
    );
    expect(report.curlDetected, isFalse);
  });

  test('length mismatch compares the overlapping bars only', () {
    final report = gate.evaluate(
      measuredCentroids: expected.take(3).toList(),
      expectedCentroids: expected,
      bubbleHeightPx: 28,
    );
    expect(report.barsChecked, 3);
    expect(report.curlDetected, isFalse);
  });

  test('no bars at all is an empty, non-curl report', () {
    final report = gate.evaluate(
      measuredCentroids: const [],
      expectedCentroids: const [],
      bubbleHeightPx: 28,
    );
    expect(report.barsChecked, 0);
    expect(report.curlDetected, isFalse);
  });
}
