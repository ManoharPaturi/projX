import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:omr_core/omr_core.dart' as core;
import 'package:omr_spec/omr_spec.dart' as spec;

import '../app_db.dart';
import '../converters.dart';
import '../enums.dart' as enums;

/// The id → rule registry backing `gradingConfigJson`'s `preset` field. Every
/// preset omr_core ships is resolvable by id so a stored config never dangles.
/// `final`, not `const`: the keys are themselves `.id` reads.
final Map<String, core.ScoringRule> _presetRegistry = <String, core.ScoringRule>{
  core.ScoringPresets.neetJeeMain.id: core.ScoringPresets.neetJeeMain,
  core.ScoringPresets.jeeAdvMultiCorrect2026.id:
      core.ScoringPresets.jeeAdvMultiCorrect2026,
  core.ScoringPresets.jeeAdvMultiCorrectLegacy.id:
      core.ScoringPresets.jeeAdvMultiCorrectLegacy,
  core.ScoringPresets.integerJeeMain2026.id:
      core.ScoringPresets.integerJeeMain2026,
  core.ScoringPresets.matrixMatchPerRow.id:
      core.ScoringPresets.matrixMatchPerRow,
};

/// Layout facts a grading run needs, resolved once per exam: question serial
/// order, per-field option values, section attribution, and the layout version
/// the sheets were printed against (audited onto the scoring run).
class LayoutContext {
  LayoutContext({
    required this.layoutVersion,
    required this.questionOrder,
    required this.optionValuesByField,
    required this.sections,
  });

  final int layoutVersion;

  /// MCQ/matrix/int-digits field keys in sheet serial order.
  final List<core.QuestionId> questionOrder;

  /// fieldKey → option values, indexed by `bubble_reads.option_index`.
  final Map<String, List<core.OptionId>> optionValuesByField;

  final List<core.SectionSpec> sections;
}

/// Rebuilds [core.GradingRequest]s from persisted state and grades whole
/// exams — the re-grade engine of plan §5.
///
/// Per-question outcomes are NEVER stored: they are a pure function of
/// (bubble_reads, human corrections included) ⋈ (an immutable key version) ⋈
/// (the scoring-rule snapshot). Any marksheet therefore reproduces exactly by
/// rebuilding the same request — a corrected key inserts a new version and
/// re-runs this service; no sheet is ever re-scanned.
class GradingService {
  GradingService(this.db);

  final AppDb db;

  /// Resolves an exam's layout into the [LayoutContext] shared by request
  /// building and read reconstruction.
  Future<LayoutContext> layoutContextFor(String examId) async {
    final (layoutRow, sheetSpec) = await _specFor(examId);
    final template = spec.compileDetectionTemplate(sheetSpec);

    // fieldKey → dense option list. Bubble rects already carry the compiled
    // option value ('A'..'E', '0'..'9'), so this is a group-by, not a rederive.
    final byField = <String, List<core.OptionId>>{};
    for (final bubble in template.bubbles) {
      final values = byField.putIfAbsent(bubble.fieldKey, () => <core.OptionId>[]);
      while (values.length <= bubble.optionIndex) {
        values.add('');
      }
      values[bubble.optionIndex] = bubble.optionValue;
    }
    for (final entry in byField.entries) {
      if (entry.value.any((v) => v.isEmpty)) {
        throw StateError(
          'layout ${sheetSpec.layoutId} v${sheetSpec.layoutVersion}: sparse '
          'option indexes on field ${entry.key}',
        );
      }
    }

    return LayoutContext(
      layoutVersion: layoutRow.layoutVersion,
      questionOrder: template.questionFieldKeys,
      optionValuesByField: byField,
      sections: <core.SectionSpec>[
        for (final s in sheetSpec.sections)
          core.SectionSpec(
            id: s.id,
            name: s.name,
            subject: s.subject,
            questionIds: spec.expandLabels(s.questionLabels),
            maxCounted: s.maxCounted,
          ),
      ],
    );
  }

  /// The compiled detection geometry for an exam's layout — the SAME
  /// template the capture path feeds `OmrPipeline`, so what registers a
  /// still and what grades its reads derive from one spec load.
  Future<spec.DetectionTemplate> templateFor(String examId) async {
    final (_, sheetSpec) = await _specFor(examId);
    return spec.compileDetectionTemplate(sheetSpec);
  }

  Future<(SheetLayout, spec.SheetSpec)> _specFor(String examId) async {
    final exam = await db.examsDao.byId(examId);
    if (exam == null) {
      throw StateError('unknown exam $examId');
    }
    final layoutRow = await (db.select(db.sheetLayouts)
          ..where((l) => l.id.equals(exam.sheetLayoutId)))
        .getSingle();
    final sheetSpec = spec.SheetSpec.fromJson(
      decodeJsonObject(layoutRow.specJson),
    );
    return (layoutRow, sheetSpec);
  }

  /// Grades every review-cleared scan of (exam, key version) and writes the
  /// results as ONE scoring run: snapshot → grade → upsert → recompute ranks,
  /// all auditable from the `scoring_runs` row.
  ///
  /// Scans still routed `needsReview` (or `rejected`) are excluded — their
  /// marks must not publish while a human hasn't confirmed the read.
  Future<core.GradingReport> gradeExam({
    required String tenantId,
    required String examId,
    required String keyVersionId,
    bool regrade = false,
  }) async {
    final exam = await db.examsDao.byId(examId);
    if (exam == null) {
      throw StateError('unknown exam $examId');
    }
    final layout = await layoutContextFor(examId);

    // Review-cleared scans with a resolved student — an unresolved roll has
    // no result row to hang marks on (FK), and belongs to review, not marks.
    final scans = await (db.select(db.scans)
          ..where(
            (s) =>
                s.examId.equals(examId) &
                s.studentId.isNotNull() &
                s.status.isInValues([
                  enums.ScanStatus.graded,
                  enums.ScanStatus.reviewed,
                ]),
          )
          ..orderBy([(s) => OrderingTerm.asc(s.capturedAt)]))
        .get();

    final reads = <String, core.SheetRead>{};
    final scanIdByStudent = <String, String>{};
    for (final scan in scans) {
      final studentId = scan.studentId;
      if (studentId == null || scanIdByStudent.containsKey(studentId)) {
        continue; // first capture wins: a replay cannot double-grade
      }
      reads[studentId] = await readForScan(scan.id, layout);
      scanIdByStudent[studentId] = scan.id;
    }

    final request = await _buildRequest(
      examId: examId,
      keyVersionId: keyVersionId,
      gradingConfigJson: exam.gradingConfigJson,
      layout: layout,
      reads: reads,
      regrade: regrade,
    );
    final report = const core.ExamGrader().grade(request);

    final scoringRunId = await db.resultsDao.startScoringRun(
      tenantId: tenantId,
      examId: examId,
      keyVersionId: keyVersionId,
      scoringRuleSnapshot: _snapshotOf(exam.gradingConfigJson),
      sheetLayoutVersion: layout.layoutVersion,
    );

    final rows = <ResultsCompanion>[
      for (final entry in report.resultsByStudent.entries)
        ResultsCompanion.insert(
          tenantId: tenantId,
          scanId: scanIdByStudent[entry.key]!,
          examId: examId,
          studentId: entry.key,
          keyVersionId: keyVersionId,
          scoringRunId: scoringRunId,
          total: entry.value.totalMarks,
          correct: Value(
            entry.value.outcomeCounts[core.QuestionOutcomeKind.correct] ?? 0,
          ),
          wrong: Value(
            entry.value.outcomeCounts[core.QuestionOutcomeKind.wrong] ?? 0,
          ),
          unattempted: Value(
            entry.value.outcomeCounts[core.QuestionOutcomeKind.unattempted] ?? 0,
          ),
          subjectTotalsJson: Value(
            encodeJsonObject(<String, Object?>{
              for (final s in entry.value.subjectTotals.entries) s.key: s.value,
            }),
          ),
          status: Value(
            switch (entry.value.status) {
              core.ExamResultStatus.ok => enums.ResultStatus.ok,
              core.ExamResultStatus.doubtful => enums.ResultStatus.doubtful,
              core.ExamResultStatus.regraded => enums.ResultStatus.regraded,
            },
          ),
        ),
    ];
    if (rows.isNotEmpty) {
      await db.resultsDao.upsertResults(tenantId, rows);
      await db.resultsDao.recomputeRanks(examId, keyVersionId);
    }
    await db.resultsDao.finishScoringRun(scoringRunId);
    return report;
  }

  /// Grades ONE scan — the read-back behind the instant post-capture card
  /// (plan M2: "scan ⇒ graded result") and the marksheet's per-question table.
  ///
  /// Does NOT write results: the persisted, ranked pass is [gradeExam]'s job.
  /// This is a pure function of the same substrate, so the card can never
  /// disagree with a later full pass over the same key version.
  Future<core.ExamResult> gradeScan({
    required String examId,
    required String keyVersionId,
    required String scanId,
  }) async {
    final exam = await db.examsDao.byId(examId);
    if (exam == null) {
      throw StateError('unknown exam $examId');
    }
    final layout = await layoutContextFor(examId);
    final read = await readForScan(scanId, layout);
    final request = await _buildRequest(
      examId: examId,
      keyVersionId: keyVersionId,
      gradingConfigJson: exam.gradingConfigJson,
      layout: layout,
      reads: <String, core.SheetRead>{scanId: read},
    );
    final report = const core.ExamGrader().grade(request);
    return report.resultsByStudent[scanId]!;
  }

  /// Rebuilds ONE scan's [core.SheetRead] from `bubble_reads`.
  ///
  /// Human corrections are already merged in place (`is_human_correction = 1`
  /// rows carry the corrected markClass), so this read re-grades
  /// deterministically without touching pixels again. Non-question fields
  /// (roll digits, set code) are skipped here — they live on the scan row.
  Future<core.SheetRead> readForScan(
    String scanId,
    LayoutContext layout,
  ) async {
    final scan = await (db.select(db.scans)
          ..where((s) => s.id.equals(scanId)))
        .getSingle();

    final rows = await (db.select(db.bubbleReads)
          ..where((b) => b.scanId.equals(scanId))
          ..orderBy([
            (b) => OrderingTerm.asc(b.fieldKey),
            (b) => OrderingTerm.asc(b.optionIndex),
          ]))
        .get();

    final byField = <String, List<BubbleRead>>{};
    for (final row in rows) {
      byField.putIfAbsent(row.fieldKey, () => <BubbleRead>[]).add(row);
    }

    final responses = <core.QuestionId, core.MarkedResponse>{};
    for (final field in byField.entries) {
      final values = layout.optionValuesByField[field.key];
      if (values == null) continue; // roll/set columns: not graded fields
      final chosen = <core.OptionId>{};
      var humanCorrected = false;
      var confidence = 1.0;
      var validity = core.ResponseValidity.valid;
      for (final bubble in field.value) {
        humanCorrected = humanCorrected || bubble.isHumanCorrection;
        confidence = math.min(confidence, bubble.confidence ?? 1);
        switch (bubble.markClass) {
          case enums.MarkClass.filled:
            chosen.add(values[bubble.optionIndex]);
          case enums.MarkClass.overfilled:
            // Intent is clear (one option) — the saturation only ROUTED the
            // sheet to review, which a human has now cleared.
            chosen.add(values[bubble.optionIndex]);
          case enums.MarkClass.probable:
            validity = core.ResponseValidity.probable;
          case enums.MarkClass.multiple:
            validity = core.ResponseValidity.multiMarked;
          case enums.MarkClass.blank || enums.MarkClass.empty:
            break;
        }
      }
      if (chosen.length > 1) validity = core.ResponseValidity.multiMarked;
      responses[field.key] = core.MarkedResponse(
        chosen: chosen,
        humanCorrected: humanCorrected,
        confidence: confidence,
        validity: validity,
      );
    }

    return core.SheetRead(
      responses: responses,
      sheetConfidence: scan.sheetConfidence ?? 1,
      rollNoRead: scan.rollNoRead,
      rollConfidence: scan.rollConfidence ?? 1,
      setCodeRead: scan.setCodeRead,
      flags: <core.SheetReadFlag>{
        if (scan.curlFlag) core.SheetReadFlag.curlDetected,
      },
    );
  }

  Future<core.GradingRequest> _buildRequest({
    required String examId,
    required String keyVersionId,
    required String gradingConfigJson,
    required LayoutContext layout,
    required Map<String, core.SheetRead> reads,
    bool regrade = false,
  }) async {
    final entries = await db.keysDao.entriesFor(keyVersionId);
    final key = <core.QuestionId, core.KeyEntry>{
      for (final e in entries)
        e.questionId: core.KeyEntry(
          questionId: e.questionId,
          // The DB stores option INDEXES; the letter is the canonical
          // OptionId everywhere else in the system.
          correctOptions: <core.OptionId>{
            for (final i in decodeJsonList(e.correctOptionsJson).cast<int>())
              String.fromCharCode(65 + i),
          },
          correctInteger: e.correctInteger,
          state: switch (e.state) {
            enums.KeyEntryState.normal => core.KeyEntryState.normal,
            enums.KeyEntryState.multipleCorrectKey =>
              core.KeyEntryState.multipleCorrectKey,
            enums.KeyEntryState.allOptionsCorrect =>
              core.KeyEntryState.allOptionsCorrect,
            enums.KeyEntryState.noneCorrect => core.KeyEntryState.noneCorrect,
            enums.KeyEntryState.dropped => core.KeyEntryState.dropped,
          },
          scoringRuleId: e.scoringRuleId,
        ),
    };

    final config = decodeJsonObject(gradingConfigJson);
    final presetId = config['preset'] as String?;
    final rule = presetId == null
        ? core.ScoringPresets.neetJeeMain
        : (_presetRegistry[presetId] ??
            (throw StateError('unknown scoring preset "$presetId"')));

    return core.GradingRequest(
      examId: examId,
      keyVersionId: keyVersionId,
      reads: reads,
      key: key,
      questionOrder: layout.questionOrder,
      sections: layout.sections,
      rules: <String, core.ScoringRule>{rule.id: rule},
      examDefaultRuleId: rule.id,
      regrade: regrade,
    );
  }

  /// The scoring-run snapshot records WHICH preset produced these marks; a
  /// default-config exam still names its effective preset explicitly.
  Map<String, Object?> _snapshotOf(String gradingConfigJson) {
    final config = decodeJsonObject(gradingConfigJson);
    if (config.containsKey('preset')) {
      return config;
    }
    return <String, Object?>{
      ...config,
      'preset': core.ScoringPresets.neetJeeMain.id,
    };
  }
}
