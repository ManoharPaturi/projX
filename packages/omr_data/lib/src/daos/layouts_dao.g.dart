// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layouts_dao.dart';

// ignore_for_file: type=lint
mixin _$LayoutsDaoMixin on DatabaseAccessor<AppDb> {
  $SheetLayoutsTable get sheetLayouts => attachedDatabase.sheetLayouts;
  LayoutsDaoManager get managers => LayoutsDaoManager(this);
}

class LayoutsDaoManager {
  final _$LayoutsDaoMixin _db;
  LayoutsDaoManager(this._db);
  $$SheetLayoutsTableTableManager get sheetLayouts =>
      $$SheetLayoutsTableTableManager(_db.attachedDatabase, _db.sheetLayouts);
}
