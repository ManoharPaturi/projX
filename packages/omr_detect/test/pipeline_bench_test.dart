import 'package:flutter_test/flutter_test.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_detect/testing.dart';
import 'package:omr_spec/omr_spec.dart';

/// Every answer, the roll and the set must read back right at the capture
/// sizes the app uses, from a small phone photo up to 12 MP. Timings are
/// printed for the CI log (host numbers, not phone numbers) but never
/// asserted: shared runners are too noisy to gate on.
void main() {
  final cv = OpencvDartImpl();
  final template = compileDetectionTemplate(buildStandard90());

  for (final (w, h) in const [(1080, 1440), (1536, 2048), (3000, 4000)]) {
    test('reads a full sheet correctly at ${w}x$h', () {
      final r = runPipelineBench(cv, template, width: w, height: h, runs: 1);
      // ignore: avoid_print
      print('bench ${w}x$h: ${r.toJson()}');
      expect(r.fieldsChecked, greaterThan(90));
      expect(r.fieldsWrong, 0, reason: '${r.toJson()}');
    });
  }
}
