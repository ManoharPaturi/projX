// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keys_dao.dart';

// ignore_for_file: type=lint
mixin _$KeysDaoMixin on DatabaseAccessor<AppDb> {
  $InstitutesTable get institutes => attachedDatabase.institutes;
  $SheetLayoutsTable get sheetLayouts => attachedDatabase.sheetLayouts;
  $ExamsTable get exams => attachedDatabase.exams;
  $AnswerKeyVersionsTable get answerKeyVersions =>
      attachedDatabase.answerKeyVersions;
  $ScoringRulesTable get scoringRules => attachedDatabase.scoringRules;
  $AnswerKeyEntriesTable get answerKeyEntries =>
      attachedDatabase.answerKeyEntries;
  KeysDaoManager get managers => KeysDaoManager(this);
}

class KeysDaoManager {
  final _$KeysDaoMixin _db;
  KeysDaoManager(this._db);
  $$InstitutesTableTableManager get institutes =>
      $$InstitutesTableTableManager(_db.attachedDatabase, _db.institutes);
  $$SheetLayoutsTableTableManager get sheetLayouts =>
      $$SheetLayoutsTableTableManager(_db.attachedDatabase, _db.sheetLayouts);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db.attachedDatabase, _db.exams);
  $$AnswerKeyVersionsTableTableManager get answerKeyVersions =>
      $$AnswerKeyVersionsTableTableManager(
        _db.attachedDatabase,
        _db.answerKeyVersions,
      );
  $$ScoringRulesTableTableManager get scoringRules =>
      $$ScoringRulesTableTableManager(_db.attachedDatabase, _db.scoringRules);
  $$AnswerKeyEntriesTableTableManager get answerKeyEntries =>
      $$AnswerKeyEntriesTableTableManager(
        _db.attachedDatabase,
        _db.answerKeyEntries,
      );
}
