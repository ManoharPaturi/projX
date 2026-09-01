// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scans_dao.dart';

// ignore_for_file: type=lint
mixin _$ScansDaoMixin on DatabaseAccessor<AppDb> {
  $InstitutesTable get institutes => attachedDatabase.institutes;
  $SheetLayoutsTable get sheetLayouts => attachedDatabase.sheetLayouts;
  $ExamsTable get exams => attachedDatabase.exams;
  $StudentsTable get students => attachedDatabase.students;
  $ScansTable get scans => attachedDatabase.scans;
  $BubbleReadsTable get bubbleReads => attachedDatabase.bubbleReads;
  $ReviewQueueTable get reviewQueue => attachedDatabase.reviewQueue;
  ScansDaoManager get managers => ScansDaoManager(this);
}

class ScansDaoManager {
  final _$ScansDaoMixin _db;
  ScansDaoManager(this._db);
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
  $$BubbleReadsTableTableManager get bubbleReads =>
      $$BubbleReadsTableTableManager(_db.attachedDatabase, _db.bubbleReads);
  $$ReviewQueueTableTableManager get reviewQueue =>
      $$ReviewQueueTableTableManager(_db.attachedDatabase, _db.reviewQueue);
}
