// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_jobs_dao.dart';

// ignore_for_file: type=lint
mixin _$ReportJobsDaoMixin on DatabaseAccessor<AppDb> {
  $InstitutesTable get institutes => attachedDatabase.institutes;
  $SheetLayoutsTable get sheetLayouts => attachedDatabase.sheetLayouts;
  $ExamsTable get exams => attachedDatabase.exams;
  $ReportJobsTable get reportJobs => attachedDatabase.reportJobs;
  ReportJobsDaoManager get managers => ReportJobsDaoManager(this);
}

class ReportJobsDaoManager {
  final _$ReportJobsDaoMixin _db;
  ReportJobsDaoManager(this._db);
  $$InstitutesTableTableManager get institutes =>
      $$InstitutesTableTableManager(_db.attachedDatabase, _db.institutes);
  $$SheetLayoutsTableTableManager get sheetLayouts =>
      $$SheetLayoutsTableTableManager(_db.attachedDatabase, _db.sheetLayouts);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db.attachedDatabase, _db.exams);
  $$ReportJobsTableTableManager get reportJobs =>
      $$ReportJobsTableTableManager(_db.attachedDatabase, _db.reportJobs);
}
