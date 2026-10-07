import 'package:omr_data/omr_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Review resolution: what a human decision does to the sheet it settles.
void main() {
  late AppDb db;
  late String examId;

  setUp(() async {
    db = await openTestDb();
    final instituteId = await seedInstitute(db);
    final layoutId = await seedLayout(db);
    examId = await seedExam(db, instituteId, sheetLayoutId: layoutId);
  });

  tearDown(() => db.close());

  Future<String> flaggedScan() => db.scansDao.insertScanWithReads(
    scanRow(examId: examId, status: ScanStatus.needsReview),
    const [
      BubbleReadInput(
        fieldKey: 'set',
        optionIndex: 0,
        markClass: MarkClass.empty,
      ),
      BubbleReadInput(
        fieldKey: 'set',
        optionIndex: 1,
        markClass: MarkClass.empty,
      ),
    ],
  );

  Future<String> enqueue(String scanId, String code) => db.reviewDao.enqueue(
    tenantId: kTenantId,
    scanId: scanId,
    reasonCode: code,
    severity: ReviewSeverity.mandatory,
  );

  Future<Scan> scan(String id) async =>
      (await db.scansDao.fetchWithReads(id))!.scan;

  test('a corrected set bubble becomes the sheet\'s set', () async {
    final scanId = await flaggedScan();
    final item = await enqueue(scanId, 'SET_BLANK');

    await db.reviewDao.resolve(
      item,
      corrections: const [
        BubbleCorrection(
          fieldKey: 'set',
          optionIndex: 1,
          markClass: MarkClass.filled,
        ),
        BubbleCorrection(
          fieldKey: 'set',
          optionIndex: 0,
          markClass: MarkClass.empty,
        ),
      ],
    );

    expect((await scan(scanId)).setCodeRead, 'B');
    expect((await scan(scanId)).status, ScanStatus.reviewed);
  });

  test('a retake retires the photo instead of leaving it "to check"', () async {
    final scanId = await flaggedScan();
    final item = await enqueue(scanId, 'NO_MARKER_ERR');

    await db.reviewDao.resolve(item, outcome: ReviewOutcome.retaken);

    expect((await scan(scanId)).status, ScanStatus.rejected);
    expect(await db.scansDao.pendingReview(), isEmpty);
  });

  test(
    'a sheet with two reasons stays in review until both are settled',
    () async {
      final scanId = await flaggedScan();
      final first = await enqueue(scanId, 'MULTI_BUBBLE_WARN');
      await enqueue(scanId, 'ROLL_NOT_ON_ROSTER');

      await db.reviewDao.resolve(first);

      expect((await scan(scanId)).status, ScanStatus.needsReview);
      final pending = await db.scansDao.pendingReview();
      expect(pending.single.reasonCode, 'ROLL_NOT_ON_ROSTER');
    },
  );

  test('rejecting a sheet closes all of its open reasons', () async {
    final scanId = await flaggedScan();
    final first = await enqueue(scanId, 'MULTI_BUBBLE_WARN');
    await enqueue(scanId, 'ROLL_NOT_ON_ROSTER');

    await db.reviewDao.resolve(first, outcome: ReviewOutcome.unresolvable);

    expect((await scan(scanId)).status, ScanStatus.rejected);
    final open = await (db.select(
      db.reviewQueue,
    )..where((r) => r.outcome.equals('open'))).get();
    expect(open, isEmpty);
  });
}
