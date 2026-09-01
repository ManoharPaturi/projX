import 'package:flutter/material.dart' show MaterialApp, Widget;
import 'package:omr_app/src/app_state.dart';
import 'package:omr_app/src/db/open_db.dart';
import 'package:omr_data/omr_data.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider;

/// Test boot: memory db + the same first-run seed production runs. Widget
/// tests therefore exercise the real tenant/institute/layout path, not a
/// parallel fixture.
Future<AppState> seededAppState() async {
  final db = AppDb.memory();
  await db.customSelect('SELECT 1').getSingle();
  final instituteId = await seedFirstRun(db);
  return AppState(
    db: db,
    instituteId: instituteId,
    instituteName: 'My Institute',
  );
}

/// A seeded exam + complete single-set key (option = i % 4) over the
/// Standard-90 layout, plus a three-student roster.
class SeededExam {
  SeededExam({
    required this.examId,
    required this.keyVersionId,
    required this.rollNoByIndex,
  });

  final String examId;
  final String keyVersionId;
  final List<String> rollNoByIndex;
}

Future<SeededExam> seedExamWithRoster(
  AppState state, {
  String name = 'JEE Mock 1',
  int students = 3,
}) async {
  final db = state.db;
  final layouts = await db.layoutsDao.activeForTenant(state.tenantId);
  final standard90 = layouts.firstWhere((l) => l.layoutId == 'std90');

  final examId = await db.examsDao.createExam(
    tenantId: state.tenantId,
    instituteId: state.instituteId,
    name: name,
    sheetLayoutId: standard90.id,
    totalQuestions: 90,
  );
  final keyVersionId = await db.keysDao.createVersion(
    tenantId: state.tenantId,
    examId: examId,
    version: 1,
    createdBy: 'test',
  );
  final layout = await GradingService(db).layoutContextFor(examId);
  await db.keysDao.addEntries(
    keyVersionId,
    tenantId: state.tenantId,
    entries: [
      for (var i = 0; i < layout.questionOrder.length; i++)
        KeyEntryInput(
          setCode: 'A',
          questionId: layout.questionOrder[i],
          correctOptions: [i % 4],
        ),
    ],
  );

  final rolls = [
    for (var i = 1; i <= students; i++) 'R${i.toString().padLeft(3, '0')}',
  ];
  await db.studentsDao.importRoster(
    state.tenantId,
    state.instituteId,
    [for (final roll in rolls) RosterEntry(rollNo: roll)],
  );

  return SeededExam(
    examId: examId,
    keyVersionId: keyVersionId,
    rollNoByIndex: rolls,
  );
}

/// Wraps a screen the way the real app does, for tests that push a single
/// screen instead of the whole shell.
Widget wrapForTest(Widget child, AppState state) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(home: child),
  );
}
