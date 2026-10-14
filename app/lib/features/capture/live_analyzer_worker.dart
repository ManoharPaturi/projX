import 'dart:async';
import 'dart:isolate';

import 'package:omr_detect/omr_detect.dart'
    show LiveFrame, LiveFrameAnalyzer, OpencvDartImpl, ScannerTick;

/// The live preview loop on its own isolate.
///
/// Quad detection runs on every analysis frame; on the UI isolate it
/// competes with the camera preview and the overlay for the same 16 ms
/// frame budget. The worker owns one [LiveFrameAnalyzer] — its blur history
/// and dwell hysteresis are per-session state, so it must live where the
/// frames are analysed — and answers each frame with a [ScannerTick].
///
/// The scanner view sends a frame only when the previous answer is back,
/// so frames the worker cannot keep up with are dropped at the source
/// instead of queueing up stale work.
class LiveAnalyzerWorker {
  LiveAnalyzerWorker._(this._isolate, this._fromWorker);

  final Isolate _isolate;
  final ReceivePort _fromWorker;
  late final SendPort _toWorker;
  final List<Completer<ScannerTick>> _pending = [];
  bool _closed = false;

  /// Starts a worker whose resolution gate uses [requiredSheetPxOnStill].
  static Future<LiveAnalyzerWorker> spawn({
    double? requiredSheetPxOnStill,
  }) async {
    final fromWorker = ReceivePort();
    final isolate = await Isolate.spawn(_workerMain, (
      fromWorker.sendPort,
      requiredSheetPxOnStill,
    ), debugName: 'live-analyzer');
    final worker = LiveAnalyzerWorker._(isolate, fromWorker);
    final ready = Completer<void>();
    // One listener for the port's lifetime: the first message is the
    // worker's inbox, every later one answers the oldest pending frame.
    fromWorker.listen((message) {
      if (!ready.isCompleted) {
        worker._toWorker = message! as SendPort;
        ready.complete();
        return;
      }
      if (worker._pending.isEmpty) return;
      final completer = worker._pending.removeAt(0);
      if (message is ScannerTick) {
        completer.complete(message);
      } else {
        completer.completeError(StateError('live analyzer: $message'));
      }
    });
    await ready.future;
    return worker;
  }

  /// Analyses one frame off the UI isolate.
  Future<ScannerTick> analyze(LiveFrame frame) {
    if (_closed) {
      return Future.error(StateError('live analyzer closed'));
    }
    final completer = Completer<ScannerTick>();
    _pending.add(completer);
    _toWorker.send(frame);
    return completer.future;
  }

  /// Stops the worker. In-flight frames fail; the scanner view ignores them.
  void dispose() {
    if (_closed) return;
    _closed = true;
    _toWorker.send(null);
    _isolate.kill(priority: Isolate.beforeNextEvent);
    _fromWorker.close();
    for (final c in _pending) {
      c.completeError(StateError('live analyzer closed'));
    }
    _pending.clear();
  }

  static void _workerMain((SendPort, double?) args) {
    final (reply, requiredSheetPxOnStill) = args;
    final inbox = ReceivePort();
    reply.send(inbox.sendPort);
    final analyzer = LiveFrameAnalyzer(
      cv: OpencvDartImpl(),
      requiredSheetPxOnStill: requiredSheetPxOnStill,
    );
    inbox.listen((message) {
      if (message is LiveFrame) {
        try {
          reply.send(analyzer.update(message));
        } catch (error) {
          reply.send('$error');
        }
      } else if (message == null) {
        inbox.close();
      }
    });
  }
}
