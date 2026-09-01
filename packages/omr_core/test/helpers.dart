/// Shared builders so each test states intent instead of constructor noise.
library;

import 'package:omr_core/omr_core.dart';

/// A field read; defaults describe a confident, clean, machine-read field.
MarkedResponse resp(
  Set<OptionId> chosen, {
  ResponseValidity validity = ResponseValidity.valid,
  double confidence = 1,
  bool humanCorrected = false,
}) => MarkedResponse(
  chosen: chosen,
  validity: validity,
  confidence: confidence,
  humanCorrected: humanCorrected,
);

/// A sheet read carrying [responses]; defaults are a confident, flag-free sheet.
SheetRead sheet(
  Map<QuestionId, MarkedResponse> responses, {
  double confidence = 1,
  Set<SheetReadFlag> flags = const <SheetReadFlag>{},
  String? roll,
  String? setCode,
}) => SheetRead(
  responses: responses,
  sheetConfidence: confidence,
  flags: flags,
  rollNoRead: roll,
  setCodeRead: setCode,
);

/// An MCQ-style key row; [integer] covers integer-digit questions.
KeyEntry keyFor(
  QuestionId questionId,
  Set<OptionId> options, {
  KeyEntryState state = KeyEntryState.normal,
  int? integer,
  String? ruleId,
}) => KeyEntry(
  questionId: questionId,
  correctOptions: options,
  correctInteger: integer,
  state: state,
  scoringRuleId: ruleId,
);

/// A single-correct marking scheme with the given marks.
ScoringRule singleRule({
  String id = 'test-single',
  num correct = 4,
  num wrong = -1,
  num unattempted = 0,
  String multiMarkAction = 'wrong',
}) => ScoringRule(
  id: id,
  name: 'test single-correct',
  kind: ScoringStrategyKind.singleCorrect,
  params: <String, Object?>{
    'correct': correct,
    'wrong': wrong,
    'unattempted': unattempted,
    'multiMarkAction': multiMarkAction,
  },
);

/// A multi-correct partial-credit scheme.
ScoringRule multiRule({
  String id = 'test-multi',
  num full = 4,
  Map<int, num>? partialByCount,
  num anyWrong = -1,
  num unattempted = 0,
}) => ScoringRule(
  id: id,
  name: 'test multi-correct',
  kind: ScoringStrategyKind.multiCorrectPartial,
  params: <String, Object?>{
    'full': full,
    'partialByCount': partialByCount ?? <int, num>{1: 1, 2: 2, 3: 3},
    'anyWrong': anyWrong,
    'unattempted': unattempted,
  },
);

/// An integer-digit marking scheme.
ScoringRule intRule({
  String id = 'test-integer',
  num correct = 4,
  num wrong = -1,
  num unattempted = 0,
  String ambiguousAction = 'wrong',
}) => ScoringRule(
  id: id,
  name: 'test integer digits',
  kind: ScoringStrategyKind.integerDigits,
  params: <String, Object?>{
    'correct': correct,
    'wrong': wrong,
    'unattempted': unattempted,
    'ambiguousAction': ambiguousAction,
  },
);

/// Digits [value] written across [columns] columns using the canonical codec.
Set<OptionId> digits(int value, int columns) =>
    IntegerDigitsCodec.encodeNumber(value, columns);
