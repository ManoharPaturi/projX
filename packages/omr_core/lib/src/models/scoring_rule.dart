library;

/// Which strategy implementation interprets a [ScoringRule]'s params.
///
/// Kept as an enum (not a class hierarchy) because a rule is *data*: it lives
/// in the `scoring_rules` table as `strategy` + `params_json`, so app code must
/// never switch on it — it resolves an id and hands the row to the engine.
enum ScoringStrategyKind { singleCorrect, multiCorrectPartial, integerDigits, matrixMatch }

/// A named marking scheme: which strategy runs and with what parameters.
///
/// Marking is data. Institutes re-tune penalties year to year (JEE-Adv moved
/// from −2 to −1 on multi-correct), so every number that decides marks lives in
/// [params] rather than in code. Presets in `scoring_presets.dart` are just
/// pre-built instances with stable ids.
final class ScoringRule {
  /// Creates a rule. Use [validate] (in `scoring_strategy.dart`) before grading
  /// — this constructor is `const` so presets need no runtime work, which means
  /// it cannot check params itself.
  const ScoringRule({
    required this.id,
    required this.name,
    required this.kind,
    this.params = const <String, Object?>{},
  });

  /// Stable identifier, persisted and referenced by per-question overrides.
  final String id;

  /// Human-readable name shown in the exam-setup UI.
  final String name;

  /// Which strategy interprets [params].
  final ScoringStrategyKind kind;

  /// Strategy-specific parameters; shape is defined by the strategy docs.
  final Map<String, Object?> params;

  @override
  String toString() => 'ScoringRule($id, $kind, $params)';
}
