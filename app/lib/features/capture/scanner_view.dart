import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:omr_detect/omr_detect.dart'
    show CvPointI, LiveFrame, ScannerTick;

import 'capture_source.dart';

/// Turns one analysis frame into one scanner state — the injectable live
/// loop. On device this closes over a [LiveFrameAnalyzer]; widget tests
/// close over a script, keeping the widget dumb and the loop's logic in
/// omr_detect where it is unit-tested.
typedef FrameAnalyzerFn = ScannerTick Function(LiveFrame frame);

/// The scanner surface (plan §6 screen 6): A4 finder frame, live quad
/// overlay — green ONLY while every gate passes — coach hint in gate
/// priority order, dwell progress ring, and a manual shutter that is always
/// available.
///
/// The view owns the frame subscription, not the source: whoever constructed
/// it (screen/test) passes a started-or-startable [CaptureSource] and
/// disposes it. The shutter CONSEQUENCE (grading, the post-capture card)
/// lives in the parent via [onAutoCapture]/[onManualCapture].
class ScannerView extends StatefulWidget {
  const ScannerView({
    super.key,
    required this.source,
    required this.analyze,
    this.onAutoCapture,
    this.onManualCapture,
    this.enabled = true,
  });

  final CaptureSource source;
  final FrameAnalyzerFn analyze;

  /// Fired when the dwell completes on clean frames — the auto-shutter.
  final VoidCallback? onAutoCapture;

  /// Fired on the shutter button — always available (plan: never block the
  /// operator on automation).
  final VoidCallback? onManualCapture;

  /// Pauses analysis (post-capture card up, session between sheets).
  final bool enabled;

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  StreamSubscription<LiveFrame>? _subscription;
  ScannerTick? _tick;
  bool _shutterFired = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.source.frames.listen(_onFrame);
    widget.source.start();
  }

  @override
  void didUpdateWidget(ScannerView old) {
    super.didUpdateWidget(old);
    if (old.enabled && !widget.enabled) {
      // Post-capture pause: freeze the overlay as-is rather than dropping
      // to "searching", so the operator sees what they shot.
      return;
    }
    if (!old.enabled && widget.enabled) {
      _shutterFired = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onFrame(LiveFrame frame) {
    if (!widget.enabled || _shutterFired) return;
    final tick = widget.analyze(frame);
    if (!mounted) return;
    setState(() => _tick = tick);
    if (tick.autoShutter) {
      _shutterFired = true;
      widget.onAutoCapture?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tick = _tick;
    final hint = tick?.hint ??
        (tick != null && tick.lockedOn ? 'Hold steady…' : 'Find the sheet');
    final progress = tick?.hysteresis.progress ?? 0;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerPainter(
                analysisSize: widget.source.analysisSize,
                quad: tick?.quad,
                lockedOn: tick?.lockedOn ?? false,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            key: const ValueKey('scan_hint'),
            hint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SizedBox(
            key: const ValueKey('scan_progress'),
            height: 104,
            width: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 104,
                  width: 104,
                  child: progress > 0
                      ? CircularProgressIndicator(value: progress)
                      : null,
                ),
                FloatingActionButton.large(
                  key: const ValueKey('manual_shutter'),
                  onPressed: widget.enabled
                      ? () {
                          if (_shutterFired) return;
                          _shutterFired = true;
                          widget.onManualCapture?.call();
                        }
                      : null,
                  child: const Icon(Icons.camera),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dims everything outside the A4 finder, draws its corner brackets, and
/// paints the detected quad over it.
class _ScannerPainter extends CustomPainter {
  _ScannerPainter({
    required this.analysisSize,
    required this.quad,
    required this.lockedOn,
  });

  final Size analysisSize;
  final List<CvPointI>? quad;
  final bool lockedOn;

  @override
  void paint(Canvas canvas, Size size) {
    final finder = _finderRect(size);

    // Dim the desk around the finder.
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.45);
    void fillRect(double x, double y, double w, double h) {
      if (w > 0 && h > 0) canvas.drawRect(Offset(x, y) & Size(w, h), dim);
    }

    fillRect(0, 0, size.width, finder.top);
    fillRect(0, finder.bottom, size.width, size.height - finder.bottom);
    fillRect(0, finder.top, finder.left, finder.height);
    fillRect(finder.right, finder.top,
        size.width - finder.right, finder.height);

    _drawBrackets(canvas, finder);

    final q = quad;
    if (q != null) {
      // Analysis px → layout px, fill-stretched. The camera preview is
      // aspect-fitted by its widget; the residual mismatch shows as a few px
      // of overlay skew, tightened when the device leg (M0/M2) measures the
      // real transform.
      final path = Path()
        ..addPolygon(
          [
            for (final p in q)
              Offset(
                p.x * size.width / analysisSize.width,
                p.y * size.height / analysisSize.height,
              ),
          ],
          true,
        );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = lockedOn ? Colors.green : Colors.white;
      canvas.drawPath(path, paint);
    }
  }

  /// Largest centred A4-portrait rect that fits.
  Rect _finderRect(Size size) {
    const a4Aspect = 1 / math.sqrt2;
    double w = size.width, h = w / a4Aspect;
    if (h > size.height) {
      h = size.height;
      w = h * a4Aspect;
    }
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
  }

  void _drawBrackets(Canvas canvas, Rect r) {
    const arm = 28.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white70;

    /// An L from [corner] running along [h] then [v] (unit directions).
    void bracket(Offset corner, Offset h, Offset v) {
      final path = Path()
        ..moveTo(corner.dx + h.dx * arm, corner.dy + h.dy * arm)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(corner.dx + v.dx * arm, corner.dy + v.dy * arm);
      canvas.drawPath(path, paint);
    }

    bracket(r.topLeft, const Offset(1, 0), const Offset(0, 1));
    bracket(r.topRight, const Offset(-1, 0), const Offset(0, 1));
    bracket(r.bottomRight, const Offset(-1, 0), const Offset(0, -1));
    bracket(r.bottomLeft, const Offset(1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(_ScannerPainter old) =>
      old.quad != quad ||
      old.lockedOn != lockedOn ||
      old.analysisSize != analysisSize;
}
