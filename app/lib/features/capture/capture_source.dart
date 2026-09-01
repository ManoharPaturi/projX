import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart' show Size, Widget;
import 'package:omr_detect/omr_detect.dart' show LiveFrame;

/// The seam between the scanner UI and wherever analysis frames come from
/// (plan §3): the widget consumes a [LiveFrame] stream and never touches a
/// camera class, so widget tests drive a [SimulatedCaptureSource] and the
/// device runs [CameraCaptureSource] behind the same contract.
abstract class CaptureSource {
  /// Analysis frames (~640×480 gray), as they arrive.
  Stream<LiveFrame> get frames;

  /// The dims [frames] will carry — the overlay maps analysis px to layout
  /// px through this. Call before [start].
  Size get analysisSize;

  Future<void> start();

  Future<void> stop();

  /// Full-resolution still, JPEG bytes — the bytes the still pipeline
  /// (registration → decode) consumes. Only meaningful while started.
  Future<Uint8List> captureStill();

  /// The camera preview to stack under the scanner overlay, or null when
  /// this source has no imagery (tests, no-camera fallback).
  Widget? buildPreview();

  Future<void> dispose();
}

/// Frames pushed by hand — widget tests and the fixture path. [push] is the
/// camera's callback stand-in; [captureStill] returns whatever the test
/// armed (or a 1×1 black JPEG placeholder), so the shutter path runs
/// identically to the device's.
class SimulatedCaptureSource implements CaptureSource {
  SimulatedCaptureSource({this.analysisSize = const Size(640, 480)});

  @override
  final Size analysisSize;

  final StreamController<LiveFrame> _controller =
      StreamController.broadcast();
  Uint8List? _armedStill;

  @override
  Stream<LiveFrame> get frames => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  /// Emits one frame to every listener.
  void push(LiveFrame frame) => _controller.add(frame);

  /// What [captureStill] will hand the shutter path.
  void armStill(Uint8List bytes) => _armedStill = bytes;

  @override
  Future<Uint8List> captureStill() async =>
      _armedStill ?? Uint8List.fromList([0]);

  @override
  Widget? buildPreview() => null;

  @override
  Future<void> dispose() => _controller.close();
}

/// The real camera: back lens, max-res stills, a ~640×480 grayscale analysis
/// stream subsampled off the Y plane.
///
/// Frame analysis runs where the stream delivers; if the per-frame budget
/// overruns on the low-end device (measured in the M0/M2 device leg), the
/// swap is a Kotlin channel behind this same interface — the scanner widget
/// and the gates never know (plan §3).
class CameraCaptureSource implements CaptureSource {
  CameraCaptureSource({this.analysisWidth = 640, this.analysisHeight = 480});

  final int analysisWidth;
  final int analysisHeight;

  CameraController? _controller;
  final StreamController<LiveFrame> _frames =
      StreamController.broadcast();
  bool _streaming = false;

  @override
  Size get analysisSize => Size(analysisWidth.toDouble(),
      analysisHeight.toDouble());

  /// Finds and initialises the back camera. False when there is none to use
  /// (desktop/emulator) — callers fall back to the fixture path.
  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        back,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      return true;
    } catch (_) {
      await _safeDispose();
      return false;
    }
  }

  @override
  Stream<LiveFrame> get frames => _frames.stream;

  @override
  Future<void> start() async {
    final controller = _controller;
    if (controller == null || _streaming) return;
    _streaming = true;
    await controller.startImageStream(_onCameraImage);
  }

  @override
  Future<void> stop() async {
    if (!_streaming) return;
    _streaming = false;
    final controller = _controller;
    if (controller != null) {
      try {
        await controller.stopImageStream();
      } catch (_) {
        // Already stopped (e.g. surface destroyed) — nothing to do.
      }
    }
  }

  void _onCameraImage(CameraImage image) {
    if (!_streaming || _frames.isClosed) return;
    // Y plane only: luminance IS the grayscale the analyzer wants. Strided
    // rows subsampled to the analysis dims — a preview, never a measurement
    // of record (bubbles are read from the still).
    final plane = image.planes.first;
    final srcW = image.width;
    final srcH = image.height;
    final rowStride = plane.bytesPerRow;
    final bytes = plane.bytes;
    final stepX = math.max(1, srcW ~/ analysisWidth);
    final stepY = math.max(1, srcH ~/ analysisHeight);
    final outW = (srcW / stepX).ceil();
    final outH = (srcH / stepY).ceil();
    final gray = Uint8List(outW * outH);
    for (var y = 0; y < outH; y++) {
      final srcRow = y * stepY * rowStride;
      final dstRow = y * outW;
      for (var x = 0; x < outW; x++) {
        gray[dstRow + x] = bytes[srcRow + x * stepX];
      }
    }
    _frames.add(LiveFrame(width: outW, height: outH, gray: gray));
  }

  @override
  Future<Uint8List> captureStill() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('camera not initialised');
    }
    final file = await controller.takePicture();
    final bytes = await file.readAsBytes();
    try {
      await File(file.path).delete();
    } catch (_) {
      // A still left in the cache dir is harmless; never fail capture on it.
    }
    return bytes;
  }

  @override
  Widget? buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    return CameraPreview(controller);
  }

  @override
  Future<void> dispose() => _safeDispose();

  Future<void> _safeDispose() async {
    await stop();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {
        // Controller already gone — nothing to release.
      }
    }
    if (!_frames.isClosed) {
      await _frames.close();
    }
  }
}
