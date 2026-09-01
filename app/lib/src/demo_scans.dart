import 'package:drift/drift.dart' show Value;
import 'package:omr_data/omr_data.dart';

import 'db/open_db.dart';

/// Dev fixture behind the capture screen's stub (plan §6 screen 6): while the
/// OpenCV pipeline is blocked on a full Xcode install, these fabricate scans
/// with believable bubble reads so grading, review, results and reports are
/// exercisable on-device end to end. Deterministic — no RNG — so a flow test
/// can assert on the marks it produces.
///
/// The reads use the same `bubble_reads` substrate a real capture writes, so
/// everything downstream (grading, corrections, re-grade, reports) is the
/// production path, not a parallel demo path.
Future<String> insertDemoScan({
  required AppDb db,
  required String examId,
  required String studentId,
  required String rollNo,
  required int studentIndex,
  bool flaggedForReview = false,
}) async {
  final layout = await GradingService(db).layoutContextFor(examId);
  final reads = <BubbleReadInput>[];

  for (var i = 0; i < layout.questionOrder.length; i++) {
    final fieldKey = layout.questionOrder[i];
    final optionCount = layout.optionValuesByField[fieldKey]?.length ?? 4;
    // ~60% attempted, spread deterministically per (student, question).
    // The flagged variant force-attempts its flagged question so the
    // multi-mark actually lands on the field the review item points at.
    final attempted =
        (flaggedForReview && i == 4) ||
        ((i * 7 + studentIndex * 13) % 10) < 6;
    final option = (i + studentIndex) % optionCount;
    // Every bubble of every question gets a read — the same shape stage 6-8
    // of the real pipeline persists — so review sees the full row, not just
    // the mark.
    for (var o = 0; o < optionCount; o++) {
      final filled =
          attempted &&
          (o == option || (flaggedForReview && i == 4 && o == (option + 1) % optionCount));
      reads.add(
        BubbleReadInput(
          fieldKey: fieldKey,
          optionIndex: o,
          markClass: filled ? MarkClass.filled : MarkClass.empty,
          meanIntensity: filled ? 92 : 240,
          fillRatio: filled ? 0.9 : 0.05,
          confidence: filled ? 0.93 : 0.95,
        ),
      );
    }
  }

  final flaggedField = layout.questionOrder.isNotEmpty
      ? layout.questionOrder[4]
      : 'q5';

  final scanId = await db.scansDao.insertScanWithReads(
    ScansCompanion.insert(
      tenantId: kTenantId,
      examId: examId,
      studentId: Value(studentId),
      rollNoRead: Value(rollNo),
      rollConfidence: const Value(0.97),
      setCodeRead: const Value('A'),
      layoutVersion: layout.layoutVersion,
      // Demo fixtures have no image files; the sentinel keeps NOT NULL happy.
      warpedImagePath: 'demo://warped',
      thumbPath: 'demo://thumb',
      annotatedPath: 'demo://annotated',
      sheetConfidence: Value(flaggedForReview ? 0.82 : 0.94),
      status: Value(
        flaggedForReview ? ScanStatus.needsReview : ScanStatus.graded,
      ),
    ),
    reads,
  );

  if (flaggedForReview) {
    await db.reviewDao.enqueue(
      tenantId: kTenantId,
      scanId: scanId,
      reasonCode: 'MULTI_BUBBLE_WARN',
      severity: ReviewSeverity.high,
      fieldRefs: [flaggedField],
    );
  }
  return scanId;
}
