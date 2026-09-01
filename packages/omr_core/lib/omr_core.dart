/// Grading engine for the OMR system: reads + answer keys → auditable marks.
///
/// Pure Dart, zero IO, no Flutter. Detection constructs the models in
/// `src/models/`; this package decides marks, aggregates results, and flags
/// suspicious key rows. Nothing here touches the clock, the network, or global
/// state, so the same inputs always reproduce the same marks — the basis of the
/// immutable key-version / re-grade design.
library;

// Models.
export 'src/models/exam_result.dart' show ExamResult, ExamResultStatus;
export 'src/models/ids.dart' show OptionId, QuestionId, SubjectId;
export 'src/models/key_entry.dart' show KeyEntry, KeyEntryState;
export 'src/models/marked_response.dart' show MarkedResponse, ResponseValidity;
export 'src/models/question_outcome.dart'
    show QuestionOutcome, QuestionOutcomeKind;
export 'src/models/scoring_rule.dart' show ScoringRule, ScoringStrategyKind;
export 'src/models/sheet_read.dart' show SheetRead, SheetReadFlag;

// Grading. The strategies live in one library spread over `part` files so that
// ScoringStrategy can stay sealed, so they are exported from that one library.
export 'src/grading/scoring_strategy.dart'
    show
        IntegerDigitsCodec,
        IntegerDigitsIssue,
        IntegerDigitsRead,
        IntegerDigitsStrategy,
        KeyCorrectionOverrideStrategy,
        MatrixMatchStrategy,
        MultiCorrectPartialStrategy,
        ScoringParams,
        ScoringStrategies,
        ScoringStrategy,
        SingleCorrectStrategy,
        validateScoringRule;
export 'src/grading/exam_grader.dart'
    show
        ExamGrader,
        GradingReport,
        GradingRequest,
        GradingSummary,
        QuestionStats,
        SectionSpec;
export 'src/grading/scoring_presets.dart' show ScoringPresets;

// Diagnostics.
export 'src/diagnostics/wrong_key_detector.dart'
    show KeyAnomaly, KeyAnomalyEvidence, KeyAnomalyReason, WrongKeyDetector;

// Utilities.
export 'src/util/marks_close.dart' show marksClose;
