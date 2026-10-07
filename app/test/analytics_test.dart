import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/analytics/analytics_screen.dart';
import 'package:omr_app/features/exams/exam_detail_screen.dart';
import 'package:omr_app/src/app_state.dart';
import 'package:omr_app/src/demo_scans.dart';

import 'helpers.dart';

void main() {
  late AppState state;

  setUp(() async {
    state = await seededAppState();
  });

  tearDown(() => state.db.close());

  testWidgets('analysis tab: empty before marking', (tester) async {
    final seeded = await seedExamWithRoster(state, students: 2);
    await tester.pumpWidget(
      wrapForTest(ExamDetailScreen(examId: seeded.examId), state),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analysis'));
    await tester.pumpAndSettle();

    expect(
      find.text('Analysis appears once sheets are scanned and marked.'),
      findsOneWidget,
    );
  });

  testWidgets('analysis tab: class summary, spread and hardest questions', (
    tester,
  ) async {
    final seeded = await seedExamWithRoster(state, students: 4);
    final roster = await state.db.studentsDao.rosterFor(state.instituteId);
    for (var i = 0; i < roster.length; i++) {
      await insertDemoScan(
        db: state.db,
        examId: seeded.examId,
        studentId: roster[i].id,
        rollNo: roster[i].rollNo,
        studentIndex: i,
      );
    }
    await state.grade(seeded.examId, seeded.keyVersionId);

    await tester.pumpWidget(
      wrapForTest(ExamDetailScreen(examId: seeded.examId), state),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analysis'));
    await tester.pumpAndSettle();

    expect(find.text('Class at a glance'), findsOneWidget);
    expect(find.text('students'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('How scores spread'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hardest questions'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(AnalyticsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Hardest questions'), findsOneWidget);
  });
}
