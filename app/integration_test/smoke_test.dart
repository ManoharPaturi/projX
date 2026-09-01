import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:omr_detect/omr_detect.dart';

/// M0 gate, device leg (plan §8c): the SAME probe the host suite runs
/// (`packages/omr_detect/test/cv_smoke_test.dart`), executed on a real
/// arm64 Android device. The frame-time bound here is the real one — the
/// ≤32 ms budget is judged on the low-end device, not the dev machine.
///
/// Run with the device attached:
///   `flutter test integration_test/smoke_test.dart -d <device-id>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M0 on-device cv smoke + quad-detect timing', (tester) async {
    // The probe is pure synchronous compute, but running it via runAsync
    // keeps it off testWidgets' fakeAsync zone — same rule the host widget
    // tests learned the hard way.
    final report = await tester.runAsync(_probe);
    expect(report, isNotNull, reason: 'probe never returned');
    for (final check in report!.checks) {
      // Integration reports surface in `flutter test` output and logcat.
      // ignore: avoid_print
      print(check);
      expect(check.passed, isTrue, reason: check.detail);
    }
    // ignore: avoid_print
    print(
      'quad-detect: ${report.quadDetectUsPerFrame.toStringAsFixed(0)} '
      'us/frame at 640x480 over ${report.framesTimed} frames',
    );
    // The go/no-go budget for the live analysis loop (plan §3): a 640×480
    // frame must clear in ≤32 ms. Blowing this on the low-end device is the
    // documented trigger to port the live quad loop to Kotlin behind
    // EdgeAnalyzer (opencv_dart keeps serving the still pipeline).
    expect(
      report.quadDetectUsPerFrame,
      lessThan(32000),
      reason: 'live-loop frame budget exceeded — see docs/m0-gate.md '
          'native-fallback decision',
    );
  });
}

Future<SmokeReport> _probe() async => runCvSmokeProbe(OpencvDartImpl());
