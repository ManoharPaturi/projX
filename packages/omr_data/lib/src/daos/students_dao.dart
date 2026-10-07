import 'package:drift/drift.dart';
import 'package:omr_core/omr_core.dart' show canonicalRoll;

import '../app_db.dart';
import '../tables/students.dart';

part 'students_dao.g.dart';

/// One roster row to import — already parsed from whatever the operator
/// handed us (CSV paste, share-in file). Roll number is the identity; name
/// and batch are optional PII the institute may skip entirely.
class RosterEntry {
  const RosterEntry({required this.rollNo, this.name, this.batch});

  final String rollNo;
  final String? name;
  final String? batch;
}

/// How a roster import landed: what came in, what was refused, and why —
/// enough for the import screen to show an actionable summary instead of a
/// row count.
class RosterImportResult {
  const RosterImportResult({
    required this.imported,
    required this.duplicatesInFile,
    required this.existingRolls,
    required this.invalidRolls,
  });

  /// Rows newly inserted.
  final int imported;

  /// Rolls appearing more than once in the file — every copy after the
  /// first was skipped (the first one won).
  final List<String> duplicatesInFile;

  /// Rolls already on the roster for this institute — skipped, NOT updated:
  /// an import must never silently rewrite an enrolled student's name.
  final List<String> existingRolls;

  /// Blank rolls etc. — refused before touching the table.
  final List<String> invalidRolls;

  int get skipped =>
      duplicatesInFile.length + existingRolls.length + invalidRolls.length;

  bool get clean =>
      duplicatesInFile.isEmpty && existingRolls.isEmpty && invalidRolls.isEmpty;
}

@DriftAccessor(tables: [Students])
class StudentsDao extends DatabaseAccessor<AppDb> with _$StudentsDaoMixin {
  StudentsDao(super.attachedDatabase);

  /// The roster in roll order, optionally filtered by a prefix/substring of
  /// the roll (what a search box sends).
  Future<List<Student>> rosterFor(String instituteId, {String? query}) async {
    final q = (query == null || query.isEmpty) ? null : query.trim();
    return (select(students)
          ..where(
            (Students s) =>
                s.instituteId.equals(instituteId) &
                (q == null ? const Constant(true) : s.rollNo.contains(q)),
          )
          ..orderBy([(Students s) => OrderingTerm.asc(s.rollNo)]))
        .get();
  }

  Future<int> count(String instituteId) async {
    final count = countAll();
    final rows =
        await (selectOnly(students)
              ..addColumns([count])
              // selectOnly's where takes a direct expression, no table lambda.
              ..where(students.instituteId.equals(instituteId)))
            .getSingle();
    return rows.read(count) ?? 0;
  }

  /// Bulk-imports roster rows. Import is additive and never destructive:
  /// new rolls insert, rolls already on the roster are skipped and reported,
  /// repeats inside the file keep only the first copy, junk rows are refused.
  ///
  /// One transaction: an import either lands whole or not at all — a
  /// half-imported roster is the worst state for an operator to untangle.
  Future<RosterImportResult> importRoster(
    String tenantId,
    String instituteId,
    List<RosterEntry> entries,
  ) async {
    final duplicatesInFile = <String>[];
    final invalidRolls = <String>[];
    final seen = <String>{};
    final accepted = <RosterEntry>[];

    for (final entry in entries) {
      final roll = entry.rollNo.trim();
      if (roll.isEmpty) {
        invalidRolls.add(entry.rollNo);
        continue;
      }
      // Canonical form: `0042` and `42` are the same bubbled roll.
      if (!seen.add(canonicalRoll(roll))) {
        duplicatesInFile.add(roll);
        continue;
      }
      accepted.add(entry);
    }

    // Pre-select what is already enrolled, by canonical roll. (Counting on
    // insertOrIgnore's return is a trap: SQLite leaves lastInsertRowId STALE
    // on an ignored insert, so an ignored row reports the previous row's id.)
    final enrolledByCanonical = <String, String>{
      for (final s in await rosterFor(instituteId))
        canonicalRoll(s.rollNo): s.rollNo,
    };
    final alreadyEnrolled = <String>{
      for (final entry in accepted)
        if (enrolledByCanonical.containsKey(canonicalRoll(entry.rollNo)))
          entry.rollNo.trim(),
    };

    await transaction(() async {
      for (final entry in accepted) {
        if (alreadyEnrolled.contains(entry.rollNo.trim())) {
          continue;
        }
        // insertOrIgnore stays as the race backstop — two imports landing
        // together must not throw, the loser simply no-ops.
        await into(students).insert(
          StudentsCompanion.insert(
            tenantId: tenantId,
            instituteId: instituteId,
            rollNo: entry.rollNo.trim(),
            name: Value(entry.name?.trim()),
            batch: Value(entry.batch?.trim()),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });

    return RosterImportResult(
      imported: accepted.length - alreadyEnrolled.length,
      duplicatesInFile: duplicatesInFile,
      existingRolls: alreadyEnrolled.toList()..sort(),
      invalidRolls: invalidRolls,
    );
  }

  /// The enrolled student a scanned [roll] belongs to, compared by
  /// [canonicalRoll] — a sheet bubbled `0001234` and a roster row typed
  /// `1234` are the same student. Null when nobody matches.
  Future<Student?> findByRoll(String instituteId, String roll) async {
    final wanted = canonicalRoll(roll);
    for (final s in await rosterFor(instituteId)) {
      if (canonicalRoll(s.rollNo) == wanted) return s;
    }
    return null;
  }

  /// Adds one student typed in by the operator.
  Future<AddStudentResult> addStudent(
    String tenantId,
    String instituteId,
    RosterEntry entry,
  ) async {
    final result = await importRoster(tenantId, instituteId, [entry]);
    if (result.imported == 1) return AddStudentResult.added;
    if (result.existingRolls.isNotEmpty) return AddStudentResult.duplicate;
    return AddStudentResult.invalid;
  }

  /// Removes a student who has never been scanned. A student with any scan
  /// or result is kept — those rows are the audit trail behind published
  /// marks — and `false` is returned so the UI can say why.
  Future<bool> deleteStudent(String studentId) async {
    final db = attachedDatabase;
    final scans =
        await (db.select(db.scans)
              ..where((t) => t.studentId.equals(studentId))
              ..limit(1))
            .get();
    final results =
        await (db.select(db.results)
              ..where((t) => t.studentId.equals(studentId))
              ..limit(1))
            .get();
    if (scans.isNotEmpty || results.isNotEmpty) return false;
    final deleted = await (delete(
      students,
    )..where((s) => s.id.equals(studentId))).go();
    return deleted == 1;
  }
}

/// Outcome of [StudentsDao.addStudent].
enum AddStudentResult { added, duplicate, invalid }
