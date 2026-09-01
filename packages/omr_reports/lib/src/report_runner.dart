import 'dart:io';

import 'package:omr_data/omr_data.dart';

/// Runs one report generation end-to-end (plan §7): write the artifact, record
/// the `report_jobs` row. Every export goes through here so "what was
/// generated, from which params, where did it land" is always answerable —
/// and a failed generation leaves a failed row, not silence.
class ReportRunner {
  ReportRunner(this.db);

  final AppDb db;

  /// Runs [build], writes its bytes to `directory/fileName`, and records the
  /// job. Returns the artifact's full path.
  Future<String> run({
    required String tenantId,
    required String examId,
    required ReportJobType type,
    required String format,
    required String directory,
    required String fileName,
    required Map<String, Object?> params,
    required Future<List<int>> Function() build,
  }) async {
    final jobId = await db.reportJobsDao.start(
      tenantId: tenantId,
      examId: examId,
      type: type,
      format: format,
      params: params,
    );
    try {
      final bytes = await build();
      final artifact = File('$directory/$fileName');
      await artifact.parent.create(recursive: true);
      await artifact.writeAsBytes(bytes, flush: true);
      await db.reportJobsDao.complete(jobId, artifact.path);
      return artifact.path;
    } catch (e) {
      await db.reportJobsDao.fail(jobId, e.toString());
      rethrow;
    }
  }
}
