// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_dao.dart';

// ignore_for_file: type=lint
mixin _$AnalyticsDaoMixin on DatabaseAccessor<AppDb> {
  $InstitutesTable get institutes => attachedDatabase.institutes;
  $SheetLayoutsTable get sheetLayouts => attachedDatabase.sheetLayouts;
  $ExamsTable get exams => attachedDatabase.exams;
  $StudentsTable get students => attachedDatabase.students;
  $ScansTable get scans => attachedDatabase.scans;
  $AnswerKeyVersionsTable get answerKeyVersions =>
      attachedDatabase.answerKeyVersions;
  $ScoringRunsTable get scoringRuns => attachedDatabase.scoringRuns;
  $ResultsTable get results => attachedDatabase.results;
  $BubbleReadsTable get bubbleReads => attachedDatabase.bubbleReads;
  $ScoringRulesTable get scoringRules => attachedDatabase.scoringRules;
  $AnswerKeyEntriesTable get answerKeyEntries =>
      attachedDatabase.answerKeyEntries;
  AnalyticsDaoManager get managers => AnalyticsDaoManager(this);
}

class AnalyticsDaoManager {
  final _$AnalyticsDaoMixin _db;
  AnalyticsDaoManager(this._db);
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
  $$AnswerKeyVersionsTableTableManager get answerKeyVersions =>
      $$AnswerKeyVersionsTableTableManager(
        _db.attachedDatabase,
        _db.answerKeyVersions,
      );
  $$ScoringRunsTableTableManager get scoringRuns =>
      $$ScoringRunsTableTableManager(_db.attachedDatabase, _db.scoringRuns);
  $$ResultsTableTableManager get results =>
      $$ResultsTableTableManager(_db.attachedDatabase, _db.results);
  $$BubbleReadsTableTableManager get bubbleReads =>
      $$BubbleReadsTableTableManager(_db.attachedDatabase, _db.bubbleReads);
  $$ScoringRulesTableTableManager get scoringRules =>
      $$ScoringRulesTableTableManager(_db.attachedDatabase, _db.scoringRules);
  $$AnswerKeyEntriesTableTableManager get answerKeyEntries =>
      $$AnswerKeyEntriesTableTableManager(
        _db.attachedDatabase,
        _db.answerKeyEntries,
      );
}
