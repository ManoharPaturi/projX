import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../app_db.dart';
import '../enums.dart';
import '../tables/bubble_reads.dart';
import '../tables/review_queue.dart';
import '../tables/scans.dart';

part 'scans_dao.g.dart';

/// A scan together with its bubble reads, fetched in one joined read.
@immutable
class ScanDetail {
  const ScanDetail({required this.scan, required this.reads});

  final Scan scan;
  final List<BubbleRead> reads;
}

/// One row of the pending-review worklist (scans ⋈ open review items).
@immutable
class PendingReviewRow {
  const PendingReviewRow({
    required this.reviewId,
    required this.scanId,
    required this.examId,
    required this.rollNoRead,
    required this.setCodeRead,
    required this.sheetConfidence,
    required this.reasonCode,
    required this.severity,
    required this.capturedAt,
  });

  final String reviewId;
  final String scanId;
  final String examId;
  final String? rollNoRead;
  final String? setCodeRead;
  final double? sheetConfidence;
  final String reasonCode;
  final ReviewSeverity severity;

  /// ISO-8601 UTC — raw SQL reads bypass the column converter.
  final DateTime capturedAt;
}

/// Input for [ScansDao.insertScanWithReads]: the DAO stamps `scan_id` and
/// `tenant_id` itself, so reads can never point at the wrong scan.
@immutable
class BubbleReadInput {
  const BubbleReadInput({
    required this.fieldKey,
    required this.optionIndex,
    required this.markClass,
    this.meanIntensity,
    this.fillRatio,
    this.confidence,
    this.thresholdUsed,
    this.isHumanCorrection = false,
  });

  final String fieldKey;
  final int optionIndex;
  final MarkClass markClass;
  final double? meanIntensity;
  final double? fillRatio;
  final double? confidence;
  final double? thresholdUsed;
  final bool isHumanCorrection;
}

@DriftAccessor(tables: [Scans, BubbleReads, ReviewQueue])
class ScansDao extends DatabaseAccessor<AppDb> with _$ScansDaoMixin {
  ScansDao(super.attachedDatabase);

  /// Inserts a scan AND its bubble reads as ONE atomic unit: if any read
  /// violates a constraint the whole insert rolls back — a half-written scan
  /// (or a scan without its re-grade substrate) is never observable.
  ///
  /// The caller-supplied `id` (when present) is the idempotency key: replaying
  /// the same capture into the same exam hits the ux_scans_exam_id unique
  /// index and the second write aborts.
  Future<String> insertScanWithReads(
    ScansCompanion scan,
    List<BubbleReadInput> reads,
  ) {
    return transaction(() async {
      final scanId = (await into(scans).insertReturning(scan)).id;
      if (reads.isNotEmpty) {
        await batch((Batch b) {
          b.insertAll(bubbleReads, <BubbleReadsCompanion>[
            for (final r in reads)
              BubbleReadsCompanion.insert(
                tenantId: scan.tenantId.value,
                scanId: scanId,
                fieldKey: r.fieldKey,
                optionIndex: r.optionIndex,
                markClass: r.markClass,
                meanIntensity: Value(r.meanIntensity),
                fillRatio: Value(r.fillRatio),
                confidence: Value(r.confidence),
                thresholdUsed: Value(r.thresholdUsed),
                isHumanCorrection: Value(r.isHumanCorrection),
              ),
          ]);
        });
      }
      final tenantId = scan.tenantId.value;
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'scans',
        rowId: scanId,
        op: SyncOp.insert,
        payload: <String, Object?>{'examId': scan.examId.value, 'id': scanId},
      );
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'bubble_reads',
        rowId: scanId,
        op: SyncOp.insert,
        payload: <String, Object?>{'scanId': scanId, 'count': reads.length},
      );
      return scanId;
    });
  }

  /// Fetches a scan with all its reads, ordered (fieldKey, optionIndex) —
  /// the review screen's zoomed-crop + read-values pairing.
  Future<ScanDetail?> fetchWithReads(String scanId) async {
    final query =
        select(scans).join([
            leftOuterJoin(bubbleReads, bubbleReads.scanId.equalsExp(scans.id)),
          ])
          ..where(scans.id.equals(scanId))
          ..orderBy([
            OrderingTerm.asc(bubbleReads.fieldKey),
            OrderingTerm.asc(bubbleReads.optionIndex),
          ]);
    final rows = await query.get();
    if (rows.isEmpty) {
      return null;
    }
    final scan = rows.first.readTable(scans);
    final reads = <BubbleRead>[];
    for (final row in rows) {
      final read = row.readTableOrNull(bubbleReads);
      if (read != null) {
        reads.add(read);
      }
    }
    return ScanDetail(scan: scan, reads: reads);
  }

  /// Marks a review-corrected scan as reviewed.
  Future<int> markReviewed(String scanId) {
    return (update(scans)..where((Scans s) => s.id.equals(scanId))).write(
      const ScansCompanion(status: Value(ScanStatus.reviewed)),
    );
  }

  /// Per-status scan counts for one exam (dashboard + review badge).
  Future<Map<ScanStatus, int>> countsByStatus(String examId) async {
    final count = countAll();
    final rows =
        await (selectOnly(scans)
              ..addColumns([scans.status, count])
              ..where(scans.examId.equals(examId))
              ..groupBy([scans.status]))
            .get();
    return <ScanStatus, int>{
      for (final row in rows)
        // readWithConverter: status is a textEnum column, so plain read()
        // would hand back the raw SQL string, not the enum.
        row.readWithConverter(scans.status)!: row.read(count) ?? 0,
    };
  }

  /// The review worklist: open items whose scan is still routed to review,
  /// most severe first, then oldest capture (FIFO within a severity band —
  /// the operator always sees the sheet that has been waiting longest).
  ///
  /// Raw SQL because the severity ordering is a CASE, not a column order.
  Future<List<PendingReviewRow>> pendingReview({String? examId}) async {
    final rows = await customSelect(
      // exam_id comes from the JOIN — review_queue has no exam column of its
      // own (the scan owns that relationship).
      'SELECT rq.id AS review_id, rq.scan_id, s.exam_id AS exam_id, '
      'rq.reason_code, rq.severity, s.roll_no_read, s.set_code_read, '
      's.sheet_confidence, s.captured_at '
      'FROM review_queue rq '
      'JOIN scans s ON s.id = rq.scan_id '
      'WHERE rq.outcome = \'open\' AND s.status = \'needsReview\' '
      'AND (?1 IS NULL OR s.exam_id = ?1) '
      'ORDER BY CASE rq.severity '
      "  WHEN 'mandatory' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 "
      '  ELSE 3 END ASC, '
      's.captured_at ASC, rq.scan_id ASC',
      // Variable<String> (not Variable<String?>): drift bounds the type
      // parameter at Object, and the null examId rides in the nullable value
      // field — which is exactly what `?1 IS NULL OR …` wants.
      variables: [Variable<String>(examId)],
      readsFrom: {scans, reviewQueue},
    ).get();
    return <PendingReviewRow>[
      for (final row in rows)
        PendingReviewRow(
          reviewId: row.read<String>('review_id'),
          scanId: row.read<String>('scan_id'),
          examId: row.read<String>('exam_id'),
          rollNoRead: row.readNullable<String>('roll_no_read'),
          setCodeRead: row.readNullable<String>('set_code_read'),
          sheetConfidence: row.readNullable<double>('sheet_confidence'),
          reasonCode: row.read<String>('reason_code'),
          severity: ReviewSeverity.values.byName(row.read<String>('severity')),
          capturedAt: DateTime.parse(row.read<String>('captured_at')),
        ),
    ];
  }
}
