/// The strategy pattern that turns reads + keys into marks.
///
/// This is a single library spread over `part` files so that
/// [ScoringStrategy] can be `sealed`: Dart requires direct subtypes to live in
/// the same library, and sealed-ness buys exhaustive `switch` over strategies
/// at compile time — a missing case here is a compile error, not a silent
/// wrong-mark at exam time.
library;

import '../models/key_entry.dart';
import '../models/marked_response.dart';
import '../models/question_outcome.dart';
import '../models/scoring_rule.dart';

part 'integer_digits_strategy.dart';
part 'key_correction_override.dart';
part 'matrix_match_strategy.dart';
part 'multi_correct_partial_strategy.dart';
part 'single_correct_strategy.dart';

/// Typed, strict reader over a [ScoringRule]'s loose `Map<String, Object?>`.
///
/// Params arrive from JSON or from hand-written presets, so every read is
/// validated and every failure throws an [ArgumentError] naming the param.
/// Silent coercion here would mean a typo in a marking scheme grading a whole
/// exam wrongly, so no defaulting and no `dynamic`.
final class ScoringParams {
  /// Wraps [raw].
  const ScoringParams(this.raw);

  /// The raw parameter map.
  final Map<String, Object?> raw;

  /// Whether [key] is present (used to distinguish "not set" from "set to 0").
  bool contains(String key) => raw.containsKey(key);

  /// Reads a numeric param (marks are fractional: partial credit, tuned
  /// penalties). [int] and [double] both satisfy this.
  double numParam(String key) => _asNum(raw[key], key).toDouble();

  /// Reads an integral param, rejecting `4.5` where a count is required.
  int intParam(String key) {
    final num v = _asNum(raw[key], key);
    if (v != v.roundToDouble()) {
      throw ArgumentError('param "$key" must be an integer, got $v');
    }
    return v.toInt();
  }

  /// Reads a string param restricted to [allowed] — the enum-ish knobs such as
  /// `multiMarkAction` are strings so the row stays JSON-portable.
  String enumParam(String key, Set<String> allowed) {
    final Object? v = raw[key];
    if (v is! String) {
      throw ArgumentError('param "$key" must be a String, got ${v.runtimeType}');
    }
    if (!allowed.contains(v)) {
      throw ArgumentError(
        'param "$key" must be one of ${allowed.join(', ')}, got "$v"',
      );
    }
    return v;
  }

  /// Reads a string param restricted to [allowed] when present, else
  /// [fallback].
  String enumOr(String key, Set<String> allowed, String fallback) =>
      contains(key) ? enumParam(key, allowed) : fallback;

  /// Reads a numeric param when present, otherwise [fallback].
  double numOr(String key, double fallback) =>
      contains(key) ? numParam(key) : fallback;

  /// Reads the `partialByCount` table: number of correct options chosen →
  /// marks. Keys may be `int` (Dart-authored) or `String` (JSON round-trip).
  Map<int, double> marksByCount(String key) {
    final Object? v = raw[key];
    if (v is! Map<Object?, Object?>) {
      throw ArgumentError('param "$key" must be a map of count → marks');
    }
    final Map<int, double> table = <int, double>{};
    for (final MapEntry<Object?, Object?> e in v.entries) {
      final Object? rawCount = e.key;
      final int? parsed = switch (rawCount) {
        final int i => i,
        final String s => int.tryParse(s),
        _ => null,
      };
      if (parsed == null) {
        throw ArgumentError(
          'param "$key" has a non-integer key: ${rawCount.runtimeType}',
        );
      }
      final int count = parsed;
      if (count < 1) {
        throw ArgumentError('param "$key" has a non-positive key: $count');
      }
      table[count] = _asNum(e.value, key).toDouble();
    }
    if (table.isEmpty) {
      throw ArgumentError('param "$key" must not be empty');
    }
    return table;
  }

  static num _asNum(Object? v, String key) {
    if (v is num) return v;
    throw ArgumentError(
      'param "$key" must be a number, got ${v?.runtimeType ?? 'null'}',
    );
  }
}

/// Base class for marking schemes: a pure function from a read and a key row to
/// an outcome.
///
/// Strategies must be deterministic and side-effect free. A re-grade months
/// later, from retained reads, must reproduce every mark exactly — that is the
/// whole basis of the immutable-key-version design, and it is why nothing here
/// consults the clock, the cohort, or any global state.
sealed class ScoringStrategy {
  /// Const so strategies are singletons.
  const ScoringStrategy();

  /// Which rule kind this strategy interprets.
  ScoringStrategyKind get kind;

  /// Scores one question.
  ///
  /// Throws [ArgumentError] when [key] and [rule] are mutually inconsistent
  /// (e.g. a multi-correct key row with an empty correct set, or an
  /// integer-question key row with no `correctInteger`) — a malformed key must
  /// stop the run loudly rather than hand out arbitrary marks.
  QuestionOutcome score(MarkedResponse response, KeyEntry key, ScoringRule rule);

  /// Checks [rule]'s params against this strategy's contract.
  ///
  /// Run for every rule before an exam grades, so a bad parameter fails in
  /// setup rather than mid-exam.
  void validate(ScoringRule rule);
}

/// Registry from rule kind to strategy instance.
///
/// The only place strategies are constructed; everywhere else resolves a rule
/// id and hands it over, so adding a marking scheme never touches app code.
final class ScoringStrategies {
  const ScoringStrategies._();

  static const SingleCorrectStrategy _single = SingleCorrectStrategy();
  static const MultiCorrectPartialStrategy _partial =
      MultiCorrectPartialStrategy();
  static const IntegerDigitsStrategy _digits = IntegerDigitsStrategy();
  static const MatrixMatchStrategy _matrix = MatrixMatchStrategy();

  /// All strategies, keyed by the rule kind they interpret.
  static const Map<ScoringStrategyKind, ScoringStrategy> byKind =
      <ScoringStrategyKind, ScoringStrategy>{
        ScoringStrategyKind.singleCorrect: _single,
        ScoringStrategyKind.multiCorrectPartial: _partial,
        ScoringStrategyKind.integerDigits: _digits,
        ScoringStrategyKind.matrixMatch: _matrix,
      };

  /// The strategy for [kind].
  static ScoringStrategy forKind(ScoringStrategyKind kind) => byKind[kind]!;

  /// The strategy for [rule], after checking the two agree.
  static ScoringStrategy forRule(ScoringRule rule) {
    final ScoringStrategy strategy = forKind(rule.kind);
    strategy.validate(rule);
    return strategy;
  }
}

/// Validates [rule] against its strategy's contract; throws [ArgumentError].
///
/// Public so exam setup can vet a marking scheme the moment it is authored.
void validateScoringRule(ScoringRule rule) =>
    ScoringStrategies.forKind(rule.kind).validate(rule);

/// Whether [subset] is strictly inside [superset] (smaller and fully contained).
bool _isStrictSubset(Set<String> subset, Set<String> superset) =>
    subset.length < superset.length && superset.containsAll(subset);

/// Whether two option sets hold exactly the same options.
bool _setsEqual(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// Human-friendly sorted rendering of an option set for reason strings.
String _labelOptions(Set<String> options) => (options.toList()..sort()).join(', ');
