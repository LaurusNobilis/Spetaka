// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acquittement_dao.dart';

// ignore_for_file: type=lint
mixin _$AcquittementDaoMixin on DatabaseAccessor<AppDatabase> {
  $AcquittementsTable get acquittements => attachedDatabase.acquittements;
  AcquittementDaoManager get managers => AcquittementDaoManager(this);
}

class AcquittementDaoManager {
  final _$AcquittementDaoMixin _db;
  AcquittementDaoManager(this._db);
  $$AcquittementsTableTableManager get acquittements =>
      $$AcquittementsTableTableManager(_db.attachedDatabase, _db.acquittements);
}
