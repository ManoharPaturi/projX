import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/capture/sheet_intake.dart';
import 'package:omr_app/features/capture/still_evaluator.dart';
import 'package:omr_app/features/review/review_queue_screen.dart';
import 'package:omr_app/src/app_state.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_detect/omr_detect.dart' as detect;
import 'package:omr_reports/omr_reports.dart';

import 'helpers.dart';

class _CleanRead implements StillEvaluator {
  _CleanRead(this.roll);

  final String roll;

  @override
  Future<detect.StillEvaluation> evaluate(
    String examId,
    Uint8List bytes,
  ) async => detect.StillEvaluation(
    read: core.SheetRead(
      responses: const {},
      sheetConfidence: 0.97,
      rollNoRead: roll,
      setCodeRead: 'A',
    ),
    fields: const [],
    registrationPath: detect.RegistrationPath.fiducialQuadrant,
    trace: const [],
  );
}

/// A second sheet carrying an already-scanned roll used to be dropped from
/// grading without a word (first capture won). It now waits for a human.
void main() {
  late AppState state;
  late SeededExam seeded;

  setUp(() async {
    state = await seededAppState();
    seeded = await seedExamWithRoster(state, students: 1);
  });

  tearDown(() => state.db.close());

  Future<CapturedSheet> scan() =>
      SheetIntake(
        state.db,
        evaluator: _CleanRead(seeded.rollNoByIndex.first),
      ).process(
        tenantId: state.tenantId,
        examId: seeded.examId,
        stillBytes: Uint8List(0),
      );

  testWidgets('second sheet for a roll is held for review, then replaces the '
      'first once confirmed', (tester) async {
    final first = (await tester.runAsync(scan))!;
    final second = (await tester.runAsync(scan))!;

    expect(first.needsReview, isFalse);
    // The first scanned sheet starts the exam.
    expect(
      (await state.db.examsDao.byId(seeded.examId))!.status.name,
      'active',
    );
    expect(second.needsReview, isTrue);
    expect(second.reasons, ['DUPLICATE_SHEET']);

    await tester.pumpWidget(wrapForTest(const ReviewQueueScreen(), state));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This student already has a scanned sheet'),
      findsOneWidget,
    );
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // Nothing specific to fix: the human's look is the confirmation.
    await tester.tap(find.text('Sheet looks right — mark it'));
    await tester.pumpAndSettle();

    final rows = await ResultsQuery(
      state.db,
      examId: seeded.examId,
      keyVersionId: seeded.keyVersionId,
    ).rows();
    expect(rows.single.scanId, second.scanId);
  });
}
