library;

import '../models/scoring_rule.dart';

/// Pre-built marking schemes with stable ids, ready to bind to an exam.
///
/// Every number that decides marks lives here as *data*, because marking
/// schemes change year to year and institute to institute — JEE-Advanced moved
/// its multi-correct wrong-answer penalty from −2 to −1, which is exactly the
/// kind of change that must be a new row, not a code edit. Ids are stable so a
/// stored `scoringRuleId` keeps resolving.
///
/// These are `const` (no runtime validation by construction); the preset test
/// asserts [validateScoringRule] accepts each one, which keeps that promise
/// honest if a preset is ever edited.
final class ScoringPresets {
  const ScoringPresets._();

  /// NEET / JEE-Main single-correct: +4 correct, −1 wrong, 0 unattempted.
  ///
  /// `multiMarkAction: 'wrong'` mirrors the NTA's treatment of a double-marked
  /// bubble as an incorrect answer.
  static const ScoringRule neetJeeMain = ScoringRule(
    id: 'neet-jee-main-4n1p',
    name: 'NEET / JEE-Main single correct (+4 / −1 / 0)',
    kind: ScoringStrategyKind.singleCorrect,
    params: <String, Object?>{
      'correct': 4,
      'wrong': -1,
      'unattempted': 0,
      'multiMarkAction': 'wrong',
    },
  );

  /// JEE-Advanced multi-correct, current scheme: +4 full, +1 per correct option
  /// marked, −1 when any wrong option is marked.
  static const ScoringRule jeeAdvMultiCorrect2026 = ScoringRule(
    id: 'jee-adv-multi-2026',
    name: 'JEE-Adv multi-correct (+4 / partial +1..+3 / −1)',
    kind: ScoringStrategyKind.multiCorrectPartial,
    params: <String, Object?>{
      'full': 4,
      'partialByCount': <int, int>{1: 1, 2: 2, 3: 3},
      'anyWrong': -1,
      'unattempted': 0,
    },
  );

  /// JEE-Advanced multi-correct, legacy scheme (same partial ladder, −2 for any
  /// wrong option) — kept as a separate row so historical papers re-grade
  /// exactly as they were first marked.
  static const ScoringRule jeeAdvMultiCorrectLegacy = ScoringRule(
    id: 'jee-adv-multi-legacy',
    name: 'JEE-Adv multi-correct, legacy (+4 / partial +1..+3 / −2)',
    kind: ScoringStrategyKind.multiCorrectPartial,
    params: <String, Object?>{
      'full': 4,
      'partialByCount': <int, int>{1: 1, 2: 2, 3: 3},
      'anyWrong': -2,
      'unattempted': 0,
    },
  );

  /// JEE-Main numerical-value questions: +4 / −1 / 0, with an ambiguous digit
  /// read (multi-marked column, blank column inside the number, blank leading
  /// column) treated as wrong rather than void.
  static const ScoringRule integerJeeMain2026 = ScoringRule(
    id: 'jee-main-integer-2026',
    name: 'JEE-Main integer digits (+4 / −1 / 0)',
    kind: ScoringStrategyKind.integerDigits,
    params: <String, Object?>{
      'correct': 4,
      'wrong': -1,
      'unattempted': 0,
      'ambiguousAction': 'wrong',
    },
  );

  /// Matrix match scored per row: +1 per matched row, no row penalty.
  static const ScoringRule matrixMatchPerRow = ScoringRule(
    id: 'matrix-match-per-row',
    name: 'Matrix match, per row (+1 / 0 / 0)',
    kind: ScoringStrategyKind.matrixMatch,
    params: <String, Object?>{
      'perRowCorrect': 1,
      'perRowWrong': 0,
      'unattempted': 0,
      'allOrNothing': false,
    },
  );

  /// The default key-correction award handed back by an NTA key correction.
  static const ScoringRule keyCorrectionAward4 = ScoringRule(
    id: 'key-correction-award-4',
    name: 'Key correction award (+4)',
    kind: ScoringStrategyKind.singleCorrect,
    params: <String, Object?>{'award': 4},
  );

  /// All presets, for UI pickers and for the validation test.
  static const List<ScoringRule> all = <ScoringRule>[
    neetJeeMain,
    jeeAdvMultiCorrect2026,
    jeeAdvMultiCorrectLegacy,
    integerJeeMain2026,
    matrixMatchPerRow,
  ];
}
