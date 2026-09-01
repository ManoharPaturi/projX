import 'package:drift/drift.dart';
import 'package:meta/meta.dart';

import '../app_db.dart';
import '../converters.dart';
import '../enums.dart';
import '../tables/answer_key_entries.dart';
import '../tables/answer_key_versions.dart';

part 'keys_dao.g.dart';

/// Input for [KeysDao.addEntries] — insert-only by construction; there is no
/// input type that could express an update because no such API exists.
@immutable
class KeyEntryInput {
  const KeyEntryInput({
    required this.setCode,
    required this.questionId,
    this.correctOptions = const <int>[],
    this.correctInteger,
    this.state = KeyEntryState.normal,
    this.scoringRuleId,
  });

  /// Set code ('A'..'D', or '' for single-set papers). Must match what the
  /// scans read into `set_code_read` — the analytics SQL joins on it.
  final String setCode;
  final String questionId;

  /// Correct option indexes into the bubble row, e.g. `[0]` / `[0, 2]`.
  final List<int> correctOptions;
  final int? correctInteger;
  final KeyEntryState state;
  final String? scoringRuleId;
}

/// Answer keys are IMMUTABLE and VERSIONED (plan §5): a wrong key discovered
/// after publishing is fixed by inserting a new version that supersedes the
/// old one and re-grading from bubble_reads — never by editing rows.
///
/// This DAO deliberately exposes no method that updates an
/// `answer_key_entries` row; the SQL layer additionally aborts any UPDATE on
/// that table via the `answer_key_entries_immutable` trigger (v1 migration).
@DriftAccessor(tables: [AnswerKeyVersions, AnswerKeyEntries])
class KeysDao extends DatabaseAccessor<AppDb> with _$KeysDaoMixin {
  KeysDao(super.attachedDatabase);

  /// Inserts a new (provisional) key version. Pass [supersedesId] when this
  /// version replaces an earlier one.
  Future<String> createVersion({
    required String tenantId,
    required String examId,
    required int version,
    required String createdBy,
    String? supersedesId,
  }) {
    return transaction(() async {
      final inserted = await into(answerKeyVersions).insertReturning(
        AnswerKeyVersionsCompanion.insert(
          tenantId: tenantId,
          examId: examId,
          version: version,
          createdBy: createdBy,
          supersedesId: Value(supersedesId),
        ),
      );
      final id = inserted.id;
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'answer_key_versions',
        rowId: id,
        op: SyncOp.insert,
        payload: <String, Object?>{
          'examId': examId,
          'version': version,
          'supersedesId': supersedesId,
        },
      );
      return id;
    });
  }

  /// Bulk-inserts entries. Refused once the version is finalized — publishing
  /// freezes the key. Idempotency is the caller's concern: re-adding an
  /// existing (version, set, question) aborts on the composite PK, which is
  /// the right failure mode for an audit-sensitive write.
  Future<void> addEntries(
    String keyVersionId, {
    required String tenantId,
    required List<KeyEntryInput> entries,
  }) async {
    final version = await _versionOrThrow(keyVersionId);
    if (version.status != KeyVersionStatus.provisional) {
      throw StateError(
        'answer key version $keyVersionId is ${version.status.name}: '
        'entries can no longer be added. Insert a new version instead.',
      );
    }
    await transaction(() async {
      if (entries.isNotEmpty) {
        await batch((Batch b) {
          b.insertAll(answerKeyEntries, <AnswerKeyEntriesCompanion>[
            for (final e in entries)
              AnswerKeyEntriesCompanion.insert(
                tenantId: tenantId,
                keyVersionId: keyVersionId,
                setCode: e.setCode,
                questionId: e.questionId,
                correctOptionsJson: Value(
                  encodeJsonList(<Object?>[...e.correctOptions]),
                ),
                correctInteger: Value(e.correctInteger),
                state: Value(e.state),
                scoringRuleId: Value(e.scoringRuleId),
              ),
          ]);
        });
      }
      await attachedDatabase.syncOutboxDao.enqueue(
        tenantId: tenantId,
        tableName: 'answer_key_entries',
        rowId: keyVersionId,
        op: SyncOp.insert,
        payload: <String, Object?>{
          'keyVersionId': keyVersionId,
          'count': entries.length,
        },
      );
    });
  }

  /// The provisional→finalized transition — the ONLY mutation this DAO ever
  /// performs on a key version. Finalizing an already-final version throws.
  Future<void> finalizeVersion(String keyVersionId) async {
    final version = await _versionOrThrow(keyVersionId);
    if (version.status == KeyVersionStatus.finalized) {
      throw StateError('answer key version $keyVersionId is already final');
    }
    await (update(
      answerKeyVersions,
    )..where((AnswerKeyVersions k) => k.id.equals(keyVersionId))).write(
      const AnswerKeyVersionsCompanion(
        status: Value(KeyVersionStatus.finalized),
      ),
    );
  }

  /// The version results should grade against: the newest FINALIZED version
  /// if any exists, else the newest provisional one.
  Future<AnswerKeyVersion?> activeVersion(String examId) async {
    final rows =
        await (select(answerKeyVersions)
              ..where((AnswerKeyVersions k) => k.examId.equals(examId))
              ..orderBy([
                (AnswerKeyVersions k) => OrderingTerm.desc(k.version),
              ]))
            .get();
    for (final row in rows) {
      if (row.status == KeyVersionStatus.finalized) {
        return row;
      }
    }
    return rows.isEmpty ? null : rows.first;
  }

  /// All versions of an exam, newest first — the key editor's history list.
  Future<List<AnswerKeyVersion>> versionsFor(String examId) {
    return (select(answerKeyVersions)
          ..where((AnswerKeyVersions k) => k.examId.equals(examId))
          ..orderBy([(AnswerKeyVersions k) => OrderingTerm.desc(k.version)]))
        .get();
  }

  Future<AnswerKeyVersion> versionById(String keyVersionId) {
    return (select(
      answerKeyVersions,
    )..where((AnswerKeyVersions k) => k.id.equals(keyVersionId))).getSingle();
  }

  /// Entries of one version in stable (set, question) order.
  Future<List<AnswerKeyEntry>> entriesFor(String keyVersionId) {
    return (select(answerKeyEntries)
          ..where((AnswerKeyEntries e) => e.keyVersionId.equals(keyVersionId))
          ..orderBy([
            (AnswerKeyEntries e) => OrderingTerm.asc(e.setCode),
            (AnswerKeyEntries e) => OrderingTerm.asc(e.questionId),
          ]))
        .get();
  }

  Future<AnswerKeyVersion> _versionOrThrow(String id) async {
    final version = await (select(
      answerKeyVersions,
    )..where((k) => k.id.equals(id))).getSingleOrNull();
    if (version == null) {
      throw StateError('unknown answer key version $id');
    }
    return version;
  }
}
