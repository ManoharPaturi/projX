import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/capture/capture_screen.dart';
import 'package:omr_app/features/capture/capture_source.dart';
import 'package:omr_app/features/capture/sheet_intake.dart';
import 'package:omr_app/features/capture/still_evaluator.dart';
import 'package:omr_app/src/app_state.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';
import 'package:omr_detect/omr_detect.dart' as detect;
import 'package:omr_detect/testing.dart'
    show inkAt, renderSheetPhoto;
import 'package:omr_spec/omr_spec.dart' show BlockType;

import 'helpers.dart';

/// End-to-end over the capture feature — the two legs of task M2's
/// "scan ⇒ graded result":
///
/// 1. the shutter through the WHOLE screen wiring (scanner → intake →
///    persistence → review routing) with a scripted evaluation carrying a
///    read flag, asserting what landed in the DB and on the card;
/// 2. REAL JPEG bytes through the real evaluator — synthetic sheet photo →
///    encodeGrayJpeg → decodeStill → register → read → intake → graded
///    result — the same seam the camera's takePicture feeds on device.
void main() {
  late AppState state;
  late String examId;

  setUp(() async {
    state = await seededAppState();
    examId = (await seedExamWithRoster(state)).examId;
  });

  tearDown(() => state.db.close());

  testWidgets(
    'flagged read through the shutter: scan stored, review queued, '
    'marks withheld',
    (tester) async {
      final source = SimulatedCaptureSource();
      source.armStill(Uint8List.fromList([1, 2, 3]));

      // One field, two dark bubbles: the read the decoder flags.
      detect.FieldRead doubleMarkedField() => detect.FieldRead(
            fieldKey: 'q3',
            blockId: 'mcq_col1',
            blockType: BlockType.mcq,
            bubbles: [
              for (final (i, zone) in [
                (0, detect.BubbleZone.filled),
                (1, detect.BubbleZone.filled),
                (2, detect.BubbleZone.empty),
                (3, detect.BubbleZone.empty),
              ])
                detect.BubbleRead(
                  sample: detect.BubbleSample(
                    fieldKey: 'q3',
                    blockId: 'mcq_col1',
                    blockType: BlockType.mcq,
                    optionIndex: i,
                    optionValue: String.fromCharCode(65 + i),
                    meanIntensity: zone == detect.BubbleZone.filled ? 30 : 220,
                    fillRatio: 0,
                  ),
                  thresholdUsed: 120,
                  zone: zone,
                  confidence: 0.9,
                ),
            ],
            markClass: detect.MarkClass.multiple,
          );
      final evaluation = detect.StillEvaluation(
        read: core.SheetRead(
          responses: const {},
          sheetConfidence: 0.95,
          rollNoRead: 'R001',
          setCodeRead: 'A',
          flags: const {core.SheetReadFlag.multiMarkedField},
        ),
        fields: [doubleMarkedField()],
        registrationPath: detect.RegistrationPath.fiducialQuadrant,
        trace: const [],
      );
      final evaluator = _SingleShotEvaluator(evaluation);

      // Dwell to the auto-shutter, as the scanner tests do.
      detect.ScannerTick tick(double progress, bool triggered) =>
          detect.ScannerTick(
            quad: null,
            gates: [
              for (final t in detect.GateType.values)
                detect.GateResult(type: t, passed: true, hint: ''),
            ],
            hysteresis: detect.HysteresisState(
              progress: progress,
              stableCount: (progress * 35).round(),
              tracking: true,
              triggered: triggered,
            ),
          );
      final script = [
        for (var i = 1; i <= 35; i++) tick(i / 35, false),
        tick(0, true),
      ];
      var index = 0;
      await tester.pumpWidget(wrapForTest(
        CaptureScreen(
          source: source,
          analyze: (frame) =>
              script[index < script.length ? index++ : script.length - 1],
          evaluator: evaluator,
        ),
        state,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      final frame = detect.LiveFrame(
        width: 640,
        height: 480,
        gray: Uint8List(640 * 480),
      );
      for (var i = 0; i < 36; i++) {
        source.push(frame);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // The card says review, with the reason spelled out.
      expect(find.text('needs review', skipOffstage: false), findsOneWidget);
      expect(
        find.textContaining('MULTI_BUBBLE_WARN', skipOffstage: false),
        findsOneWidget,
      );

      // The scan persisted with its reads and the review routing.
      final db = state.db;
      final scan = await (db.select(db.scans)
            ..where((Scans s) => s.rollNoRead.equals('R001')))
          .getSingle();
      expect(scan.status, ScanStatus.needsReview);
      expect(scan.setCodeRead, 'A');

      final reviewRows = await (db.select(db.reviewQueue)
            ..where((ReviewQueue r) => r.scanId.equals(scan.id)))
          .get();
      expect(reviewRows, hasLength(1));
      expect(reviewRows.single.reasonCode, 'MULTI_BUBBLE_WARN');
      expect(reviewRows.single.severity, ReviewSeverity.high);
      expect(reviewRows.single.fieldRefsJson, contains('q3'));

      // Both marks persisted as filled — the substrate review corrects.
      final q3 = await (db.select(db.bubbleReads)
            ..where((BubbleReads b) =>
                b.scanId.equals(scan.id) & b.fieldKey.equals('q3')))
          .get();
      expect(
        q3
            .where((b) => b.markClass == MarkClass.filled)
            .map((b) => b.optionIndex),
        [0, 1],
      );

      // Marks withheld: gradeExam skips review-routed scans entirely.
      final results = await (db.select(db.results)
            ..where((Results r) => r.examId.equals(examId)))
          .get();
      expect(results, isEmpty);
    },
  );

  test('real path: JPEG bytes through the pipeline → stored, graded', () async {
    // The roster must carry the roll the sheet bubbles (7 digits + a
    // checksum digit the decoder validates but strips).
    await state.db.studentsDao.importRoster(
      state.tenantId,
      state.instituteId,
      [RosterEntry(rollNo: '0000073')],
    );

    final cv = detect.OpencvDartImpl();
    final template = await GradingService(state.db).templateFor(examId);

    // q1='C' (key 'A' → wrong), q2='A' (key 'B' → wrong), set='B', roll
    // 0000073 with checksum 6 — pipeline_test's proven happy fixture.
    final marks = [
      inkAt(template, 'q1', 'C'),
      inkAt(template, 'q2', 'A'),
      inkAt(template, 'set', 'B'),
      for (final (i, d) in ['0', '0', '0', '0', '0', '7', '3', '6'].indexed)
        inkAt(template, 'roll${i + 1}', d),
    ];
    final photo = renderSheetPhoto(
      cv,
      template,
      imageWidth: 1200,
      imageHeight: 1600,
      marks: marks,
    );
    final jpeg = cv.encodeGrayJpeg(1200, 1600, photo);

    final captured = await SheetIntake(
      state.db,
      evaluator: OmrStillEvaluator(state.db, cv: cv),
    ).process(
      tenantId: state.tenantId,
      examId: examId,
      stillBytes: jpeg,
    );

    expect(captured.rollNoRead, '0000073');
    expect(captured.setCodeRead, 'B');
    expect(captured.needsReview, isFalse, reason: 'clean sheet, clean roll');
    expect(captured.reasons, isEmpty);
    expect(captured.result, isNotNull);
    expect(captured.result!.totalMarks, -2); // two wrong at −1
    expect(
      captured.result!.outcomeCounts[core.QuestionOutcomeKind.unattempted],
      88,
    );

    final db = state.db;
    final scan = await (db.select(db.scans)
          ..where((Scans s) => s.rollNoRead.equals('0000073')))
        .getSingle();
    expect(scan.status, ScanStatus.graded);
    expect(scan.layoutVersion, template.layoutVersion);
    expect(scan.studentId, isNotNull,
        reason: 'roster roll resolved the student');

    // The re-grade substrate: every bubble of the sheet persisted.
    final reads = await (db.select(db.bubbleReads)
          ..where((BubbleReads b) => b.scanId.equals(scan.id)))
        .get();
    expect(reads, isNotEmpty);
    expect(
      q1Of(reads, 2).markClass,
      MarkClass.filled,
      reason: "q1 'C' read as filled",
    );

    // And the ranked, persisted pass wrote this student's result.
    final results = await (db.select(db.results)
          ..where((Results r) => r.scanId.equals(scan.id)))
        .get();
    expect(results, hasLength(1));
    expect(results.single.total, -2.0);
  });
}

/// The bubble row for [optionIndex] within field `q1`'s reads.
BubbleRead q1Of(List<BubbleRead> reads, int optionIndex) => reads.singleWhere(
      (b) => b.fieldKey == 'q1' && b.optionIndex == optionIndex,
    );

/// One canned evaluation, every call — a single-sheet session.
class _SingleShotEvaluator implements StillEvaluator {
  _SingleShotEvaluator(this._evaluation);

  final detect.StillEvaluation _evaluation;

  @override
  Future<detect.StillEvaluation> evaluate(
    String examId,
    Uint8List stillBytes,
  ) async => _evaluation;
}
