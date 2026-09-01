import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../app_db.dart';
import '../converters.dart';
import '../enums.dart';
import '../tables/results.dart';
import '../tables/scoring_runs.dart';
import '../tables/students.dart';

part 'results_dao.g.dart';

/// A result joined with its student — the shape of every results list.
@immutable
class ResultWithStudent {
  const ResultWithStudent({required this.result, required this.student});

  final Result result;
  final Student student;
}

@DriftAccessor(tables: [Results, Students, ScoringRuns])
class ResultsDao extends DatabaseAccessor<AppDb> with _$ResultsDaoMixin {
  ResultsDao(super.attachedDatabase);

  /// Opens an audit-snapshot row for one grading pass (plan §4: rule
  /// snapshot + layout version + threshold config, so historical marksheets
  /// reproduce exactly). Close it with [finishScoringRun].
  Future<String> startScoringRun({
    required String tenantId,
    required String examId,
    required String keyVersionId,
    required Map<String, Object?> scoringRuleSnapshot,
    required int sheetLayoutVersion,
    String? thresholdConfigId,
  }) {
    return transaction(() async {
      final inserted = await into(scoringRuns).insertReturning(
        ScoringRunsCompanion.insert(
          tenantId: tenantId,
          examId: examId,
          keyVersionId: keyVersionId,
          scoringRuleSnapshotJson: encodeJsonObject(scoringRuleSnapshot),
          sheetLayoutVersion: sheetLayoutVersion,
          thresholdConfigId: Value(thresholdConfigId),
        ),
      );
      final id = inserted.id;
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'scoring_runs',
        rowId: id,
        op: SyncOp.insert,
        payload: <String, Object?>{
          'examId': examId,
          'keyVersionId': keyVersionId,
        },
      );
      return id;
    });
  }

  /// Stamps a scoring run finished.
  Future<int> finishScoringRun(String scoringRunId) {
    return (update(scoringRuns)
          ..where((ScoringRuns s) => s.id.equals(scoringRunId)))
        .write(ScoringRunsCompanion(finishedAt: Value(DateTime.now().toUtc())));
  }

  /// Atomically upserts one scoring run's result rows.
  ///
  /// The conflict target is the natural key (exam_id, student_id,
  /// key_version_id), NOT the surrogate id: re-grading the same key version
  /// replaces its rows in place, while grading a NEW key version inserts
  /// alongside the old rows — both stay auditable side by side.
  Future<void> upsertResults(
    String tenantId,
    List<ResultsCompanion> rows,
  ) async {
    if (rows.isEmpty) {
      return;
    }
    final runIds = rows.map((r) => r.scoringRunId.value).toSet();
    if (runIds.length > 1) {
      throw ArgumentError(
        'upsertResults takes ONE scoring run\'s rows, got ${runIds.length}',
      );
    }
    await transaction(() async {
      await batch((Batch b) {
        for (final row in rows) {
          b.insert(
            results,
            row,
            onConflict: DoUpdate(
              (_) => row,
              target: [results.examId, results.studentId, results.keyVersionId],
            ),
          );
        }
      });
      for (final row in rows) {
        await attachedDatabase.syncOutboxDao.enqueue(
          tenantId: tenantId,
          tableName: 'results',
          rowId:
              '${row.examId.value}:${row.studentId.value}:${row.keyVersionId.value}',
          op: SyncOp.insert,
          payload: <String, Object?>{
            'examId': row.examId.value,
            'studentId': row.studentId.value,
            'keyVersionId': row.keyVersionId.value,
            'total': row.total.value,
          },
        );
      }
    });
  }

  /// Recomputes `results.rank` for one (exam, key version) with a
  /// RANK() OVER window — RANK, not ROW_NUMBER: tied totals SHARE a rank and
  /// the next rank skips (90, 90 ⇒ ranks 2, 2 then 4). One statement, no
  /// app-side loop; ties inside ORDER BY total DESC break on student_id only
  /// to keep the window deterministic, it does not affect the rank values.
  Future<int> recomputeRanks(String examId, String keyVersionId) {
    return customUpdate(
      'UPDATE results SET "rank" = ('
      '  SELECT w.rnk FROM ('
      '    SELECT id, RANK() OVER ('
      '        PARTITION BY exam_id ORDER BY total DESC) AS rnk '
      '    FROM results WHERE exam_id = ?1 AND key_version_id = ?2'
      '  ) w WHERE w.id = results.id'
      ') WHERE exam_id = ?1 AND key_version_id = ?2',
      variables: [
        Variable.withString(examId),
        Variable.withString(keyVersionId),
      ],
      updates: {results},
    );
  }

  /// Results for one (exam, key version) joined with students, rank order,
  /// ties broken deterministically (total DESC, then student id).
  Future<List<ResultWithStudent>> resultsFor(
    String examId,
    String keyVersionId,
  ) async {
    final rows =
        await (select(results).join([
                innerJoin(students, students.id.equalsExp(results.studentId)),
              ])
              ..where(
                results.examId.equals(examId) &
                    results.keyVersionId.equals(keyVersionId),
              )
              ..orderBy([
                OrderingTerm(
                  expression: results.rank,
                  mode: OrderingMode.asc,
                  nulls: NullsOrder.last,
                ),
                OrderingTerm.desc(results.total),
                OrderingTerm.asc(results.studentId),
              ]))
            .get();
    return <ResultWithStudent>[
      for (final row in rows)
        ResultWithStudent(
          result: row.readTable(results),
          student: row.readTable(students),
        ),
    ];
  }
}
