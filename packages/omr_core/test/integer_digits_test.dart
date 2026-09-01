/// Integer-digit questions: the codec's canonical encoding, leading-zero vs
/// blank-column semantics, and the ambiguous-column action.
library;

import 'package:omr_core/omr_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  final IntegerDigitsStrategy strategy = IntegerDigitsStrategy();
  final ScoringRule rule = ScoringPresets.integerJeeMain2026;
  final KeyEntry key = keyFor('q1', <OptionId>{}, integer: 42);

  QuestionOutcome score(Set<OptionId> chosen, [ScoringRule? withRule]) =>
      strategy.score(resp(chosen), key, withRule ?? rule);

  group('codec', () {
    test('encodes a number across columns, zero-padded', () {
      expect(digits(3, 2), <OptionId>{'0:0', '1:3'});
      expect(digits(42, 2), <OptionId>{'0:4', '1:2'});
      expect(digits(0, 2), <OptionId>{'0:0', '1:0'});
      expect(digits(7, 1), <OptionId>{'0:7'});
    });

    test('rejects values that do not fit the column count', () {
      expect(() => digits(100, 2), throwsArgumentError);
      expect(() => digits(-1, 2), throwsArgumentError);
      expect(() => digits(1, 0), throwsArgumentError);
    });

    test("'03' and '3' decode to the same number", () {
      // Explicit leading zero over two columns vs a single marked column: the
      // block is right-aligned, so both are the number 3.
      final IntegerDigitsRead explicit = IntegerDigitsCodec.decode(
        <OptionId>{'0:0', '1:3'},
      );
      final IntegerDigitsRead single = IntegerDigitsCodec.decode(
        <OptionId>{'1:3'},
      );
      expect(explicit.value, 3);
      expect(single.value, 3);
      expect(explicit.ambiguous, isFalse);
    });

    test('a blank column inside the number is reported', () {
      final IntegerDigitsRead read = IntegerDigitsCodec.decode(
        <OptionId>{'0:1', '2:3'},
      );
      expect(read.value, isNull);
      expect(read.ambiguous, isTrue);
      expect(read.issues, contains(IntegerDigitsIssue.interiorBlankColumn));
    });
  });

  group('clean reads', () {
    test('an exact value earns full marks', () {
      final QuestionOutcome o = score(digits(42, 2));
      expect(o.kind, QuestionOutcomeKind.correct);
      expect(marksClose(o.marksAwarded, 4), isTrue);
      expect(o.reason, 'correct: 42');
    });

    test('an explicit leading zero is unambiguous', () {
      final QuestionOutcome o = score(<OptionId>{'0:0', '1:3'});
      expect(o.kind, QuestionOutcomeKind.wrong); // 3 vs key 42
      expect(o.reason, contains('marked 3'));
    });

    test('a wrong value is penalised', () {
      final QuestionOutcome o = score(digits(41, 2));
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -1), isTrue);
    });

    test('a blank field is unattempted at zero', () {
      final QuestionOutcome o = score(<OptionId>{});
      expect(o.kind, QuestionOutcomeKind.unattempted);
      expect(marksClose(o.marksAwarded, 0), isTrue);
    });

    test('every value of the column range is scored, not just the key', () {
      final KeyEntry zeroKey = keyFor('q2', <OptionId>{}, integer: 0);
      final QuestionOutcome o = strategy.score(
        resp(digits(0, 2)),
        zeroKey,
        rule,
      );
      expect(o.kind, QuestionOutcomeKind.correct);
      expect(o.reason, 'correct: 0');
    });
  });

  group('blank leading column vs explicit zero', () {
    // ' 3' — the left column left blank, the right column marked 3.
    final Set<OptionId> blankLeading = <OptionId>{'1:3'};

    test('is flagged as ambiguous even though it decodes to the same number', () {
      final IntegerDigitsRead read = IntegerDigitsCodec.decode(blankLeading);
      expect(read.value, 3);
      expect(read.ambiguous, isTrue);
      expect(read.issues, contains(IntegerDigitsIssue.leadingBlankColumn));
    });

    test("ambiguousAction 'wrong' applies the penalty", () {
      final QuestionOutcome o = score(blankLeading, intRule(ambiguousAction: 'wrong'));
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -1), isTrue);
      expect(o.reason, contains('leadingBlankColumn'));
    });

    test("ambiguousAction 'unattempted' voids it at zero", () {
      final QuestionOutcome o = score(
        blankLeading,
        intRule(ambiguousAction: 'unattempted'),
      );
      expect(o.kind, QuestionOutcomeKind.unattempted);
      expect(marksClose(o.marksAwarded, 0), isTrue);
      expect(o.reason, contains('unattempted'));
      expect(o.reason, contains('leadingBlankColumn'));
    });
  });

  group('multi-marked digit columns', () {
    final Set<OptionId> multi = <OptionId>{'0:4', '0:2', '1:2'};

    test('is ambiguous with no defensible value', () {
      final IntegerDigitsRead read = IntegerDigitsCodec.decode(multi);
      expect(read.value, isNull);
      expect(read.issues, contains(IntegerDigitsIssue.multiMarkedColumn));
    });

    test("honours ambiguousAction 'wrong'", () {
      final QuestionOutcome o = score(multi);
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(marksClose(o.marksAwarded, -1), isTrue);
      expect(o.reason, contains('multiMarkedColumn'));
    });

    test("honours ambiguousAction 'unattempted'", () {
      final QuestionOutcome o = score(
        multi,
        intRule(ambiguousAction: 'unattempted'),
      );
      expect(o.kind, QuestionOutcomeKind.unattempted);
      expect(marksClose(o.marksAwarded, 0), isTrue);
    });
  });

  group('malformed input', () {
    test('an unparseable option id is ambiguous, not a crash', () {
      final QuestionOutcome o = score(<OptionId>{'A'});
      expect(o.kind, QuestionOutcomeKind.wrong);
      expect(o.reason, contains('malformedOptionId'));
    });

    test('a key without correctInteger is rejected', () {
      expect(
        () => strategy.score(
          resp(digits(42, 2)),
          keyFor('q3', <OptionId>{'A'}),
          rule,
        ),
        throwsArgumentError,
      );
    });

    test('a non-numeric param is rejected by validation', () {
      const ScoringRule bad = ScoringRule(
        id: 'bad',
        name: 'bad',
        kind: ScoringStrategyKind.integerDigits,
        params: <String, Object?>{'ambiguousAction': 'ignore'},
      );
      expect(() => validateScoringRule(bad), throwsArgumentError);
    });
  });
}
