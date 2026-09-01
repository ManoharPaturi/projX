import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Every number asserted below was computed BY HAND from the cohort in
/// helpers.dart — this file is the oracle for the SQL, not a restatement of
/// it.
///
/// Cohort (set 'A', keys q1→[0], q2→[1], q3→[2], q4→[1]):
///
/// | student | total | q1 | q2 | q3 | q4 |      NTILE(2) half      |
/// |---------|-------|----|----|----|----|-------------------------|
/// | s1      | 12    | 0✓ | 1✓ | 3✗ | 1✓ | 1 (top)                 |
/// | s2      | 10    | 0✓ | 2✗ | 0✗ | 1✓ | 1 (top)                 |
/// | s3      | 6     | 0✓ | 1✓ | 2✓ | —  | 2 (bottom)              |
/// | s4      | 4     | 1✗ | 3✗ | 2✓ | —  | 2 (bottom)              |
///
/// ('—' = only an empty read: present but unattempted.)
///
/// Hand-computed item stats:
///   q1: correct 3/4 → P=0.75 | top 1/2=0.5? NO — top = s1✓,s2✓ = 1.0,
///       bottom = s3✓,s4✗ = 0.5 → D = +0.5
///   q2: correct 2/4 → P=0.50 | top = 1/2, bottom = 1/2 → D = 0.0
///   q3: correct 2/4 → P=0.50 | top = 0/2, bottom = 2/2 → D = −1.0
///       (a negative-discrimination question: the weak half found it easier —
///       the classic wrong-key / ambiguous-stem smell the metric exists for)
///   q4: attempted 2, correct 2 → P = 2/4 = 0.50 | top 2/2 = 1.0,
///       bottom 0/2 = 0.0 → D = +1.0
void main() {
  late AppDb db;
  late AnalyticsCohort cohort;

  setUp(() async {
    db = await openTestDb();
    cohort = await seedAnalyticsCohort(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'subject-wise averages/max/min straight from subject_totals_json',
    () async {
      final rows = await db.analyticsDao.subjectAggregates(
        cohort.examId,
        cohort.keyVersionId,
      );

      expect(rows.length, 2);
      // Physics: 8 + 6 + 4 + 2 = 20 / 4 = 5, max 8, min 2.
      final physics = rows.singleWhere((r) => r.subject == 'Physics');
      expect(physics.students, 4);
      expect(physics.avgTotal, closeTo(5.0, 1e-9));
      expect(physics.maxTotal, closeTo(8.0, 1e-9));
      expect(physics.minTotal, closeTo(2.0, 1e-9));

      // Chemistry: 4 + 4 + 2 + 2 = 12 / 4 = 3, max 4, min 2.
      final chemistry = rows.singleWhere((r) => r.subject == 'Chemistry');
      expect(chemistry.students, 4);
      expect(chemistry.avgTotal, closeTo(3.0, 1e-9));
      expect(chemistry.maxTotal, closeTo(4.0, 1e-9));
      expect(chemistry.minTotal, closeTo(2.0, 1e-9));
    },
  );

  test('per-question difficulty and top-vs-bottom discrimination', () async {
    final stats = await db.analyticsDao.questionStats(
      cohort.examId,
      cohort.keyVersionId,
    );

    expect(stats.map((q) => q.questionId).toList(), ['q1', 'q2', 'q3', 'q4']);

    QuestionStatsRow at(String id) =>
        stats.singleWhere((q) => q.questionId == id);

    final q1 = at('q1');
    expect(q1.students, 4);
    expect(q1.attempted, 4);
    expect(q1.correct, 3);
    expect(q1.difficulty, closeTo(0.75, 1e-9));
    expect(q1.topHalfCorrectRate, closeTo(1.0, 1e-9));
    expect(q1.bottomHalfCorrectRate, closeTo(0.5, 1e-9));
    expect(q1.discrimination, closeTo(0.5, 1e-9));

    final q2 = at('q2');
    expect(q2.attempted, 4);
    expect(q2.correct, 2);
    expect(q2.difficulty, closeTo(0.5, 1e-9));
    expect(q2.topHalfCorrectRate, closeTo(0.5, 1e-9));
    expect(q2.bottomHalfCorrectRate, closeTo(0.5, 1e-9));
    expect(
      q2.discrimination,
      closeTo(0.0, 1e-9),
      reason: 'both halves did equally well — zero discrimination',
    );

    final q3 = at('q3');
    expect(q3.correct, 2);
    expect(q3.difficulty, closeTo(0.5, 1e-9));
    expect(q3.topHalfCorrectRate, closeTo(0.0, 1e-9));
    expect(q3.bottomHalfCorrectRate, closeTo(1.0, 1e-9));
    expect(
      q3.discrimination,
      closeTo(-1.0, 1e-9),
      reason: 'only the bottom half solved it — the wrong-key smell',
    );

    final q4 = at('q4');
    expect(
      q4.students,
      4,
      reason:
          'unattempted students still count in the '
          'denominator — their reads exist',
    );
    expect(q4.attempted, 2);
    expect(q4.correct, 2);
    expect(
      q4.difficulty,
      closeTo(0.5, 1e-9),
      reason: 'difficulty divides by students, not attempters',
    );
    expect(q4.topHalfCorrectRate, closeTo(1.0, 1e-9));
    expect(q4.bottomHalfCorrectRate, closeTo(0.0, 1e-9));
    expect(q4.discrimination, closeTo(1.0, 1e-9));
  });

  test('multi-mark answers count as wrong, never partially right', () async {
    // The cohort has no multi-marks, so graft one on: s1 fills BOTH q1
    // options. q1's correct set is {0}; a fill of {0,1} must flip s1 to
    // incorrect even though a keyed option is among the marks.
    final readCount = (await db.select(db.bubbleReads).get())
        .where((r) => r.scanId == cohort.scanIds[0] && r.fieldKey == 'q1')
        .length;
    expect(readCount, 1, reason: 'fixture sanity: s1 read one q1 option');

    await db.scansDao.insertScanWithReads(
      // A fresh scan for s1 is not needed — extend the existing read set.
      scanRow(examId: cohort.examId),
      const [],
    );
    await db
        .into(db.bubbleReads)
        .insert(
          BubbleReadsCompanion.insert(
            tenantId: kTenantId,
            scanId: cohort.scanIds[0],
            fieldKey: 'q1',
            optionIndex: 1,
            markClass: MarkClass.filled,
          ),
        );

    final q1 = (await db.analyticsDao.questionStats(
      cohort.examId,
      cohort.keyVersionId,
    )).singleWhere((q) => q.questionId == 'q1');

    expect(
      q1.correct,
      2,
      reason:
          's1 was q1-correct before the extra mark; now attempted with '
          'a keyed AND an unkeyed option → wrong',
    );
    expect(q1.difficulty, closeTo(0.5, 1e-9));
    expect(q1.topHalfCorrectRate, closeTo(0.5, 1e-9));
  });

  test(
    'distractor distribution counts filled options and flags the key',
    () async {
      final rows = await db.analyticsDao.distractorDistribution(
        cohort.examId,
        cohort.keyVersionId,
      );

      // (question, option) → chosen count, keyed?
      final dist = <String, DistractorRow>{
        for (final r in rows) '${r.questionId}:${r.optionIndex}': r,
      };

      expect(dist.keys.toSet(), {
        'q1:0',
        'q1:1',
        'q2:1',
        'q2:2',
        'q2:3',
        'q3:0',
        'q3:2',
        'q3:3',
        'q4:1',
      }, reason: 'only FILLED options appear; empty reads are not choices');

      expect(dist['q1:0']!.chosenCount, 3); // s1, s2, s3 bubbled 0
      expect(dist['q1:0']!.isCorrectOption, isTrue);
      expect(dist['q1:1']!.chosenCount, 1); // s4
      expect(dist['q1:1']!.isCorrectOption, isFalse);

      expect(dist['q2:1']!.chosenCount, 2); // s1, s3 — the keyed option
      expect(dist['q2:1']!.isCorrectOption, isTrue);
      expect(dist['q2:2']!.chosenCount, 1); // s2
      expect(dist['q2:3']!.chosenCount, 1); // s4

      expect(dist['q3:2']!.chosenCount, 2); // s3, s4 — keyed
      expect(dist['q3:2']!.isCorrectOption, isTrue);
      expect(dist['q3:0']!.chosenCount, 1); // s2's wrong pick
      expect(dist['q3:3']!.chosenCount, 1); // s1's wrong pick

      expect(dist['q4:1']!.chosenCount, 2); // s1, s2 only
      expect(dist['q4:1']!.isCorrectOption, isTrue);
    },
  );
}
