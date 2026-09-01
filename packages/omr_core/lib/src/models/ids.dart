/// Canonical identifier types shared by detection, grading and reports.
library;

/// A single bubble option inside one question field.
///
/// MCQ blocks use letters (`'A'`..`'E'`), digit blocks use digit strings
/// (`'0'`..`'9'`), and integer/matrix blocks use the positional encodings
/// documented on [IntegerDigitsCodec] and [MatrixMatchStrategy]. Keeping this
/// a plain [String] typedef (rather than a wrapper class) means `Set<OptionId>`
/// stays a cheap literal in tests and in the drift layer.
typedef OptionId = String;

/// Canonical question id (e.g. `'q17'`), stable across sets and key versions.
///
/// The sheet ordinal (position on paper) is a *separate* concept owned by the
/// sheet spec / question-set mapping; grading always speaks in canonical ids so
/// that set A and set B can share one key row when their answers coincide.
typedef QuestionId = String;

/// A subject or section key used to break totals down (e.g. `'physics'`).
typedef SubjectId = String;
