import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late AppDb db;
  late String examId;

  setUp(() async {
    db = await openTestDb();
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'insertScanWithReads writes the scan and its reads atomically',
    () async {
      final scanId = await db.scansDao.insertScanWithReads(
        scanRow(examId: examId, rollNoRead: 'R001', setCodeRead: 'A'),
        const [
          BubbleReadInput(
            fieldKey: 'q2',
            optionIndex: 1,
            markClass: MarkClass.filled,
            meanIntensity: 30,
            fillRatio: 0.9,
            confidence: 0.95,
            thresholdUsed: 128,
          ),
          BubbleReadInput(
            fieldKey: 'q1',
            optionIndex: 0,
            markClass: MarkClass.filled,
          ),
          BubbleReadInput(
            fieldKey: 'q1',
            optionIndex: 1,
            markClass: MarkClass.empty,
          ),
        ],
      );

      final detail = await db.scansDao.fetchWithReads(scanId);
      expect(detail, isNotNull);
      expect(detail!.scan.id, scanId);
      expect(detail.scan.rollNoRead, 'R001');
      expect(detail.scan.status, ScanStatus.graded);

      // Ordered by (fieldKey, optionIndex) regardless of insert order.
      expect(detail.reads.map((r) => '${r.fieldKey}:${r.optionIndex}'), [
        'q1:0',
        'q1:1',
        'q2:1',
      ]);
      // reads.first is q1:0 (ordering), which carries no measurement — the
      // instrumented read is q2:1.
      final q2 = detail.reads.singleWhere((r) => r.fieldKey == 'q2');
      expect(q2.meanIntensity, 30);
      expect(q2.isHumanCorrection, false);
    },
  );

  test('a read that violates the PK rolls the WHOLE insert back', () async {
    final scansBefore = await db.select(db.scans).get();
    final outboxBefore = await db.select(db.syncOutbox).get();

    // Two reads with the same (fieldKey, optionIndex) — a PK violation inside
    // the batch. The scan insert must vanish with them.
    await expectLater(
      db.scansDao.insertScanWithReads(
        scanRow(examId: examId, id: 'scan-rollback'),
        const [
          BubbleReadInput(
            fieldKey: 'q1',
            optionIndex: 0,
            markClass: MarkClass.filled,
          ),
          BubbleReadInput(
            fieldKey: 'q1',
            optionIndex: 0,
            markClass: MarkClass.probable,
          ),
        ],
      ),
      throwsA(isA<Exception>()),
    );

    expect(
      await db.select(db.scans).get(),
      scansBefore,
      reason: 'no half-written scan may survive',
    );
    expect(
      (await db.select(db.bubbleReads).get()).where(
        (r) => r.scanId == 'scan-rollback',
      ),
      isEmpty,
    );
    expect(
      await db.select(db.syncOutbox).get(),
      outboxBefore,
      reason:
          'the transactional outbox rolls back with the rows — a scan '
          'row was never inserted, so nothing may be enqueued for sync',
    );
  });

  test(
    'UNIQUE(examId, id) makes capture replay idempotent-by-rejection',
    () async {
      await db.scansDao.insertScanWithReads(
        scanRow(examId: examId, id: 'scan-replay'),
        const [],
      );
      // The same capture, uploaded again (process crash after server ack, etc).
      await expectLater(
        db.scansDao.insertScanWithReads(
          scanRow(examId: examId, id: 'scan-replay'),
          const [],
        ),
        throwsA(isA<Exception>()),
      );
      expect((await db.select(db.scans).get()).length, 1);

      // The replay key is the capture UUID itself — a sheet cannot reappear as
      // a different exam's scan either (M5's server replay keys on id alone,
      // and bubble_reads FKs point at scans.id).
      final instituteId = (await db.select(db.institutes).get()).single.id;
      final layoutId = (await db.select(db.sheetLayouts).get()).single.id;
      final otherExamId = await seedExam(
        db,
        instituteId,
        sheetLayoutId: layoutId,
        name: 'Mock 2',
      );
      await expectLater(
        db.scansDao.insertScanWithReads(
          scanRow(examId: otherExamId, id: 'scan-replay'),
          const [],
        ),
        throwsA(isA<Exception>()),
      );
      expect((await db.select(db.scans).get()).length, 1);

      // A fresh capture under that other exam is of course fine.
      await db.scansDao.insertScanWithReads(
        scanRow(examId: otherExamId),
        const [],
      );
      expect((await db.select(db.scans).get()).length, 2);
    },
  );

  test('markReviewed routes a scan out of the review queue', () async {
    final scanId = await db.scansDao.insertScanWithReads(
      scanRow(examId: examId),
      const [],
    );
    await db.reviewDao.enqueue(
      tenantId: kTenantId,
      scanId: scanId,
      reasonCode: 'roll_mismatch',
      severity: ReviewSeverity.high,
    );
    expect(
      (await db.scansDao.fetchWithReads(scanId))!.scan.status,
      ScanStatus.needsReview,
    );

    await db.scansDao.markReviewed(scanId);

    expect(
      (await db.scansDao.fetchWithReads(scanId))!.scan.status,
      ScanStatus.reviewed,
    );
    // And it leaves the pending worklist with it.
    expect(await db.scansDao.pendingReview(examId: examId), isEmpty);
  });

  test('countsByStatus groups per status for one exam only', () async {
    final instituteId = (await db.select(db.institutes).get()).single.id;
    final layoutId = (await db.select(db.sheetLayouts).get()).single.id;
    final otherExamId = await seedExam(
      db,
      instituteId,
      sheetLayoutId: layoutId,
      name: 'Mock 2',
    );

    await db.scansDao.insertScanWithReads(scanRow(examId: examId), const []);
    await db.scansDao.insertScanWithReads(scanRow(examId: examId), const []);
    final reviewScanId = await db.scansDao.insertScanWithReads(
      scanRow(examId: examId),
      const [],
    );
    await db.reviewDao.enqueue(
      tenantId: kTenantId,
      scanId: reviewScanId,
      reasonCode: 'low_confidence',
      severity: ReviewSeverity.medium,
    );
    await db.scansDao.insertScanWithReads(
      scanRow(examId: otherExamId),
      const [],
    ); // not this exam

    final counts = await db.scansDao.countsByStatus(examId);
    expect(counts, {ScanStatus.graded: 2, ScanStatus.needsReview: 1});
  });

  test(
    'pendingReview: severity bands first, FIFO (oldest capture) within',
    () async {
      Future<void> seedItem(
        String label,
        ReviewSeverity severity,
        DateTime capturedAt,
      ) async {
        final scanId = await db.scansDao.insertScanWithReads(
          scanRow(examId: examId, rollNoRead: label, capturedAt: capturedAt),
          const [],
        );
        await db.reviewDao.enqueue(
          tenantId: kTenantId,
          scanId: scanId,
          reasonCode: 'gate_$label',
          severity: severity,
        );
      }

      await seedItem(
        'medium-old',
        ReviewSeverity.medium,
        DateTime.utc(2026, 1, 1, 9),
      );
      await seedItem(
        'mandatory',
        ReviewSeverity.mandatory,
        DateTime.utc(2026, 1, 1, 12),
      );
      await seedItem('high', ReviewSeverity.high, DateTime.utc(2026, 1, 1, 11));
      await seedItem(
        'medium-new',
        ReviewSeverity.medium,
        DateTime.utc(2026, 1, 1, 10),
      );

      final pending = await db.scansDao.pendingReview(examId: examId);
      expect(
        pending.map((r) => r.rollNoRead).toList(),
        ['mandatory', 'high', 'medium-old', 'medium-new'],
        reason:
            'mandatory beats high beats medium; within medium the sheet '
            'captured at 09:00 waits longest so it surfaces first',
      );
      expect(pending.first.severity, ReviewSeverity.mandatory);
      expect(pending.map((r) => r.reasonCode).toSet().length, 4);

      // examId filter: another exam's queue is invisible here.
      expect(await db.scansDao.pendingReview(), isNotEmpty);
      expect(pending.every((r) => r.examId == examId), isTrue);
    },
  );

  test(
    'review resolve applies human corrections to the exact bubbles',
    () async {
      final scanId = await db.scansDao
          .insertScanWithReads(scanRow(examId: examId), const [
            BubbleReadInput(
              fieldKey: 'roll1',
              optionIndex: 3,
              markClass: MarkClass.probable,
            ),
            BubbleReadInput(
              fieldKey: 'roll1',
              optionIndex: 4,
              markClass: MarkClass.filled,
            ),
          ]);
      final reviewId = await db.reviewDao.enqueue(
        tenantId: kTenantId,
        scanId: scanId,
        reasonCode: 'multi_mark_roll',
        severity: ReviewSeverity.mandatory,
        fieldRefs: const ['roll1:3', 'roll1:4'],
      );

      await db.reviewDao.resolve(
        reviewId,
        resolvedBy: 'operator-1',
        outcome: ReviewOutcome.corrected,
        corrections: const [
          BubbleCorrection(
            fieldKey: 'roll1',
            optionIndex: 3,
            markClass: MarkClass.filled,
          ),
          BubbleCorrection(
            fieldKey: 'roll1',
            optionIndex: 4,
            markClass: MarkClass.empty,
          ),
        ],
      );

      final detail = await db.scansDao.fetchWithReads(scanId);
      expect(detail, isNotNull, reason: 'scan + reads must exist');
      final byOption = {for (final r in detail!.reads) r.optionIndex: r};
      expect(byOption[3]!.markClass, MarkClass.filled);
      expect(byOption[3]!.isHumanCorrection, isTrue);
      expect(byOption[4]!.markClass, MarkClass.empty);
      expect(byOption[4]!.isHumanCorrection, isTrue);
      expect(detail.scan.status, ScanStatus.reviewed);
    },
  );
}
