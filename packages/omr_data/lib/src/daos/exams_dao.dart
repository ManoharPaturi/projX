import 'package:drift/drift.dart';

import '../app_db.dart';
import '../converters.dart';
import '../enums.dart';
import '../tables/exams.dart';
import '../tables/question_sets.dart';

part 'exams_dao.g.dart';

@DriftAccessor(tables: [Exams, QuestionSets])
class ExamsDao extends DatabaseAccessor<AppDb> with _$ExamsDaoMixin {
  ExamsDao(super.attachedDatabase);

  /// Creates an exam in draft. Grading config is JSON (preset + overrides)
  /// chosen in exam setup.
  Future<String> createExam({
    required String tenantId,
    required String instituteId,
    required String name,
    required String sheetLayoutId,
    required int totalQuestions,
    DateTime? heldAt,
    String gradingConfigJson = '{}',
  }) {
    return transaction(() async {
      // insertReturning, not insert(): ids are client UUIDs, so the int rowid
      // insert() reports is useless — the RETURNING row carries the id the
      // clientDefault just minted (and the one the outbox must replay).
      final inserted = await into(exams).insertReturning(
        ExamsCompanion.insert(
          tenantId: tenantId,
          instituteId: instituteId,
          name: name,
          sheetLayoutId: sheetLayoutId,
          totalQuestions: totalQuestions,
          heldAt: Value(heldAt),
          gradingConfigJson: Value(gradingConfigJson),
        ),
      );
      final id = inserted.id;
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'exams',
        rowId: id,
        op: SyncOp.insert,
        payload: <String, Object?>{'id': id, 'name': name},
      );
      return id;
    });
  }

  /// Lifecycle transitions only; status never goes backwards here — callers
  /// drive draft → active → graded → published.
  Future<int> setStatus(String examId, ExamStatus status) {
    return (update(exams)..where((Exams e) => e.id.equals(examId))).write(
      ExamsCompanion(status: Value(status)),
    );
  }

  Future<Exam?> byId(String examId) {
    return (select(
      exams,
    )..where((Exams e) => e.id.equals(examId))).getSingleOrNull();
  }

  Future<List<Exam>> forInstitute(String tenantId, String instituteId) {
    return (select(exams)
          ..where(
            (Exams e) =>
                e.tenantId.equals(tenantId) & e.instituteId.equals(instituteId),
          )
          ..orderBy([(Exams e) => OrderingTerm.desc(e.createdAt)]))
        .get();
  }

  /// Adds (or idempotently replaces) the question map for one set code.
  Future<void> addQuestionSet({
    required String tenantId,
    required String examId,
    required String setCode,
    required Map<String, Object?> questionMap,
  }) async {
    await into(questionSets).insertOnConflictUpdate(
      QuestionSetsCompanion.insert(
        tenantId: tenantId,
        examId: examId,
        setCode: setCode,
        questionMapJson: encodeJsonObject(questionMap),
      ),
    );
  }
}
