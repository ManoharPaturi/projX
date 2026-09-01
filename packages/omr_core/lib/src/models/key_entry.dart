library;

import 'ids.dart';

/// Lifecycle/correction state of one answer-key row, mirroring the NTA's
/// post-exam key-correction vocabulary.
///
/// These states are first-class because they decide *bonus marks*, and bonus
/// marks are exactly the kind of thing a teacher audits line by line. Anything
/// other than [normal] makes [KeyCorrectionOverrideStrategy] run after the base
/// strategy (see its docs for who gets awarded what).
enum KeyEntryState {
  /// The key row is authoritative as written.
  normal,

  /// The examiner added correct options after publishing: everyone who marked
  /// *any* listed correct option gets the full award, regardless of the base
  /// outcome (so a previously-wrong response no longer attracts negative marks).
  multipleCorrectKey,

  /// Every option was accepted: full award to everyone who attempted.
  allOptionsCorrect,

  /// No option was correct: full award to everyone, attempted or not.
  noneCorrect,

  /// Question withdrawn (dropped): full award to everyone, attempted or not.
  dropped,
}

/// One row of an answer key: the right answer for one question.
///
/// Immutable by convention — keys are never edited in place. A correction
/// creates a new key *version* whose rows are re-graded from the retained raw
/// reads, which is why this type carries no history of its own.
final class KeyEntry {
  /// Creates a key row.
  const KeyEntry({
    required this.questionId,
    this.correctOptions = const <OptionId>{},
    this.correctInteger,
    this.state = KeyEntryState.normal,
    this.scoringRuleId,
  });

  /// The question this row answers.
  final QuestionId questionId;

  /// Correct options as a set — a singleton for single-correct, the full
  /// correct set for multi-correct, `row:col` pairs for matrix match.
  final Set<OptionId> correctOptions;

  /// Correct value for integer-digit questions (`correctInteger` column).
  final int? correctInteger;

  /// Key-correction state; anything but [KeyEntryState.normal] triggers the
  /// override strategy after the base strategy.
  final KeyEntryState state;

  /// Per-question scoring-rule override; `null` falls back to the section
  /// default and then the exam default.
  final String? scoringRuleId;

  /// Whether this row's state changes marks (drives the override pass).
  bool get isKeyCorrection => state != KeyEntryState.normal;

  @override
  String toString() =>
      'KeyEntry($questionId, $correctOptions, int: $correctInteger, '
      'state: $state, rule: $scoringRuleId)';
}
