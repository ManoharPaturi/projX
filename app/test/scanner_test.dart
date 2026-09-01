import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/capture/capture_screen.dart';
import 'package:omr_app/features/capture/capture_source.dart';
import 'package:omr_app/features/capture/scanner_view.dart';
import 'package:omr_app/features/capture/still_evaluator.dart';
import 'package:omr_app/src/app_state.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_detect/omr_detect.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

/// The scanner surface over a hand-driven source: coach hint from the first
/// failing gate, dwell progress to the auto-shutter, manual shutter always
/// available, and the post-capture card off the SAME shutter consequence.
///
/// The frame script fakes [ScannerTick]s and the evaluator fakes the still
/// read — the real loop's and pipeline's logic each have their own suites —
/// so these tests pin the WIRING: ticks in, hints and shutter consequences
/// out.
void main() {
  late AppState state;

  setUp(() async {
    state = await seededAppState();
    await seedExamWithRoster(state);
  });

  tearDown(() => state.db.close());

  /// Five gate results, all passing unless [failHint] names one that fails
  /// with that hint.
  ScannerTick tick({
    String? failHint,
    double progress = 0,
    bool tracking = false,
    bool triggered = false,
  }) {
    GateResult gate(GateType type) => GateResult(
          type: type,
          passed: failHint == null,
          hint: failHint ?? '',
        );

    return ScannerTick(
      quad: null,
      gates: [
        gate(GateType.area),
        gate(GateType.angle),
        gate(GateType.blur),
        gate(GateType.exposure),
        gate(GateType.resolution),
      ],
      hysteresis: HysteresisState(
        progress: progress,
        stableCount: (progress * 35).round(),
        tracking: tracking,
        triggered: triggered,
      ),
    );
  }

  Widget host(
    CaptureSource source,
    FrameAnalyzerFn analyze, {
    StillEvaluator? evaluator,
  }) =>
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          home: CaptureScreen(
            source: source,
            analyze: analyze,
            evaluator: evaluator,
          ),
        ),
      );

  /// Screen up, exam dropdown loaded, scanner mounted and subscribed —
  /// frames pushed before this would drop on the floor (broadcast stream,
  /// no listener yet).
  Future<void> mounted(WidgetTester tester) async {
    await tester.pump();
    await tester.pumpAndSettle();
  }


  /// One gray frame — content irrelevant, the script supplies the verdict.
  LiveFrame blankFrame() => LiveFrame(
        width: 640,
        height: 480,
        gray: Uint8List(640 * 480),
      );

  /// Canned still reads, one per capture: each shutter consumes the next
  /// roll, so the "scan next sheet" flow advances students as on device.
  /// Empty fields = nothing flagged; the intake persists the scan, grades
  /// it all-unattempted, and the card shows the read roll.
  _ScriptedEvaluator fakeEvaluator(List<String> rolls) => _ScriptedEvaluator([
        for (final roll in rolls)
          () => StillEvaluation(
                read: core.SheetRead(
                  responses: const {},
                  sheetConfidence: 0.95,
                  rollNoRead: roll,
                  setCodeRead: 'A',
                ),
                fields: const [],
                registrationPath: RegistrationPath.fiducialQuadrant,
                trace: const [],
              ),
      ]);

  testWidgets('failing gate coaches its hint; dwell stays empty', (tester) async {
    final source = SimulatedCaptureSource();
    final ticks = <ScannerTick>[
      tick(failHint: 'move closer — sheet too small in frame'),
    ];
    var index = 0;
    await tester.pumpWidget(host(
      source,
      (frame) => ticks[index++],
    ));
    await mounted(tester);

    source.push(blankFrame());
    // Stream delivery lands a frame later than the first pump builds; the
    // second pump carries the analyzer's verdict into the tree.
    await tester.pump();
    await tester.pump();

    expect(find.text('move closer — sheet too small in frame'),
        findsOneWidget);
    // The ring only exists once the dwell moves; a starved dwell builds no
    // indicator at all.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scan_progress')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
  });

  testWidgets('dwell completes → auto-shutter → post-capture card',
      (tester) async {
    final source = SimulatedCaptureSource();
    source.armStill(Uint8List.fromList([1, 2, 3]));

    // 35 clean ticks ramping the ring, then the trigger.
    final script = <ScannerTick>[
      for (var i = 1; i <= 35; i++)
        tick(progress: i / 35, tracking: i >= 3),
      tick(progress: 0, tracking: true, triggered: true),
    ];
    var index = 0;
    await tester.pumpWidget(host(source, (frame) {
      // Clamp: never run off the script while the card settles.
      return script[index < script.length ? index++ : script.length - 1];
    }, evaluator: fakeEvaluator(['R001'])));
    await mounted(tester);

    for (var i = 0; i < 36; i++) {
      source.push(blankFrame());
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // The shutter consequence ran: the card shows the READ roll with the
    // auto-graded chip. The card sits below the fold of the 600px test
    // surface (scanner is 440 of it), so these look past the viewport —
    // on device the operator scrolls to it.
    expect(find.text('R001', skipOffstage: false), findsOneWidget);
    expect(find.text('auto-graded', skipOffstage: false), findsOneWidget);
    expect(find.text('Scan next sheet', skipOffstage: false), findsOneWidget);
  });

  testWidgets('manual shutter always works, mid-dwell', (tester) async {
    final source = SimulatedCaptureSource();
    source.armStill(Uint8List.fromList([9]));

    await tester.pumpWidget(host(
      source,
      (frame) => tick(progress: 0.2, tracking: true),
      evaluator: fakeEvaluator(['R001']),
    ));
    await mounted(tester);

    source.push(blankFrame());
    // Same delivery lag as the hint test: the second pump renders the tick
    // before the operator's thumb lands.
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('manual_shutter')));
    await tester.pumpAndSettle();

    expect(find.text('R001', skipOffstage: false), findsOneWidget);
    expect(find.text('auto-graded', skipOffstage: false), findsOneWidget);
  });

  testWidgets('scan next sheet re-arms the scanner for the following student',
      (tester) async {
    final source = SimulatedCaptureSource();
    source.armStill(Uint8List.fromList([1]));

    final script = <ScannerTick>[
      for (var i = 1; i <= 35; i++)
        tick(progress: i / 35, tracking: i >= 3),
      tick(progress: 0, tracking: true, triggered: true),
    ];
    var index = 0;
    await tester.pumpWidget(host(source, (frame) {
      return script[index < script.length ? index++ : script.length - 1];
    }, evaluator: fakeEvaluator(['R001', 'R002'])));
    await mounted(tester);

    // First capture.
    for (var i = 0; i < 36; i++) {
      source.push(blankFrame());
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('R001', skipOffstage: false), findsOneWidget);

    // Next sheet: card clears, dwell restarts, second student captures.
    // The button is below the fold — bring it on-screen before tapping.
    await tester.scrollUntilVisible(
      find.text('Scan next sheet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Scan next sheet'));
    await tester.pumpAndSettle();
    expect(find.text('R001', skipOffstage: false), findsNothing);

    index = 0;
    for (var i = 0; i < 36; i++) {
      source.push(blankFrame());
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('R002', skipOffstage: false), findsOneWidget);
  });
}

/// Yields one canned [StillEvaluation] per call, in order; past the script
/// it repeats the last (a session scanning more sheets than scripted).
class _ScriptedEvaluator implements StillEvaluator {
  _ScriptedEvaluator(this._evaluations);

  final List<StillEvaluation Function()> _evaluations;
  var _next = 0;

  @override
  Future<StillEvaluation> evaluate(String examId, Uint8List stillBytes) async {
    final i = _next < _evaluations.length ? _next++ : _evaluations.length - 1;
    return _evaluations[i]();
  }
}
