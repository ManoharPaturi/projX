// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'students_dao.dart';

// ignore_for_file: type=lint
mixin _$StudentsDaoMixin on DatabaseAccessor<AppDb> {
  $InstitutesTable get institutes => attachedDatabase.institutes;
  $StudentsTable get students => attachedDatabase.students;
  StudentsDaoManager get managers => StudentsDaoManager(this);
}

class StudentsDaoManager {
  final _$StudentsDaoMixin _db;
  StudentsDaoManager(this._db);
  $$InstitutesTableTableManager get institutes =>
      $$InstitutesTableTableManager(_db.attachedDatabase, _db.institutes);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
}
