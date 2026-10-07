import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_detect/omr_detect.dart';
import 'package:omr_spec/omr_spec.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../capture/capture_source.dart';

/// The analyze seam, injectable like the scanner's [FrameAnalyzerFn]:
/// still bytes in, margin report out. The device runs the real decoder +
/// [CalibrationAnalyzer]; tests inject a canned report.
typedef CalibrationAnalyzeFn =
    Future<CalibrationReport> Function(Uint8List stillBytes);

/// Plan §6 screen 11 / §9 SOP: print the calibration sheet, photograph it
/// with the SAME capture path production sheets use, and read the per-band
/// margin report. A pass is evidence about the real read path — the
/// analyzer registers the same fiducials and measures the same bubble ROIs.
///
/// On devices without a camera (emulator) the print leg still works; the
/// photo leg says so instead of pretending.
class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key, this.stillSource, this.analyze});

  /// Test seam: armed still bytes in place of the camera.
  final Future<Uint8List> Function()? stillSource;

  /// Test seam: canned margin reports.
  final CalibrationAnalyzeFn? analyze;

  static const String routeName = '/calibration';

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  bool _busy = false;
  CalibrationReport? _report;
  String? _error;
  bool _cameraTried = false;
  bool _cameraReady = false;

  CameraCaptureSource? _ownedSource;

  @override
  void initState() {
    super.initState();
    if (widget.stillSource != null) {
      _cameraTried = true;
      _cameraReady = true;
    } else {
      _bootCamera();
    }
  }

  Future<void> _bootCamera() async {
    final source = CameraCaptureSource();
    final ready = await source.initialize();
    if (!mounted) {
      await source.dispose();
      return;
    }
    setState(() {
      _cameraTried = true;
      if (ready) {
        _cameraReady = true;
        _ownedSource = source;
      }
    });
  }

  @override
  void dispose() {
    _ownedSource?.dispose();
    super.dispose();
  }

  /// The production analysis: decode the still, register the calibration
  /// sheet's own fiducials, measure the reference bubbles.
  Future<CalibrationReport> _deviceAnalyze(Uint8List stillBytes) async {
    final cv = OpencvDartImpl();
    final template = compileDetectionTemplate(buildCalibrationSpec());
    final decoded = cv.decodeStill(stillBytes);
    return CalibrationAnalyzer().analyze(
      cv: cv,
      template: template,
      imageWidth: decoded.width,
      imageHeight: decoded.height,
      grayBytes: decoded.gray,
    );
  }

  Future<void> _printSheet() async {
    setState(() => _busy = true);
    try {
      final sheet = buildCalibrationSheet();
      final pdf = await compileSheetPdf(
        sheet.spec,
        bubbleFills: sheet.fills,
        examTitle: 'Printer check',
      );
      await Printing.layoutPdf(
        name: 'omr-calibration',
        onLayout: (_) async => pdf,
      );
    } catch (error) {
      _snack('print failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Uint8List still;
      final owned = _ownedSource;
      if (widget.stillSource != null) {
        still = await widget.stillSource!();
      } else if (owned != null) {
        await owned.start();
        try {
          still = await owned.captureStill();
        } finally {
          await owned.stop();
        }
      } else {
        throw StateError('no camera on this device');
      }
      final report = await (widget.analyze ?? _deviceAnalyze)(still);
      if (mounted) setState(() => _report = report);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('Printer check')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Do this once for each new printer, paper or photocopier, '
                'to make sure its sheets read correctly.\n\n'
                '1. Print the test sheet at 100% size (not "Fit to page").\n'
                '2. Lay it flat in even light and take its photo here.',
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.print_outlined),
                  title: const Text('1. Print the test sheet'),
                  subtitle: const Text(
                    'One page with bubbles printed at different darkness',
                  ),
                  enabled: !_busy,
                  onTap: _printSheet,
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('2. Take its photo and check'),
                  subtitle: Text(
                    _cameraTried && !_cameraReady
                        ? 'Camera not available — allow camera access in '
                              'phone Settings'
                        : 'The result appears below in a few seconds',
                  ),
                  enabled: !_busy && _cameraReady,
                  onTap: _captureAndAnalyze,
                ),
              ],
            ),
          ),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          if (report != null) ...[
            _VerdictCard(report: report),
            Card(
              child: ExpansionTile(
                title: const Text('Technical details'),
                children: [
                  ListTile(title: Text(report.summary)),
                  for (final region in report.regions)
                    ListTile(
                      leading: const Icon(Icons.straighten),
                      title: Text(
                        'Band ${region.band.toUpperCase()} · '
                        '${region.samples} samples',
                      ),
                      subtitle: Text(
                        'separation ${region.separation.toStringAsFixed(0)} '
                        '· split at ${region.threshold.toStringAsFixed(0)} '
                        '· faint at ${region.faintMean.toStringAsFixed(0)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.report});

  final CalibrationReport report;

  @override
  Widget build(BuildContext context) {
    // Dark-filled verdict chip with white bold text (WCAG AA — the 500
    // green and amber shades were under 3:1), and a semantics label so the
    // verdict is announced, not just colored.
    final (color, label, spoken, advice) = switch (report.overall) {
      CalibrationVerdict.comfortable => (
        const Color(0xFF1B5E20),
        'GOOD',
        'Printer check passed',
        'Sheets from this printer read well. You are ready to go.',
      ),
      CalibrationVerdict.tight => (
        const Color(0xFF8B4000),
        'OK',
        'Printer check: usable',
        'Usable, but faint marks may need more checking. Use the '
            'suggested setting below.',
      ),
      CalibrationVerdict.failed => (
        Theme.of(context).colorScheme.error,
        'POOR',
        'Printer check failed',
        'Sheets from this printer may be misread. Try another printer, '
            'better paper, or print instead of photocopying — then check '
            'again.',
      ),
    };
    final state = context.read<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  label: spoken,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    advice,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (report.registrationOk &&
                report.overall != CalibrationVerdict.comfortable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.tune),
                  label: Text(
                    'Use the suggested setting '
                    '(${report.suggestedStrictness})',
                  ),
                  onPressed: () async {
                    await SettingsDao(state.db).write(
                      tenantId: state.tenantId,
                      strictness: report.suggestedStrictness,
                    );
                    state.refresh();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Photo quality check set to '
                          '${report.suggestedStrictness}',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
