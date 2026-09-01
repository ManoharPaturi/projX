import 'dart:typed_data';

import 'package:omr_data/omr_data.dart';
import 'package:omr_detect/omr_detect.dart';

/// The seam between the shutter and the detection pipeline: still bytes in,
/// one [StillEvaluation] out. Widget tests inject a canned evaluator so the
/// capture screen's wiring (persistence, grading, review routing, the card)
/// is testable without pixels; the device runs [OmrStillEvaluator].
abstract class StillEvaluator {
  Future<StillEvaluation> evaluate(String examId, Uint8List stillBytes);
}

/// Decodes and reads a captured still against the exam's own layout.
///
/// The pipeline is constructed per capture, not cached: the roster check
/// must see imports that happened since the last sheet, and [OmrPipeline]
/// is a const value object — there is no warm state to lose.
class OmrStillEvaluator implements StillEvaluator {
  OmrStillEvaluator(this.db, {OpencvService? cv})
      : cv = cv ?? OpencvDartImpl();

  final AppDb db;
  final OpencvService cv;

  @override
  Future<StillEvaluation> evaluate(String examId, Uint8List stillBytes) async {
    final template = await GradingService(db).templateFor(examId);

    // The roster as of THIS capture: roll-not-on-roster is a review flag,
    // not a crash, so an import mid-session takes effect on the next sheet.
    final exam = await db.examsDao.byId(examId);
    final roster = await db.studentsDao.rosterFor(exam!.instituteId);

    final decoded = cv.decodeStill(stillBytes);
    return OmrPipeline(
      cv: cv,
      template: template,
      roster: {for (final s in roster) s.rollNo},
    ).evaluateGray(decoded.width, decoded.height, decoded.gray);
  }
}
