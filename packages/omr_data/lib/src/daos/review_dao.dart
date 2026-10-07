import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../app_db.dart';
import '../converters.dart';
import '../enums.dart';
import '../services/audit_log_service.dart';
import '../tables/bubble_reads.dart';
import '../tables/review_queue.dart';
import '../tables/scans.dart';

part 'review_dao.g.dart';

/// One human bubble correction applied on resolve. Writes the addressed
/// bubble_reads row in place with `is_human_correction = 1` — the corrected
/// value then supersedes the machine read on every subsequent re-grade
/// (deterministically, because the PK addresses exactly one bubble).
@immutable
class BubbleCorrection {
  const BubbleCorrection({
    required this.fieldKey,
    required this.optionIndex,
    required this.markClass,
  });

  final String fieldKey;
  final int optionIndex;
  final MarkClass markClass;
}

@DriftAccessor(tables: [ReviewQueue, Scans, BubbleReads])
class ReviewDao extends DatabaseAccessor<AppDb> with _$ReviewDaoMixin {
  ReviewDao(super.attachedDatabase);

  /// Enqueues a review item AND routes the scan to `needsReview` in the same
  /// transaction — the queue and the scan status can never disagree.
  Future<String> enqueue({
    required String tenantId,
    required String scanId,
    required String reasonCode,
    required ReviewSeverity severity,
    List<String> fieldRefs = const <String>[],
  }) {
    return transaction(() async {
      final inserted = await into(reviewQueue).insertReturning(
        ReviewQueueCompanion.insert(
          tenantId: tenantId,
          scanId: scanId,
          reasonCode: reasonCode,
          severity: severity,
          fieldRefsJson: Value(encodeJsonList(<Object?>[...fieldRefs])),
        ),
      );
      final id = inserted.id;
      await (update(scans)..where((Scans s) => s.id.equals(scanId))).write(
        const ScansCompanion(status: Value(ScanStatus.needsReview)),
      );
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'review_queue',
        rowId: id,
        op: SyncOp.insert,
        payload: <String, Object?>{
          'scanId': scanId,
          'reasonCode': reasonCode,
          'severity': severity.name,
        },
      );
      return id;
    });
  }

  /// Resolves a review item, optionally carrying the operator's corrections.
  ///
  /// - corrections overwrite the addressed bubble reads in place;
  /// - the correction payload is archived verbatim on the queue row;
  /// - `corrected` routes the scan to `reviewed`, `unresolvable` to
  ///   `rejected`; `retaken` leaves the scan to be re-captured (its reads
  ///   will be replaced by the new capture's).
  Future<void> resolve(
    String reviewId, {
    String? resolvedBy,
    ReviewOutcome outcome = ReviewOutcome.corrected,
    List<BubbleCorrection> corrections = const <BubbleCorrection>[],
  }) async {
    final item = await (select(
      reviewQueue,
    )..where((ReviewQueue r) => r.id.equals(reviewId))).getSingle();
    await transaction(() async {
      await (update(
        reviewQueue,
      )..where((ReviewQueue r) => r.id.equals(reviewId))).write(
        ReviewQueueCompanion(
          resolvedBy: Value(resolvedBy),
          resolvedAt: Value(DateTime.now().toUtc()),
          correctionJson: Value(
            encodeJsonList(<Object?>[
              for (final c in corrections)
                <String, Object?>{
                  'fieldKey': c.fieldKey,
                  'optionIndex': c.optionIndex,
                  'markClass': c.markClass.name,
                },
            ]),
          ),
          outcome: Value(outcome),
        ),
      );
      for (final correction in corrections) {
        await (update(bubbleReads)..where(
              (BubbleReads b) =>
                  b.scanId.equals(item.scanId) &
                  b.fieldKey.equals(correction.fieldKey) &
                  b.optionIndex.equals(correction.optionIndex),
            ))
            .write(
              BubbleReadsCompanion(
                markClass: Value(correction.markClass),
                isHumanCorrection: const Value(true),
              ),
            );
      }
      // A corrected set bubble IS the sheet's set: grading reads the set
      // from the scan row, so the correction must land there too.
      final setFix = corrections.where(
        (c) => c.fieldKey == 'set' && c.markClass == MarkClass.filled,
      );
      // A sheet can carry several review reasons. A correction clears
      // only its own item; the sheet leaves review once none are open. A
      // reject/retake settles the whole sheet, so its other items close too.
      final otherOpen =
          await (select(reviewQueue)..where(
                (ReviewQueue r) =>
                    r.scanId.equals(item.scanId) &
                    r.id.equals(reviewId).not() &
                    r.outcome.equals(ReviewOutcome.open.name),
              ))
              .get();
      if (outcome != ReviewOutcome.corrected && otherOpen.isNotEmpty) {
        await (update(reviewQueue)..where(
              (ReviewQueue r) => r.id.isIn([for (final o in otherOpen) o.id]),
            ))
            .write(
              ReviewQueueCompanion(
                resolvedBy: Value(resolvedBy),
                resolvedAt: Value(DateTime.now().toUtc()),
                outcome: Value(outcome),
              ),
            );
      }
      final status = switch (outcome) {
        ReviewOutcome.corrected =>
          otherOpen.isEmpty ? ScanStatus.reviewed : null,
        // A retake replaces this photo: it must neither be marked nor sit
        // forever as "to check" once its review item is closed.
        ReviewOutcome.retaken ||
        ReviewOutcome.unresolvable => ScanStatus.rejected,
        ReviewOutcome.open => null,
      };
      if (status != null || setFix.isNotEmpty) {
        await (update(
          scans,
        )..where((Scans s) => s.id.equals(item.scanId))).write(
          ScansCompanion(
            status: status == null ? const Value.absent() : Value(status),
            setCodeRead: setFix.isEmpty
                ? const Value.absent()
                : Value(String.fromCharCode(65 + setFix.last.optionIndex)),
          ),
        );
      }
      await AuditLogService(attachedDatabase).record(
        tenantId: item.tenantId,
        entity: 'review_queue',
        entityId: reviewId,
        action: 'resolve',
        after: {
          'outcome': outcome.name,
          'corrections': corrections.length,
          'scanId': item.scanId,
        },
        byUser: resolvedBy,
      );
    });
  }
}
