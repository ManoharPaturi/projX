import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_data/omr_data.dart';
import 'package:omr_detect/omr_detect.dart' as detect
    show BubbleRead, BubbleZone, FieldRead, MarkClass, StillEvaluation;

import 'still_evaluator.dart';

/// The shutter's full consequence, as one call: evaluate the still, persist
/// the scan with its bubble reads, route it through the review queue when
/// the read says so, grade, and return what the post-capture card shows.
///
/// Everything here is the same substrate the fixture path writes — grading
/// and re-grade never know which path inserted a scan.
class SheetIntake {
  SheetIntake(this.db, {StillEvaluator? evaluator})
      : evaluator = evaluator ?? OmrStillEvaluator(db);

  final AppDb db;
  final StillEvaluator evaluator;

  /// Processes one captured still for [examId].
  ///
  /// A rejected or flagged read is NOT an error: the scan row lands with
  /// `needsReview`, the review queue says why, and the card reflects it.
  /// Only infra failures (decode, DB) throw — those the screen surfaces as
  /// a snack and the operator re-shoots.
  Future<CapturedSheet> process({
    required String tenantId,
    required String examId,
    required Uint8List stillBytes,
  }) async {
    final exam = await db.examsDao.byId(examId);
    if (exam == null) {
      throw StateError('unknown exam $examId');
    }

    final evaluation = await evaluator.evaluate(examId, stillBytes);
    final read = evaluation.read;
    final layoutVersion =
        (await GradingService(db).templateFor(examId)).layoutVersion;

    // Roll → student: an unresolvable roll leaves the scan student-less on
    // purpose — it belongs to review, not to a guessed roster row.
    String? studentId;
    final roll = read.rollNoRead;
    if (roll != null) {
      final roster = await db.studentsDao.rosterFor(exam.instituteId);
      for (final s in roster) {
        if (s.rollNo == roll) {
          studentId = s.id;
          break;
        }
      }
    }

    final reasons = reviewReasonsFor(evaluation);
    final needsReview = reasons.isNotEmpty;
    final scanId = await db.scansDao.insertScanWithReads(
      ScansCompanion.insert(
        tenantId: tenantId,
        examId: examId,
        studentId: Value(studentId),
        rollNoRead: Value(roll),
        rollConfidence: Value(read.rollConfidence),
        setCodeRead: Value(read.setCodeRead),
        layoutVersion: layoutVersion,
        // Derived-image persistence is the M4 retention piece; the
        // sentinels keep NOT NULL honest until then.
        warpedImagePath: 'capture://pending',
        thumbPath: 'capture://pending',
        annotatedPath: 'capture://pending',
        sheetConfidence: Value(read.sheetConfidence),
        curlFlag: Value(read.flags.contains(core.SheetReadFlag.curlDetected)),
        status: Value(
          needsReview ? ScanStatus.needsReview : ScanStatus.graded,
        ),
      ),
      [for (final field in evaluation.fields) ..._bubbleInputs(field)],
    );

    for (final reason in reasons) {
      await db.reviewDao.enqueue(
        tenantId: tenantId,
        scanId: scanId,
        reasonCode: reason.code,
        severity: reason.severity,
        fieldRefs: reason.fieldRefs,
      );
    }

    // The persisted, ranked pass — exactly what the fixture path and the
    // key editor trigger, so the results tab reflects this sheet at once.
    // Review-routed scans are excluded by gradeExam itself.
    final keyVersion = await db.keysDao.activeVersion(examId);
    core.ExamResult? result;
    if (keyVersion != null) {
      await GradingService(db).gradeExam(
        tenantId: tenantId,
        examId: examId,
        keyVersionId: keyVersion.id,
      );
      result = await GradingService(db).gradeScan(
        examId: examId,
        keyVersionId: keyVersion.id,
        scanId: scanId,
      );
    }

    return CapturedSheet(
      scanId: scanId,
      rollNoRead: roll,
      setCodeRead: read.setCodeRead,
      result: result,
      needsReview: needsReview,
      reasons: [for (final r in reasons) r.code],
    );
  }

  /// One [BubbleReadInput] per bubble — the re-grade substrate, so a
  /// corrected key reproduces this sheet's marks without re-scanning.
  List<BubbleReadInput> _bubbleInputs(detect.FieldRead field) => [
        for (final bubble in field.bubbles)
          BubbleReadInput(
            fieldKey: bubble.sample.fieldKey,
            optionIndex: bubble.sample.optionIndex,
            markClass: _markClass(field, bubble),
            meanIntensity: bubble.sample.meanIntensity,
            fillRatio: bubble.sample.fillRatio,
            confidence: bubble.confidence,
            thresholdUsed: bubble.thresholdUsed,
          ),
      ];

  /// Bubble-level mark, a pure translation of the detect verdicts: the
  /// bubble's zone, except that overfill is a ROW verdict — the zone knows
  /// dark, only the classifier's row knows whether the ink stayed inside
  /// the outline. Multiplicity needs no ride-along: a `multiple` row has
  /// two zone-filled bubbles, which `readForScan` already turns into a
  /// multi-marked validity.
  MarkClass _markClass(detect.FieldRead field, detect.BubbleRead bubble) {
    switch (bubble.zone) {
      case detect.BubbleZone.probable:
        return MarkClass.probable;
      case detect.BubbleZone.filled:
        return field.markClass == detect.MarkClass.overfilled
            ? MarkClass.overfilled
            : MarkClass.filled;
      case detect.BubbleZone.empty:
        return MarkClass.empty;
    }
  }
}

/// Review routing for one evaluation: rejection codes first, then one row
/// per read flag. Public so the intake's tests and any future batch path
/// assert against the same mapping.
List<({String code, ReviewSeverity severity, List<String> fieldRefs})>
    reviewReasonsFor(detect.StillEvaluation evaluation) {
  // Field refs per reason where the read can name them.
  final multiMarked = [
    for (final f in evaluation.fields)
      if (f.markClass == detect.MarkClass.multiple ||
          f.markClass == detect.MarkClass.overfilled)
        f.fieldKey,
  ];
  final probable = [
    for (final f in evaluation.fields)
      if (f.bubbles.any((b) => b.zone == detect.BubbleZone.probable))
        f.fieldKey,
  ];
  return [
    if (evaluation.rejected)
      (
        code: 'NO_MARKER_ERR',
        severity: ReviewSeverity.mandatory,
        fieldRefs: const <String>[],
      ),
    for (final flag in evaluation.read.flags)
      switch (flag) {
        core.SheetReadFlag.rollChecksumMismatch => (
            code: 'ROLL_CHECKSUM_ERR',
            severity: ReviewSeverity.high,
            fieldRefs: const <String>[],
          ),
        core.SheetReadFlag.rollNotOnRoster => (
            code: 'ROLL_NOT_ON_ROSTER',
            severity: ReviewSeverity.high,
            fieldRefs: const <String>[],
          ),
        core.SheetReadFlag.rollColumnAmbiguous => (
            code: 'ROLL_AMBIGUOUS',
            severity: ReviewSeverity.high,
            fieldRefs: const <String>[],
          ),
        core.SheetReadFlag.setCodeBlank => (
            code: 'SET_BLANK',
            severity: ReviewSeverity.medium,
            fieldRefs: const <String>[],
          ),
        core.SheetReadFlag.setCodeMulti => (
            code: 'SET_MULTI',
            severity: ReviewSeverity.medium,
            fieldRefs: const <String>[],
          ),
        core.SheetReadFlag.multiMarkedField => (
            code: 'MULTI_BUBBLE_WARN',
            severity: ReviewSeverity.high,
            fieldRefs: multiMarked,
          ),
        core.SheetReadFlag.probableBubblesPresent => (
            code: 'PROBABLE_BUBBLE',
            severity: ReviewSeverity.medium,
            fieldRefs: probable,
          ),
        core.SheetReadFlag.curlDetected => (
            code: 'CURL_WARN',
            severity: ReviewSeverity.medium,
            fieldRefs: const <String>[],
          ),
        core.SheetReadFlag.lowConfidence => (
            code: 'LOW_CONFIDENCE',
            severity: ReviewSeverity.medium,
            fieldRefs: const <String>[],
          ),
      },
  ];
}

/// What the post-capture card shows (plan §6 screen 6): the READ identity —
/// roll and set as bubbled, not as the roster guessed — the instant grade,
/// and the review routing.
class CapturedSheet {
  const CapturedSheet({
    required this.scanId,
    required this.rollNoRead,
    required this.setCodeRead,
    required this.result,
    required this.needsReview,
    required this.reasons,
  });

  final String scanId;
  final String? rollNoRead;
  final String? setCodeRead;
  final core.ExamResult? result;
  final bool needsReview;
  final List<String> reasons;
}
