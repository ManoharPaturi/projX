import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/capture/live_analyzer_worker.dart';
import 'package:omr_detect/omr_detect.dart';

/// The live loop on its own isolate answers like the in-process analyzer:
/// same frame in, same verdict out — and closing it fails pending work
/// instead of hanging the scanner.
void main() {
  LiveFrame flatFrame() {
    final gray = Uint8List(640 * 480)..fillRange(0, 640 * 480, 128);
    return LiveFrame(width: 640, height: 480, gray: gray);
  }

  test(
    'answers a frame with the same tick as the in-process analyzer',
    () async {
      final worker = await LiveAnalyzerWorker.spawn(
        requiredSheetPxOnStill: 900,
      );
      addTearDown(worker.dispose);

      final remote = await worker.analyze(flatFrame());
      final local = LiveFrameAnalyzer(
        cv: OpencvDartImpl(),
        requiredSheetPxOnStill: 900,
      ).update(flatFrame());

      expect(remote.quad, local.quad);
      expect(remote.hint, local.hint);
      expect(remote.allPassed, local.allPassed);
      expect(remote.hysteresis.progress, local.hysteresis.progress);
    },
  );

  test('keeps per-session state across frames', () async {
    final worker = await LiveAnalyzerWorker.spawn();
    addTearDown(worker.dispose);
    final ticks = [
      for (var i = 0; i < 3; i++) await worker.analyze(flatFrame()),
    ];
    expect(ticks, hasLength(3));
    expect(ticks.every((t) => t.quad == null), isTrue);
  });

  test('analyze after dispose fails fast', () async {
    final worker = await LiveAnalyzerWorker.spawn();
    worker.dispose();
    expect(worker.analyze(flatFrame()), throwsStateError);
  });
}
