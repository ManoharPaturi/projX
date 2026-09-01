// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exams_dao.dart';

// ignore_for_file: type=lint
mixin _$ExamsDaoMixin on DatabaseAccessor<AppDb> {
  $InstitutesTable get institutes => attachedDatabase.institutes;
  $SheetLayoutsTable get sheetLayouts => attachedDatabase.sheetLayouts;
  $ExamsTable get exams => attachedDatabase.exams;
  $QuestionSetsTable get questionSets => attachedDatabase.questionSets;
  ExamsDaoManager get managers => ExamsDaoManager(this);
}

class ExamsDaoManager {
  final _$ExamsDaoMixin _db;
  ExamsDaoManager(this._db);
  $$InstitutesTableTableManager get institutes =>
      $$InstitutesTableTableManager(_db.attachedDatabase, _db.institutes);
  $$SheetLayoutsTableTableManager get sheetLayouts =>
      $$SheetLayoutsTableTableManager(_db.attachedDatabase, _db.sheetLayouts);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db.attachedDatabase, _db.exams);
  $$QuestionSetsTableTableManager get questionSets =>
      $$QuestionSetsTableTableManager(_db.attachedDatabase, _db.questionSets);
}
