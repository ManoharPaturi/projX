import 'package:drift/drift.dart';

import '../app_db.dart';
import '../converters.dart';
import '../enums.dart';
import '../tables/report_jobs.dart';

part 'report_jobs_dao.g.dart';

/// Records every report/export generation (plan §7): what was asked for
/// (params), what came out (path), and why it failed when it did.
///
/// Jobs are regenerable by design — a marksheet is a pure function of
/// (bubble_reads ⋈ key version ⋈ rule snapshot) — so the row exists for
/// traceability, not for recovery.
@DriftAccessor(tables: [ReportJobs])
class ReportJobsDao extends DatabaseAccessor<AppDb> with _$ReportJobsDaoMixin {
  ReportJobsDao(super.attachedDatabase);

  /// Opens a job row and returns its id — call [complete] or [fail] on it.
  Future<String> start({
    required String tenantId,
    required String examId,
    required ReportJobType type,
    required String format,
    required Map<String, Object?> params,
  }) async {
    final inserted = await into(reportJobs).insertReturning(
      ReportJobsCompanion.insert(
        tenantId: tenantId,
        examId: examId,
        type: type,
        format: format,
        paramsJson: encodeJsonObject(params),
        status: const Value(ReportJobStatus.running),
      ),
    );
    return inserted.id;
  }

  /// Stamps a job done with the artifact path.
  Future<void> complete(String jobId, String filePath) async {
    await (update(
      reportJobs,
    )..where((ReportJobs j) => j.id.equals(jobId))).write(
      ReportJobsCompanion(
        filePath: Value(filePath),
        status: const Value(ReportJobStatus.done),
        generatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Stamps a job failed with the operator-readable reason.
  Future<void> fail(String jobId, String errorText) async {
    await (update(
      reportJobs,
    )..where((ReportJobs j) => j.id.equals(jobId))).write(
      ReportJobsCompanion(
        status: const Value(ReportJobStatus.failed),
        errorText: Value(errorText),
      ),
    );
  }

  /// Recent jobs first — the Reports screen lists what was generated when.
  Future<List<ReportJob>> recentFor(String examId, {int limit = 50}) {
    return (select(reportJobs)
          ..where((ReportJobs j) => j.examId.equals(examId))
          ..orderBy([
            // generatedAt NULLS LAST would put failed jobs first otherwise;
            // id breaks ties because timestamp resolution collides on bursts.
            (ReportJobs j) => OrderingTerm(
              expression: j.generatedAt,
              mode: OrderingMode.desc,
              nulls: NullsOrder.last,
            ),
            (ReportJobs j) => OrderingTerm.desc(j.id),
          ])
          ..limit(limit))
        .get();
  }
}
