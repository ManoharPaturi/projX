import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';

/// M0 go/no-go smoke (plan §8): proves the native OpenCV build loads and
/// every call family the pipeline ships actually exists in the trimmed
/// module set. The checks themselves live in [runCvSmokeProbe] so the
/// on-device integration test (app/integration_test) judges exactly the
/// same criteria — this file is the host driver.
void main() {
  final report = runCvSmokeProbe(OpencvDartImpl());

  for (final check in report.checks) {
    test(check.name, () {
      // ignore: avoid_print, informational in CI logs
      print(check);
      expect(check.passed, isTrue, reason: check.detail);
    });
  }

  test('quad-detect host frame time (informational)', () {
    // Host sanity bound only — generous, since the dev machine is not the
    // target device. The real gate is the on-device ≤32 ms measurement.
    // ignore: avoid_print
    print(
      'quad-detect: ${report.quadDetectUsPerFrame.toStringAsFixed(0)} '
      'us/frame at 640x480 '
      '(${(1000000 / report.quadDetectUsPerFrame).toStringAsFixed(0)} fps, '
      'host)',
    );
    expect(report.quadDetectUsPerFrame, lessThan(32000));
  });
}
