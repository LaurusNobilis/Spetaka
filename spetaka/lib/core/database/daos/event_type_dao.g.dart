// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_type_dao.dart';

// ignore_for_file: type=lint
mixin _$EventTypeDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventTypesTable get eventTypes => attachedDatabase.eventTypes;
  EventTypeDaoManager get managers => EventTypeDaoManager(this);
}

class EventTypeDaoManager {
  final _$EventTypeDaoMixin _db;
  EventTypeDaoManager(this._db);
  $$EventTypesTableTableManager get eventTypes =>
      $$EventTypesTableTableManager(_db.attachedDatabase, _db.eventTypes);
}
