import 'package:drift/drift.dart';

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
  Future<List<Student>> rosterFor(
    String instituteId, {
    String? query,
  }) async {
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
    final rows = await (selectOnly(students)
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
      if (!seen.add(roll)) {
        duplicatesInFile.add(roll);
        continue;
      }
      accepted.add(entry);
    }

    // Pre-select what is already enrolled. (Counting on insertOrIgnore's
    // return is a trap: SQLite leaves lastInsertRowId STALE on an ignored
    // insert, so an ignored row reports the previous row's id, not 0.)
    final acceptedRolls = accepted.map((e) => e.rollNo.trim()).toList();
    Set<String> alreadyEnrolled;
    if (acceptedRolls.isEmpty) {
      alreadyEnrolled = const <String>{};
    } else {
      final enrolled = await (select(students)
            ..where(
              (Students s) =>
                  s.instituteId.equals(instituteId) &
                  s.rollNo.isIn(acceptedRolls),
            ))
          .get();
      alreadyEnrolled = enrolled.map((s) => s.rollNo).toSet();
    }

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
}
