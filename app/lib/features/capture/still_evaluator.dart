import 'dart:isolate';
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

/// `settings.strictness` → the capture preset it names. Unknown values are
/// impossible through [SettingsDao.write], which refuses them — this map is
/// defense for a hand-edited row, defaulting like the DAO does.
Strictness strictnessFromSettings(String name) => switch (name) {
  'strict' => Strictness.strict,
  'relaxed' => Strictness.relaxed,
  _ => Strictness.normal,
};

/// Decodes and reads a captured still against the exam's own layout.
///
/// The pipeline is constructed per capture, not cached: the roster check
/// must see imports that happened since the last sheet, the operator's
/// strictness choice must apply from the next sheet, and [OmrPipeline]
/// is a const value object — there is no warm state to lose.
///
/// Decode and detection run on a short-lived background isolate
/// ([inBackground], on by default): they take hundreds of milliseconds on a
/// phone, and on the UI isolate the busy spinner and the preview would
/// freeze for all of it. The DB reads stay here; drift already runs them on
/// its own isolate.
class OmrStillEvaluator implements StillEvaluator {
  OmrStillEvaluator(this.db, {OpencvService? cv, this.inBackground = true})
    : cv = cv ?? OpencvDartImpl();

  final AppDb db;
  final OpencvService cv;
  final bool inBackground;

  @override
  Future<StillEvaluation> evaluate(String examId, Uint8List stillBytes) async {
    final template = await GradingService(db).templateFor(examId);

    // The roster as of THIS capture: roll-not-on-roster is a review flag,
    // not a crash, so an import mid-session takes effect on the next sheet.
    final exam = await db.examsDao.byId(examId);
    final roster = await db.studentsDao.rosterFor(exam!.instituteId);

    final settings = await SettingsDao(db).settingsFor(exam.tenantId);
    final pipeline = OmrPipeline(
      cv: cv,
      template: template,
      thresholdConfig: ThresholdConfig(
        strictness: strictnessFromSettings(settings.strictness),
      ),
      roster: {for (final s in roster) s.rollNo},
    );
    return inBackground
        ? _inIsolate(pipeline, stillBytes)
        : decodeAndRead(pipeline, stillBytes);
  }

  /// Kept static so the isolate closure captures only the pipeline (plain
  /// data: template, config, roster) and the bytes — never the DB.
  static Future<StillEvaluation> _inIsolate(
    OmrPipeline pipeline,
    Uint8List stillBytes,
  ) => Isolate.run(
    () => decodeAndRead(pipeline, stillBytes),
    debugName: 'still-evaluate',
  );
}

/// JPEG bytes → decoded gray → [OmrPipeline]: the whole CPU-bound part of
/// a capture, runnable on any isolate.
StillEvaluation decodeAndRead(OmrPipeline pipeline, Uint8List stillBytes) {
  return pipeline.evaluateStill(stillBytes);
}
