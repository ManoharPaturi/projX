/// Text-stored enums persisted by the drift tables in this package.
///
/// Every enum below is stored through drift's `textEnum` helper, which writes
/// the Dart member NAME verbatim (e.g. `ScanStatus.needsReview` is stored as
/// the TEXT `'needsReview'`). Raw SQL in the DAOs compares against these
/// member names — renaming a member invalidates already-stored data.
///
/// One naming note: `KeyVersionStatus` uses `finalized` where plan §4 sketches
/// `final`, because `final` is a reserved Dart word and cannot be an enum
/// member name.
library;

/// Phase-2 sync state (plan §4 `†` columns; MVP stays [pending]).
enum SyncState { pending, synced, failed }

/// `exams.status` — draft | active | graded | published.
enum ExamStatus { draft, active, graded, published }

/// `answer_key_versions.status`. Provisional versions can still take entries;
/// finalized versions are frozen forever — a key edit is always a NEW version
/// that supersedes the old one (plan §5 re-grade flow).
enum KeyVersionStatus { provisional, finalized }

/// `answer_key_entries.state` — NTA key-correction states are first-class.
enum KeyEntryState {
  normal,
  multipleCorrectKey,
  allOptionsCorrect,
  noneCorrect,
  dropped,
}

/// `scans.status`.
enum ScanStatus { graded, needsReview, reviewed, rejected }

/// `bubble_reads.markClass` — the Addmen-style classification taxonomy
/// emitted by detection stage 8 (plan §3).
enum MarkClass { filled, empty, probable, multiple, overfilled, blank }

/// `results.status`.
enum ResultStatus { ok, doubtful, regraded }

/// `scoring_rules.strategy` — marking is data, not code (plan §5).
enum ScoringStrategyKind {
  singleCorrect,
  multiCorrectPartial,
  integerDigits,
  matrixMatch,
  keyCorrectionOverride,
}

/// `review_queue.severity`. Declaration order mirrors escalation order; the
/// pending-review query orders `mandatory` → `low` via a CASE expression.
enum ReviewSeverity { low, medium, high, mandatory }

/// `review_queue.outcome`.
enum ReviewOutcome { open, corrected, unresolvable, retaken }

/// `report_jobs.type`.
enum ReportJobType { marksheet, consolidated, excel, csv, analytics }

/// `report_jobs.status`.
enum ReportJobStatus { queued, running, done, failed }

/// `sync_outbox.op`.
enum SyncOp { insert, update, delete }
