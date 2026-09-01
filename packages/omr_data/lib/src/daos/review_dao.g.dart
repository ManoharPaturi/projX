// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewDaoMixin on DatabaseAccessor<AppDb> {
  $InstitutesTable get institutes => attachedDatabase.institutes;
  $SheetLayoutsTable get sheetLayouts => attachedDatabase.sheetLayouts;
  $ExamsTable get exams => attachedDatabase.exams;
  $StudentsTable get students => attachedDatabase.students;
  $ScansTable get scans => attachedDatabase.scans;
  $ReviewQueueTable get reviewQueue => attachedDatabase.reviewQueue;
  $BubbleReadsTable get bubbleReads => attachedDatabase.bubbleReads;
  ReviewDaoManager get managers => ReviewDaoManager(this);
}

class ReviewDaoManager {
  final _$ReviewDaoMixin _db;
  ReviewDaoManager(this._db);
  $$InstitutesTableTableManager get institutes =>
      $$InstitutesTableTableManager(_db.attachedDatabase, _db.institutes);
  $$SheetLayoutsTableTableManager get sheetLayouts =>
      $$SheetLayoutsTableTableManager(_db.attachedDatabase, _db.sheetLayouts);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db.attachedDatabase, _db.exams);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
  $$ScansTableTableManager get scans =>
      $$ScansTableTableManager(_db.attachedDatabase, _db.scans);
  $$ReviewQueueTableTableManager get reviewQueue =>
      $$ReviewQueueTableTableManager(_db.attachedDatabase, _db.reviewQueue);
  $$BubbleReadsTableTableManager get bubbleReads =>
      $$BubbleReadsTableTableManager(_db.attachedDatabase, _db.bubbleReads);
}
