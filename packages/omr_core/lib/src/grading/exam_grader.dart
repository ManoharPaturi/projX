library;

import '../models/exam_result.dart';
import '../models/ids.dart';
import '../models/key_entry.dart';
import '../models/marked_response.dart';
import '../models/question_outcome.dart';
import '../models/scoring_rule.dart';
import '../models/sheet_read.dart';
import 'scoring_presets.dart';
import 'scoring_strategy.dart';

/// A graded slice of the paper: sections carry subject attribution, an optional
/// per-section marking default, and the N-of-M cap.
final class SectionSpec {
  /// Creates a section.
  const SectionSpec({
    required this.id,
    required this.questionIds,
    this.name,
    this.subject,
    this.maxCounted,
    this.defaultRuleId,
  });

  /// Section id, e.g. `'physics-a'`.
  final String id;

  /// Display name.
  final String? name;

  /// Subject/section key used in `subjectTotals`; falls back to [id] so every
  /// question always lands in some bucket.
  final SubjectId? subject;

  /// Questions in this section, in canonical ids (order here is not authoritative).
  final List<QuestionId> questionIds;

  /// N-of-M cap: at most this many responses in this section count. `null` = no
  /// cap (the ordinary case).
  final int? maxCounted;

  /// Marking-scheme default for this section; questions may override.
  final String? defaultRuleId;

  /// Key used in `subjectTotals`.
  SubjectId get subjectKey => subject ?? id;

  /// Whether this section caps how many responses count.
  bool get hasCap => maxCounted != null;

  @override
  String toString() =>
      'SectionSpec($id, ${questionIds.length} questions'
      '${hasCap ? ', max $maxCounted counted' : ''})';
}

/// Everything one grading run needs. Immutable; a re-grade is a new request.
final class GradingRequest {
  /// Creates a request.
  const GradingRequest({
    required this.examId,
    required this.keyVersionId,
    required this.reads,
    required this.key,
    required this.questionOrder,
    required this.sections,
    required this.rules,
    required this.examDefaultRuleId,
    this.keyCorrectionRule = ScoringPresets.keyCorrectionAward4,
    this.regrade = false,
    this.doubtfulConfidenceBelow = 0.90,
  });

  /// Exam being graded (audit trail only).
  final String examId;

  /// Key version graded against — results are tagged with it, never mutated.
  final String keyVersionId;

  /// Reads keyed by student id.
  final Map<String, SheetRead> reads;

  /// Answer key by canonical question id.
  final Map<QuestionId, KeyEntry> key;

  /// All questions in **sheet serial order**. Order is input, not derived:
  /// N-of-M selection walks this order, and it is the order results are
  /// reported in, so it must be supplied by the caller who knows the layout.
  final List<QuestionId> questionOrder;

  /// Sections covering the paper.
  final List<SectionSpec> sections;

  /// Resolution table: rule id → rule. Presets can be merged in directly.
  final Map<String, ScoringRule> rules;

  /// Fallback rule when neither the question nor its section names one.
  final String examDefaultRuleId;

  /// Award handed back by key corrections (see [KeyCorrectionOverrideStrategy]).
  final ScoringRule keyCorrectionRule;

  /// Marks results as [ExamResultStatus.regraded] when this run supersedes an
  /// earlier key version.
  final bool regrade;

  /// A sheet whose confidence falls below this is reported as `doubtful`.
  final double doubtfulConfidenceBelow;
}

/// Cohort-level statistics for one question — the feed for the wrong-key
/// detector and for difficulty/discrimination analytics.
///
/// Rates use *attempted* as the denominator, not cohort size: difficulty is a
/// property of the students who tried the question. Questions nobody attempted
/// report 0 for every rate, and callers should treat that as "no signal", which
/// [WrongKeyDetector] does via its minimum-attempts guard.
final class QuestionStats {
  /// Creates stats; fields are counts gathered over the whole cohort.
  const QuestionStats({
    required this.questionId,
    required this.subject,
    required this.cohortSize,
    required this.attempted,
    required this.correct,
    required this.partial,
    required this.wrong,
    required this.unattempted,
    required this.invalidated,
    required this.bonus,
    required this.multiMarked,
    required this.averageMarks,
  });

  /// The question these stats describe.
  final QuestionId questionId;

  /// Subject/section bucket this question falls in.
  final SubjectId subject;

  /// Students in the run.
  final int cohortSize;

  /// Students who marked the question (cap-invalidated attempts included — the
  /// student did mark them).
  final int attempted;

  /// Outcome counts.
  final int correct, partial, wrong, unattempted, invalidated, bonus;

  /// Reads the detection layer flagged as multi-marked. This is detection's
  /// verdict, not an inference from the chosen-set size, because on a
  /// multi-correct question three choices can be perfectly legal.
  final int multiMarked;

  /// Mean marks awarded across the whole cohort.
  final double averageMarks;

  /// Correct rate over attempts (the classic difficulty index).
  double get correctRate => attempted == 0 ? 0 : correct / attempted;

  /// Multi-mark rate over attempts.
  double get multiMarkRate => attempted == 0 ? 0 : multiMarked / attempted;

  /// Share of the cohort that attempted the question.
  double get attemptRate => cohortSize == 0 ? 0 : attempted / cohortSize;
}

/// Cohort statistics for a whole run.
final class GradingSummary {
  /// Creates a summary.
  const GradingSummary({
    required this.students,
    required this.stats,
    required this.medianCorrectRate,
    required this.medianMultiMarkRate,
  });

  /// Students graded.
  final int students;

  /// Per-question stats in sheet serial order.
  final List<QuestionStats> stats;

  /// Median [QuestionStats.correctRate] across questions with at least one
  /// attempt; 0 when nothing was attempted anywhere.
  final double medianCorrectRate;

  /// Median [QuestionStats.multiMarkRate] across questions with at least one
  /// attempt; 0 when nothing was attempted anywhere.
  final double medianMultiMarkRate;

  /// Stats for [questionId], or `null` when the question was not graded.
  QuestionStats? statFor(QuestionId questionId) {
    for (final QuestionStats s in stats) {
      if (s.questionId == questionId) return s;
    }
    return null;
  }
}

/// The output of one grading run.
final class GradingReport {
  /// Creates a report.
  const GradingReport({
    required this.examId,
    required this.keyVersionId,
    required this.resultsByStudent,
    required this.summary,
  });

  /// Exam id from the request.
  final String examId;

  /// Key version graded against.
  final String keyVersionId;

  /// One result per student.
  final Map<String, ExamResult> resultsByStudent;

  /// Cohort statistics.
  final GradingSummary summary;
}

/// Grades a whole exam: many sheets against one key version.
///
/// Orchestration only — every marks decision is delegated to a
/// [ScoringStrategy], so this class is where policy about *which* rule runs and
/// about section caps lives, and nothing else.
///
/// Rule resolution order per question: the key entry's `scoringRuleId`, then
/// its section's `defaultRuleId`, then the exam's [GradingRequest.examDefaultRuleId].
/// Each is looked up in [GradingRequest.rules]; a dangling id is a setup error
/// and throws rather than silently grading with a default.
final class ExamGrader {
  /// Const; the grader holds no state between runs.
  const ExamGrader();

  static const KeyCorrectionOverrideStrategy _keyCorrection =
      KeyCorrectionOverrideStrategy();

  /// Grades every read in [request].
  GradingReport grade(GradingRequest request) {
    final _Prepared prepared = _prepare(request);

    final Map<String, ExamResult> results = <String, ExamResult>{};
    final Map<QuestionId, List<QuestionOutcome>> byQuestion =
        <QuestionId, List<QuestionOutcome>>{
          for (final QuestionId q in request.questionOrder) q: <QuestionOutcome>[],
        };

    for (final MapEntry<String, SheetRead> entry in request.reads.entries) {
      final String studentId = entry.key;
      final SheetRead read = entry.value;
      final List<QuestionOutcome> outcomes = <QuestionOutcome>[];
      final Map<SubjectId, double> subjectTotals = <SubjectId, double>{};

      final Set<QuestionId> beyondCap = _questionsBeyondCap(request, prepared, read);

      for (final QuestionId q in request.questionOrder) {
        final KeyEntry keyEntry = request.key[q]!;
        final SectionSpec? section = prepared.sectionOf[q];
        final QuestionOutcome outcome = _scoreQuestion(
          request: request,
          prepared: prepared,
          read: read,
          questionId: q,
          keyEntry: keyEntry,
          section: section,
          beyondCap: beyondCap.contains(q),
        );
        outcomes.add(outcome);
        byQuestion[q]!.add(outcome);
        final SubjectId bucket = section?.subjectKey ?? _unsectioned;
        subjectTotals[bucket] = (subjectTotals[bucket] ?? 0) + outcome.marksAwarded;
      }

      final bool doubtful =
          read.flags.isNotEmpty ||
          read.sheetConfidence < request.doubtfulConfidenceBelow;
      results[studentId] = ExamResult.fromOutcomes(
        studentId: studentId,
        keyVersionId: request.keyVersionId,
        outcomes: outcomes,
        subjectTotals: subjectTotals,
        status: doubtful
            ? ExamResultStatus.doubtful
            : request.regrade
            ? ExamResultStatus.regraded
            : ExamResultStatus.ok,
      );
    }

    return GradingReport(
      examId: request.examId,
      keyVersionId: request.keyVersionId,
      resultsByStudent: results,
      summary: _summarise(request, prepared, results.length, byQuestion),
    );
  }

  /// Scores one question for one student: base strategy, then the section cap,
  /// then any key correction.
  QuestionOutcome _scoreQuestion({
    required GradingRequest request,
    required _Prepared prepared,
    required SheetRead read,
    required QuestionId questionId,
    required KeyEntry keyEntry,
    required SectionSpec? section,
    required bool beyondCap,
  }) {
    final String ruleId =
        keyEntry.scoringRuleId ??
        section?.defaultRuleId ??
        request.examDefaultRuleId;
    final ScoringRule rule = prepared.rulesById[ruleId]!;
    final MarkedResponse response = read.responseFor(questionId);
    final QuestionOutcome base = ScoringStrategies.forRule(rule).score(
      response,
      keyEntry,
      rule,
    );

    // Cap first: an overflow response is void, so there is nothing for a key
    // correction to revise.
    if (beyondCap) {
      return base.supersededBy(
        QuestionOutcome.of(
          questionId,
          QuestionOutcomeKind.invalidated,
          0,
          'invalidated: section cap — only the first ${section!.maxCounted} '
          'responses in ${section.id} count (no penalty)',
        ),
      );
    }
    if (keyEntry.isKeyCorrection) {
      return _keyCorrection.apply(
        base: base,
        response: response,
        key: keyEntry,
        rule: request.keyCorrectionRule,
      );
    }
    return base;
  }

  /// The attempted questions in [read] that fall outside every capped section's
  /// limit, in sheet serial order.
  ///
  /// A response consumes a slot when the student marked it **and** the key state
  /// is not one of the everyone-gets-awarded states: `noneCorrect` and `dropped`
  /// hand marks to the whole cohort regardless of attempt, so they are examiner
  /// decisions rather than student responses and must neither consume a slot nor
  /// be voided by one. Unattempted questions never consume a slot.
  Set<QuestionId> _questionsBeyondCap(
    GradingRequest request,
    _Prepared prepared,
    SheetRead read,
  ) {
    final Set<QuestionId> beyond = <QuestionId>{};
    for (final SectionSpec section in request.sections) {
      final int? cap = section.maxCounted;
      if (cap == null) continue;
      int counted = 0;
      for (final QuestionId q in prepared.orderedBySerial[section.id]!) {
        final MarkedResponse response = read.responseFor(q);
        if (response.chosen.isEmpty) continue;
        if (_awardsEveryoneRegardless(request.key[q]!.state)) continue;
        counted++;
        if (counted > cap) beyond.add(q);
      }
    }
    return beyond;
  }

  /// Whether [state] awards marks without regard to what the student marked.
  static bool _awardsEveryoneRegardless(KeyEntryState state) =>
      state == KeyEntryState.noneCorrect || state == KeyEntryState.dropped;

  /// Validates the request and indexes everything the hot loop needs.
  static _Prepared _prepare(GradingRequest request) {
    if (request.questionOrder.toSet().length != request.questionOrder.length) {
      throw ArgumentError('questionOrder contains duplicate question ids');
    }
    for (final QuestionId q in request.questionOrder) {
      if (!request.key.containsKey(q)) {
        throw ArgumentError('no key entry for question "$q"');
      }
    }

    final Map<QuestionId, int> ordinal = <QuestionId, int>{
      for (int i = 0; i < request.questionOrder.length; i++)
        request.questionOrder[i]: i,
    };
    final Map<QuestionId, SectionSpec> sectionOf = <QuestionId, SectionSpec>{};
    final Map<String, List<QuestionId>> orderedBySerial =
        <String, List<QuestionId>>{};

    for (final SectionSpec section in request.sections) {
      if (section.hasCap && section.maxCounted! < 1) {
        throw ArgumentError(
          'section "${section.id}" has maxCounted < 1 (${section.maxCounted})',
        );
      }
      final List<QuestionId> ordered = section.questionIds.toList()
        ..sort(
          (QuestionId a, QuestionId b) =>
              ordinal[a]!.compareTo(ordinal[b]!),
        );
      for (final QuestionId q in section.questionIds) {
        if (!ordinal.containsKey(q)) {
          throw ArgumentError(
            'section "${section.id}" lists question "$q" which is not in '
            'questionOrder',
          );
        }
        if (sectionOf.containsKey(q)) {
          throw ArgumentError(
            'question "$q" appears in both "${sectionOf[q]!.id}" and '
            '"${section.id}"',
          );
        }
        sectionOf[q] = section;
      }
      orderedBySerial[section.id] = ordered;
    }

    // Resolve and validate every rule the run can reach, up front: a malformed
    // marking scheme must fail in setup, not halfway through a cohort.
    final Map<String, ScoringRule> rulesById = <String, ScoringRule>{
      ...request.rules,
    };
    final keyCorrectionId = request.keyCorrectionRule.id;
    if (!rulesById.containsKey(keyCorrectionId)) {
      rulesById[keyCorrectionId] = request.keyCorrectionRule;
    }
    _keyCorrection.validate(request.keyCorrectionRule);
    for (final String id in <String>{
      request.examDefaultRuleId,
      for (final SectionSpec s in request.sections) if (s.defaultRuleId != null) s.defaultRuleId!,
      for (final KeyEntry k in request.key.values) if (k.scoringRuleId != null) k.scoringRuleId!,
    }) {
      final ScoringRule? rule = rulesById[id];
      if (rule == null) {
        throw ArgumentError('unknown scoring rule id "$id"');
      }
      validateScoringRule(rule);
    }

    return _Prepared(sectionOf, orderedBySerial, rulesById);
  }

  /// Aggregates per-question outcomes into cohort statistics.
  static GradingSummary _summarise(
    GradingRequest request,
    _Prepared prepared,
    int students,
    Map<QuestionId, List<QuestionOutcome>> byQuestion,
  ) {
    final List<QuestionStats> stats = <QuestionStats>[];
    final List<double> correctRates = <double>[];
    final List<double> multiMarkRates = <double>[];

    for (final QuestionId q in request.questionOrder) {
      final List<QuestionOutcome> outcomes = byQuestion[q] ?? const <QuestionOutcome>[];
      int correct = 0, partial = 0, wrong = 0, unattempted = 0, invalidated = 0, bonus = 0;
      double marks = 0;
      for (final QuestionOutcome o in outcomes) {
        marks += o.marksAwarded;
        switch (o.kind) {
          case QuestionOutcomeKind.correct: correct++;
          case QuestionOutcomeKind.partial: partial++;
          case QuestionOutcomeKind.wrong: wrong++;
          case QuestionOutcomeKind.unattempted: unattempted++;
          case QuestionOutcomeKind.invalidated: invalidated++;
          case QuestionOutcomeKind.bonus: bonus++;
        }
      }
      final int multiMarked = request.reads.values
          .where((SheetRead r) => r.responses[q]?.validity == ResponseValidity.multiMarked)
          .length;
      final SectionSpec? section = prepared.sectionOf[q];
      final int attempted = outcomes.length - unattempted;
      stats.add(
        QuestionStats(
          questionId: q,
          subject: section?.subjectKey ?? _unsectioned,
          cohortSize: students,
          attempted: attempted,
          correct: correct,
          partial: partial,
          wrong: wrong,
          unattempted: unattempted,
          invalidated: invalidated,
          bonus: bonus,
          multiMarked: multiMarked,
          averageMarks: outcomes.isEmpty ? 0 : marks / outcomes.length,
        ),
      );
      if (attempted > 0) {
        correctRates.add(correct / attempted);
        multiMarkRates.add(multiMarked / attempted);
      }
    }
    return GradingSummary(
      students: students,
      stats: stats,
      medianCorrectRate: _median(correctRates),
      medianMultiMarkRate: _median(multiMarkRates),
    );
  }

  /// Subject bucket used when a question belongs to no section.
  static const SubjectId _unsectioned = 'general';

  /// Median of [values]; 0 for an empty list (no signal, not a zero signal).
  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final List<double> sorted = values.toList()..sort();
    final int mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}

/// Lookups precomputed once per run so the per-student loop stays allocation
/// light.
final class _Prepared {
  const _Prepared(this.sectionOf, this.orderedBySerial, this.rulesById);

  final Map<QuestionId, SectionSpec> sectionOf;
  final Map<String, List<QuestionId>> orderedBySerial;
  final Map<String, ScoringRule> rulesById;
}
