import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';
import 'package:omr_detect/omr_detect.dart'
    show LiveFrameAnalyzer, OpencvDartImpl;
import 'package:omr_spec/omr_spec.dart' show pxPerMm;
import 'package:provider/provider.dart';

import '../../src/app_state.dart';
import '../../src/demo_scans.dart';
import 'capture_source.dart';
import 'scanner_view.dart';
import 'sheet_intake.dart';
import 'still_evaluator.dart';

/// Plan §6 screen 6 — the auto-capture scanner.
///
/// The scanner surface ([ScannerView]) runs whenever a [CaptureSource] is
/// available: injected for tests, the back camera on device, absent on
/// desktops/emulators where the fixture buttons below carry the same
/// post-shutter path. The shutter consequence — read → grade → card — is one
/// code path regardless of what fired it (dwell or the manual button):
/// [SheetIntake.process] on the captured still.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    super.key,
    this.source,
    this.analyze,
    this.evaluator,
  });

  /// Test seam: a hand-driven source plus the frame script that turns its
  /// frames into scanner states. Injected sources are owned by the caller
  /// (this screen only starts/stops them).
  final CaptureSource? source;
  final FrameAnalyzerFn? analyze;

  /// Test seam for the still pipeline: canned evaluations in place of
  /// decode + register + read. The device runs [OmrStillEvaluator].
  final StillEvaluator? evaluator;

  static const String routeName = '/capture';

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  List<Exam>? _exams;
  Exam? _exam;
  bool _busy = false;
  _CapturedCard? _lastCard;

  /// Camera probe finished (device path only).
  bool _cameraTried = false;

  /// Owned by this screen when it booted the camera itself.
  CameraCaptureSource? _ownedSource;
  FrameAnalyzerFn? _analyze;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    state.db.examsDao
        .forInstitute(state.tenantId, state.instituteId)
        .then((exams) {
      if (!mounted) {
        return;
      }
      setState(() {
        _exams = exams;
        _exam = exams.isNotEmpty ? exams.first : null;
      });
      _syncAnalyzer();
    });
    if (widget.source != null) {
      assert(widget.analyze != null,
          'an injected source needs its analyze script');
      _analyze = widget.analyze;
      _cameraTried = true;
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
        _ownedSource = source;
      }
    });
    // The live loop binds once the exam (and so its template) is known.
    await _syncAnalyzer();
  }

  /// Binds the device analyzer, whose resolution gate needs the SELECTED
  /// exam's capture floor: sheet px on the still = canvas px ÷ px/mm × the
  /// template's minimum px/mm on capture. Re-run when the exam changes —
  /// a denser layout raises the floor.
  Future<void> _syncAnalyzer() async {
    if (widget.analyze != null) {
      return; // injected script wins
    }
    final exam = _exam;
    if ((_ownedSource ?? widget.source) == null || exam == null) {
      return;
    }
    // Read before the first await: this method runs on the heels of a
    // mounted check, and the spec load below must not re-reach the context.
    final db = context.read<AppState>().db;
    final template = await GradingService(db).templateFor(exam.id);
    if (!mounted || _exam != exam) {
      return; // the dropdown moved on while the spec loaded
    }
    setState(() {
      _analyze = LiveFrameAnalyzer(
        cv: OpencvDartImpl(),
        requiredSheetPxOnStill:
            template.canvasWidth / pxPerMm * template.minPxPerMmOnCapture,
      ).update;
    });
  }

  @override
  void dispose() {
    _ownedSource?.dispose();
    super.dispose();
  }

  /// The shutter consequence — identical for auto and manual fires: the
  /// still goes through the full intake (read → persist → route → grade)
  /// and the card shows what came back.
  Future<void> _onShutter() async {
    final source = widget.source ?? _ownedSource;
    final exam = _exam;
    if (source == null || exam == null || _busy) {
      return;
    }
    setState(() => _busy = true);
    final state = context.read<AppState>();
    try {
      final Uint8List still;
      try {
        still = await source.captureStill();
      } catch (error) {
        _snack('capture failed: $error');
        return;
      }
      await source.stop();

      final captured = await SheetIntake(
        state.db,
        evaluator: widget.evaluator,
      ).process(
        tenantId: state.tenantId,
        examId: exam.id,
        stillBytes: still,
      );
      state.refresh();
      if (!mounted) {
        return;
      }
      setState(() => _lastCard = _CapturedCard(captured));
    } catch (error) {
      // Infra failures only (decode, DB) — the operator re-shoots.
      _snack('$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _insertFixtureSheet({required bool flagged}) async {
    if (_exam == null) {
      return;
    }
    // The fixture buttons arrive idle and drive the same progress UI.
    setState(() => _busy = true);
    try {
      final state = context.read<AppState>();
      final db = state.db;
      final keyVersion = await db.keysDao.activeVersion(_exam!.id);

      // Fixture stand-in for "point at the next sheet": the first roster
      // student without a scan in this exam.
      final roster = await db.studentsDao.rosterFor(state.instituteId);
      final existing = await (db.select(db.scans)
            ..where((Scans s) => s.examId.equals(_exam!.id)))
          .get();
      final takenRolls = existing
          .map((s) => s.rollNoRead)
          .nonNulls
          .toSet();
      final student = roster.firstWhere(
        (s) => !takenRolls.contains(s.rollNo),
        orElse: () =>
            roster.isEmpty ? throw StateError('empty roster') : roster.first,
      );

      final scanId = await insertDemoScan(
        db: db,
        examId: _exam!.id,
        studentId: student.id,
        rollNo: student.rollNo,
        studentIndex: roster.indexOf(student),
        flaggedForReview: flagged,
      );

      // Full grading pass so results/reports reflect the new sheet at once.
      if (keyVersion != null && !flagged) {
        await GradingService(db).gradeExam(
          tenantId: state.tenantId,
          examId: _exam!.id,
          keyVersionId: keyVersion.id,
        );
      }

      _CapturedCard? card;
      if (keyVersion != null) {
        // The instant post-capture card: grade this ONE scan.
        final result = await GradingService(db).gradeScan(
          examId: _exam!.id,
          keyVersionId: keyVersion.id,
          scanId: scanId,
        );
        card = _CapturedCard(
          CapturedSheet(
            scanId: scanId,
            rollNoRead: student.rollNo,
            setCodeRead: 'A',
            result: result,
            needsReview: flagged,
            reasons: const [],
          ),
        );
      }
      state.refresh();
      if (!mounted) {
        return;
      }
      setState(() => _lastCard = card);
    } catch (error) {
      _snack('$error');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source ?? _ownedSource;
    final analyze = _analyze;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan sheets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_exams != null && _exams!.isNotEmpty) ...[
            DropdownButtonFormField<Exam>(
              decoration: const InputDecoration(labelText: 'Exam'),
              items: [
                for (final exam in _exams!) DropdownMenuItem(value: exam, child: Text(exam.name)),
              ],
              initialValue: _exam,
              onChanged: (exam) {
                setState(() => _exam = exam);
                _syncAnalyzer();
              },
            ),
            const SizedBox(height: 16),
          ],
          if (source != null && analyze != null && _exam != null) ...[
            SizedBox(
              height: 440,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    source.buildPreview() ??
                        const ColoredBox(color: Color(0xFF10151A)),
                    ScannerView(
                      source: source,
                      analyze: analyze,
                      enabled: !_busy && _lastCard == null,
                      onAutoCapture: _onShutter,
                      onManualCapture: _onShutter,
                    ),
                  ],
                ),
              ),
            ),
            if (_busy) const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          ] else if (_cameraTried) ...[
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_outlined),
                        SizedBox(width: 8),
                        Text(
                          'No camera available here',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The live scanner needs this device\'s back camera. '
                      'The buttons below insert fixture sheets through the '
                      'same read → grade → review → report path the shutter '
                      'feeds.',
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (source == null && _cameraTried) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy || _exam == null
                  ? null
                  : () => _insertFixtureSheet(flagged: false),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Insert fixture sheet (clean)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy || _exam == null
                  ? null
                  : () => _insertFixtureSheet(flagged: true),
              icon: const Icon(Icons.warning_amber),
              label: const Text('Insert fixture sheet (multi-mark → review)'),
            ),
          ],
          if (_lastCard != null) ...[
            const SizedBox(height: 16),
            _lastCard!,
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      // Next sheet, same session: re-arm the scanner (the
                      // dwell restarts; the blur norm carries — same desk,
                      // same light).
                      setState(() => _lastCard = null);
                      await (widget.source ?? _ownedSource)?.start();
                    },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Scan next sheet'),
            ),
          ],
        ],
      ),
    );
  }
}

/// The post-capture card (plan §6 screen 6): the READ identity — roll and
/// set as bubbled, not as the roster guessed — the instant grade when a key
/// exists, and the review routing when the read earned it. One shape for
/// the shutter path and the fixture buttons.
class _CapturedCard extends StatelessWidget {
  const _CapturedCard(this.captured);

  final CapturedSheet captured;

  @override
  Widget build(BuildContext context) {
    final grade = captured.result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    captured.rollNoRead ?? 'roll unread',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _confidenceChip(context),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              captured.setCodeRead == null
                  ? 'Set not read'
                  : 'Set ${captured.setCodeRead}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (captured.reasons.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                captured.reasons.join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            if (grade != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('Total', grade.totalMarks.toStringAsFixed(0)),
                  _stat(
                    'Correct',
                    '${grade.outcomeCounts[core.QuestionOutcomeKind.correct] ?? 0}',
                  ),
                  _stat(
                    'Wrong',
                    '${grade.outcomeCounts[core.QuestionOutcomeKind.wrong] ?? 0}',
                  ),
                  _stat(
                    'Skipped',
                    '${grade.outcomeCounts[core.QuestionOutcomeKind.unattempted] ?? 0}',
                  ),
                ],
              )
            else
              Text(
                captured.needsReview
                    ? 'Routed to review — graded after confirmation.'
                    : 'No answer key yet — not graded.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _confidenceChip(BuildContext context) {
    final review = captured.needsReview;
    final color = review ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        review ? 'needs review' : 'auto-graded',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
